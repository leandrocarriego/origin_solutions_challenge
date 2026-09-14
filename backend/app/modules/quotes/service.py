"""What serving a chart decides, before HTTP and before SQL.

This is where Article II lives. The quota is 800 requests a day and a session at `1min` has 390
candles, so the rule is not "cache when convenient": nothing reaches the provider if the database
can answer, and what does reach it is shared. Two things make that true, and they are different:

- **the freshness rule** stops a second reader of the same symbol inside a TTL, and
- **the gate** stops a second reader that arrives while the first one is still fetching, which a
  TTL alone cannot see: in sequence a TTL looks perfect and spends ten credits the moment ten
  browsers land in the same second (RF-25).

The provider arrives as an argument and is never built here: that is what lets the whole suite
run with no network and no API key (TEST-03), and it is also why this file can be read without
knowing who the provider is (GEN-08).
"""

import asyncio
from datetime import UTC, date, datetime, time, timedelta
from zoneinfo import ZoneInfo

import structlog
from sqlalchemy.ext.asyncio import AsyncSession

from app.errors import QuoteRangeInvalid, QuoteRangeTooLong, UnknownSymbolError
from app.modules.favorites import is_favorite
from app.modules.quotes.models import Quote, QuoteInterval
from app.modules.quotes.repository import candles_in, newest_ts, save
from app.modules.quotes.schemas import QuoteCandle, QuoteSeries
from app.observability import (
    PROVIDER_QUOTA_REMAINING,
    PROVIDER_REQUESTS,
    QUOTE_CACHE_HITS,
    QUOTE_CACHE_MISSES,
)
from app.providers import MarketDataProvider, ProviderError

# NYSE and NASDAQ, which are the two markets of the catalogue and keep the same hours (A4). A
# constant and not a column: every symbol we serve trades here, and a column would be a piece of
# configuration nobody would ever set to anything else.
MARKET_TIMEZONE = ZoneInfo("America/New_York")

# How far back a cold cache asks. It costs the same credit as asking for an hour -- the provider
# charges per request, not per candle -- and it brings back the last session there was, which is
# what RF-27 needs on a Sunday with an empty database.
REALTIME_LOOKBACK = timedelta(days=7)

# The TTL of a candle is the interval it covers (ADR-003): before the next one closes there is
# nothing new to fetch, so asking again could not answer anything different.
_TTL = {
    QuoteInterval.ONE_MINUTE: timedelta(minutes=1),
    QuoteInterval.FIVE_MINUTES: timedelta(minutes=5),
    QuoteInterval.FIFTEEN_MINUTES: timedelta(minutes=15),
}

# How long a window may be, per interval (RF-42 to RF-44). They live here and nowhere else: a
# browser carrying its own copy would be one business rule written twice, and one of the two
# would go stale without anybody noticing until somebody read a number that was not true. The
# three were chosen to fit the provider's ceiling of 5.000 candles: seven days at `1min` are
# about 2.730.
MAX_RANGE_DAYS = {
    QuoteInterval.ONE_MINUTE: 7,
    QuoteInterval.FIVE_MINUTES: 30,
    QuoteInterval.FIFTEEN_MINUTES: 90,
}

_log = structlog.get_logger()


class _Gate:
    """One `(symbol, interval)`'s turn at the provider: who is going, and when one last went.

    Not data, which is why it is a class with behaviour and not a model: it holds an
    `asyncio.Lock` and the loop that lock belongs to, it is mutable by design, and it never
    crosses a boundary. Everything that *is* data in this application is a Pydantic model.

    The two pieces stop two different kinds of waste. The lock collapses the requests that
    overlap; the instant stops the ones that follow a fetch which brought nothing back -- a
    Sunday, or a symbol with no series -- where there is no fresh candle to say "do not ask
    again" (RF-24, RF-25).

    Taking the turn is `async with gate:`, and the state behind it is private: the caller cannot
    read the instant without asking a question about it, nor write one that is not now.
    """

    __slots__ = ("_last_attempt", "_lock", "_loop")

    def __init__(self, loop: asyncio.AbstractEventLoop) -> None:
        """Open a gate nobody has gone through, on the loop its lock will be awaited in."""
        self._lock = asyncio.Lock()
        self._loop = loop
        self._last_attempt: datetime | None = None

    async def __aenter__(self) -> "_Gate":
        """Wait for this pair's turn, however many readers are asking for it."""
        await self._lock.acquire()
        return self

    async def __aexit__(self, *_: object) -> None:
        """Hand the turn to whoever is next, whether or not the fetch went well."""
        self._lock.release()

    def belongs_to(self, loop: asyncio.AbstractEventLoop) -> bool:
        """Whether this gate's lock can still be awaited, which is true only in its own loop."""
        return self._loop is loop

    def asked_within(self, window: timedelta, now: datetime) -> bool:
        """Whether the provider was already asked this recently and brought nothing back."""
        return self._last_attempt is not None and now - self._last_attempt < window

    def went_out(self, at: datetime) -> None:
        """Record that the provider answered, so the next reader waits out the TTL."""
        self._last_attempt = at


class _Gatekeeper:
    """The gate of every `(symbol, interval)` this process has served.

    The pair is the key, and that is the whole of Article II in one line: ten browsers on TSLA
    at `5min` are one question and cost one credit, and the same ten on `1min` are another one.

    An `asyncio.Lock` belongs to the loop that awaits it -- waiting on one from a different loop
    raises about a future attached to somewhere else -- so a gate that outlived its loop is not
    a gate, it is a latent crash, and this hands out a new one instead. The application has one
    loop for its whole life and never sees it; what does is anything that runs loops one after
    another, and then a fresh loop rightly starts with nothing remembered.
    """

    def __init__(self) -> None:
        """Start with no gate open, which is what a process that has served nothing has."""
        self._gates: dict[tuple[str, str], _Gate] = {}

    def gate_for(self, symbol: str, interval: str) -> _Gate:
        """That pair's gate, opened the first time somebody asks for it in this event loop."""
        running = asyncio.get_running_loop()
        gate = self._gates.get((symbol, interval))

        if gate is None or not gate.belongs_to(running):
            gate = _Gate(running)
            self._gates[(symbol, interval)] = gate

        return gate

    def clear(self) -> None:
        """Forget every gate, which is what a test needs between one case and the next."""
        self._gates.clear()


# Process state: one gatekeeper for the application, and the reason the quota scales with symbols
# observed instead of with clients connected.
_GATEKEEPER = _Gatekeeper()


async def get_series(
    session: AsyncSession,
    provider: MarketDataProvider,
    symbol: str,
    interval: QuoteInterval,
    user_id: int,
    start: datetime | None = None,
    end: datetime | None = None,
) -> QuoteSeries:
    """The series of that symbol for whoever is asking, and what to say about it.

    `user_id` is the identity of the token and the only one this ever sees (Article III), and
    `start`/`end` arrive naive and in market hours, exactly as the person wrote them: putting a
    timezone on them is this layer's job, because this is the only side of the cable that knows
    which market the catalogue trades in.

    **The range is validated first**, before authorizing and before a single query: RF-47 says a
    query that cannot be asked is not executed, and "not executed" includes the lookup of whose
    symbol this is. The consequence is deliberate -- somebody else's symbol asked for with an
    impossible range answers 422 and not 404 -- and it leaks nothing: the 422 talks about the
    range, which whoever asked wrote themselves.
    """
    asked = _window_asked_for(interval, start, end)
    wanted = symbol.strip().upper()

    if not await is_favorite(session, user_id, wanted):
        raise UnknownSymbolError

    now = datetime.now(tz=UTC)
    window = asked if asked is not None else (_today_began(now), now)

    stored = await candles_in(session, wanted, interval, *window)
    if _answers_already(stored, interval, now, historic=asked is not None):
        QUOTE_CACHE_HITS.inc()
        served = await _answer(
            session, wanted, interval, stored, failed=False, historic=asked is not None
        )
        _audit(wanted, interval, window, served, cache_hit=True)
        return served

    QUOTE_CACHE_MISSES.inc()
    failed = await _fill(
        session, provider, wanted, interval, window, now, historic=asked is not None
    )
    stored = await candles_in(session, wanted, interval, *window)

    served = await _answer(
        session, wanted, interval, stored, failed=failed, historic=asked is not None
    )
    _audit(wanted, interval, window, served, cache_hit=False)

    return served


def _audit(
    symbol: str,
    interval: QuoteInterval,
    window: tuple[datetime, datetime],
    served: QuoteSeries,
    cache_hit: bool,
) -> None:
    """Record what was served and what it cost (ERR-07).

    One line per request and not only per call to the provider: what `ERR-07` asks to be auditable
    includes **whether the provider was reached at all**, and a request served from the database
    left no trace at all before this -- so the log answered "how often do we spend a credit?" with
    silence on the numerator's other half. The counters carry the aggregate; this carries the
    request, which is what somebody reading a symbol's history needs.

    Who the provider is stays out of it, here as everywhere (RF-26, Article I).
    """
    _log.info(
        "quote_served",
        symbol=symbol,
        interval=interval.value,
        window_start=window[0].isoformat(),
        window_end=window[1].isoformat(),
        status=served.status,
        candles=len(served.points),
        cache_hit=cache_hit,
    )


def _window_asked_for(
    interval: QuoteInterval, start: datetime | None, end: datetime | None
) -> tuple[datetime, datetime] | None:
    """The window of `Histórico` as two instants, or nothing when the mode is `Tiempo Real`.

    The two hours arrive as the person wrote them -- naive, in market hours -- and this is where
    they become instants, because the market is a fact of the product and not of the request
    (RF-36). A service that stamped UTC on them would answer a window four or five hours away
    from the one that was pointed at, with every point still neatly on the axis.
    """
    if start is None and end is None:
        return None

    if start is None or end is None or start >= end:
        raise QuoteRangeInvalid

    cap = MAX_RANGE_DAYS[interval]
    if end - start > timedelta(days=cap):
        raise QuoteRangeTooLong(interval.value, cap)

    return (
        start.replace(tzinfo=MARKET_TIMEZONE).astimezone(UTC),
        end.replace(tzinfo=MARKET_TIMEZONE).astimezone(UTC),
    )


def _today_began(now: datetime) -> datetime:
    """Midnight of today where the market is, as an instant.

    Which day "today" is, is a market hour: at 22:00 in New York it is already tomorrow in UTC,
    and a window that started there would ask for a session that has not opened (RF-36).
    """
    return datetime.combine(now.astimezone(MARKET_TIMEZONE).date(), time.min, MARKET_TIMEZONE)


def _answers_already(
    stored: list[Quote], interval: QuoteInterval, now: datetime, historic: bool
) -> bool:
    """Whether what is cached can be served without spending a credit.

    Two rules, because there are two kinds of window. One that reaches the present is current
    while the candle in progress has not closed, so the TTL is the interval (ADR-003): asking
    again would buy the same answer with a credit. One that closed in the past **does not
    expire** -- the prices of last Tuesday are a week old and perfectly final -- so having
    candles at all is enough.
    """
    if not stored:
        return False

    return historic or now - stored[-1].ts < _TTL[interval]


async def _fill(
    session: AsyncSession,
    provider: MarketDataProvider,
    symbol: str,
    interval: QuoteInterval,
    window: tuple[datetime, datetime],
    now: datetime,
    historic: bool,
) -> bool:
    """Bring the window up to date through the gate, and say whether the provider refused.

    Inside the lock the cache is read again, because whoever waited may find that whoever held
    the lock already fetched what they came for -- which is precisely what makes ten simultaneous
    readers cost one credit (RF-25).

    **Which window goes out is decided here, and there are two of them in `Tiempo Real`.** With
    today's session already stored it is `[newest candle, now]`, which is the refresh of every
    minute and is as small as it gets. With the cache cold it is the whole lookback: it costs the
    same credit -- the provider charges per request, not per candle -- and it brings back the
    last session there was, which is what the screen needs on a Sunday (RF-27). In `Histórico`
    the window is the one that was asked for, and nothing else would answer the question.
    """
    gate = _GATEKEEPER.gate_for(symbol, interval)

    async with gate:
        fresh = await candles_in(session, symbol, interval, *window)
        if _answers_already(fresh, interval, now, historic=historic):
            return False

        if gate.asked_within(_TTL[interval], now):
            # Nothing came back the last time either, and the TTL has not passed: asking again
            # would spend a credit to be told the same thing (RF-24).
            return False

        if historic:
            asked = window
        elif fresh:
            # The refresh of every minute: only what happened since the newest candle we hold.
            asked = (fresh[-1].ts, window[1])
        else:
            # A cold cache, or a day with no session yet. It costs the same credit and brings back
            # the last session there was, which is what the screen needs on a Sunday (RF-27).
            asked = (now - REALTIME_LOOKBACK, window[1])

        return not await _fetch(session, provider, gate, symbol, interval, asked)


async def _fetch(
    session: AsyncSession,
    provider: MarketDataProvider,
    gate: _Gate,
    symbol: str,
    interval: QuoteInterval,
    window: tuple[datetime, datetime],
) -> bool:
    """Ask the world for that window and store what comes back; say whether it answered.

    Nothing the provider raises escapes: a failure upstream is not a failure of this endpoint
    (ERR-05), and every one of them is logged with the window it happened in (ERR-01, ERR-07).
    What is never logged is who the provider is (RF-26, Article I).

    The gate arrives as an argument rather than being looked up again: it is the one `_fill` is
    holding the lock of, and state written through a second lookup is state two functions own.
    """
    PROVIDER_REQUESTS.labels(symbol=symbol, interval=interval.value, outcome="attempt").inc()

    try:
        points = await provider.get_time_series(symbol, interval.value, *window)
    except ProviderError as error:
        PROVIDER_REQUESTS.labels(symbol=symbol, interval=interval.value, outcome="failure").inc()
        _log.warning(
            "quote_fetch_failed",
            symbol=symbol,
            interval=interval.value,
            window_start=window[0].isoformat(),
            window_end=window[1].isoformat(),
            reason=type(error).__name__,
        )
        return False

    gate.went_out(datetime.now(tz=UTC))
    PROVIDER_REQUESTS.labels(symbol=symbol, interval=interval.value, outcome="success").inc()
    # Only an answer costs an allowance. A refusal that never reached the series -- a 429 above all
    # -- spends no credit, and decrementing on it would drift the gauge away from the number it is
    # there to report.
    PROVIDER_QUOTA_REMAINING.dec()
    _log.info(
        "quote_fetch_succeeded",
        symbol=symbol,
        interval=interval.value,
        window_start=window[0].isoformat(),
        window_end=window[1].isoformat(),
        candles=len(points),
    )

    if points:
        await save(session, symbol, interval, points)

    return True


async def _answer(
    session: AsyncSession,
    symbol: str,
    interval: QuoteInterval,
    stored: list[Quote],
    failed: bool,
    historic: bool,
) -> QuoteSeries:
    """Turn what the cache holds into the series the router serves, and say what it is.

    The order of the chain is the requirement, because three of the four states are reachable at
    once -- the provider refused, today has nothing, and there is an earlier session stored --
    and only one reading of that is honest: when the provider failed we do not know whether the
    market is closed or whether the provider is down, and answering `market_closed` would be
    inventing the first (RF-29, RF-30). So a failed fetch is `stale`, always.

    When today came out empty the chart falls back to the last session there is, which is what
    RF-27 asks for: on a Saturday the screen shows Friday with a notice, and not a blank
    rectangle. That fallback belongs to `Tiempo Real` alone -- somebody who asked for a window of
    June wants that window, and answering another day's prices would be a different question
    answered quietly.
    """
    if stored:
        return QuoteSeries(
            status="stale" if failed else "ok", points=_points(stored), session_date=None
        )

    if historic:
        return QuoteSeries(status="stale" if failed else "no_data", points=(), session_date=None)

    previous, traded_on = await _last_session(session, symbol, interval)

    if failed:
        return QuoteSeries(status="stale", points=_points(previous), session_date=None)

    if previous:
        return QuoteSeries(status="market_closed", points=_points(previous), session_date=traded_on)

    return QuoteSeries(status="no_data", points=(), session_date=None)


def _points(stored: list[Quote]) -> tuple[QuoteCandle, ...]:
    """The stored rows as what leaves this module: an instant and a price (RF-14)."""
    return tuple(QuoteCandle(ts=row.ts, price=row.close_price) for row in stored)


async def _last_session(
    session: AsyncSession, symbol: str, interval: QuoteInterval
) -> tuple[list[Quote], date | None]:
    """The newest session the cache holds, and the day it traded in market hours.

    The day is read where the session happened and never off the stored instant: a session that
    runs to 21:30 in New York is already the next day in UTC, and the notice of RF-28 would name
    a day that never traded (RF-36).
    """
    newest = await newest_ts(session, symbol, interval)
    if newest is None:
        return [], None

    traded_on = newest.astimezone(MARKET_TIMEZONE).date()
    opened = datetime.combine(traded_on, time.min, MARKET_TIMEZONE)

    return await candles_in(
        session, symbol, interval, opened, opened + timedelta(days=1)
    ), traded_on
