"""What serving a chart decides, before HTTP and before SQL."""

import asyncio
from collections.abc import Awaitable, Callable, Sequence
from datetime import UTC, date, datetime, time, timedelta
from typing import Protocol
from zoneinfo import ZoneInfo

import structlog

from app.db import SessionDep
from app.errors import QuoteRangeInvalid, QuoteRangeTooLong, UnknownSymbolError
from app.modules.favorites import is_favorite
from app.modules.quotes.models import Quote, QuoteInterval
from app.modules.quotes.repository import QuoteRepository
from app.modules.quotes.schemas import QuoteCandle, QuoteSeries
from app.observability import (
    PROVIDER_QUOTA_REMAINING,
    PROVIDER_REQUESTS,
    QUOTE_CACHE_HITS,
    QUOTE_CACHE_MISSES,
)
from app.providers import MarketDataProvider, ProviderError, QuotePoint

# NYSE and NASDAQ, which are the two markets of the catalogue and keep the same hours. A
# constant and not a column: every symbol we serve trades here, and a column would be a piece of
# configuration nobody would ever set to anything else.
MARKET_TIMEZONE = ZoneInfo("America/New_York")

# How far back a cold cache asks.
REALTIME_LOOKBACK = timedelta(days=7)

# The TTL of a candle is the interval it covers: before the next one closes.
_TTL = {
    QuoteInterval.ONE_MINUTE: timedelta(minutes=1),
    QuoteInterval.FIVE_MINUTES: timedelta(minutes=5),
    QuoteInterval.FIFTEEN_MINUTES: timedelta(minutes=15),
}

# How long a window may be, per interval.
MAX_RANGE_DAYS = {
    QuoteInterval.ONE_MINUTE: 7,
    QuoteInterval.FIVE_MINUTES: 30,
    QuoteInterval.FIFTEEN_MINUTES: 90,
}

_log = structlog.get_logger()


class _Gate:
    """One `(symbol, interval)`'s turn at the provider: who is going, and when one last went."""

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
    """The gate of every `(symbol, interval)` this process has served."""

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


# Process state: one gatekeeper for the application.
_GATEKEEPER = _Gatekeeper()


class QuoteStore(Protocol):
    """What this module needs from whatever caches the candles it serves."""

    async def candles_in(
        self, symbol: str, interval: str, start: datetime, end: datetime
    ) -> list[Quote]:
        """The candles of that symbol and interval inside that window, oldest first."""
        ...

    async def newest_ts(self, symbol: str, interval: str) -> datetime | None:
        """The instant of the newest candle stored for that pair, or nothing."""
        ...

    async def save(self, symbol: str, interval: str, points: Sequence[QuotePoint]) -> int:
        """Store those candles, and say how many rows the statement touched."""
        ...


# The one question this module asks `favorites`, with the session already bound.
FavoriteCheck = Callable[[int, str], Awaitable[bool]]


def quote_store(session: SessionDep) -> QuoteStore:
    """The cache a route is served with."""
    return QuoteRepository(session)


def favorite_check(session: SessionDep) -> FavoriteCheck:
    """The authorization question a route is served with, bound to its session."""

    async def follows(user_id: int, symbol: str) -> bool:
        return await is_favorite(session, user_id, symbol)

    return follows


async def get_series(
    store: QuoteStore,
    follows: FavoriteCheck,
    provider: MarketDataProvider,
    symbol: str,
    interval: QuoteInterval,
    user_id: int,
    start: datetime | None = None,
    end: datetime | None = None,
) -> QuoteSeries:
    """The series of that symbol for whoever is asking, and what to say about it."""
    asked = _window_asked_for(interval, start, end)
    wanted = symbol.strip().upper()

    if not await follows(user_id, wanted):
        raise UnknownSymbolError

    now = datetime.now(tz=UTC)
    window = asked if asked is not None else (_today_began(now), now)

    stored = await store.candles_in(wanted, interval, *window)

    if _answers_already(stored, interval, now, historic=asked is not None):
        QUOTE_CACHE_HITS.inc()
        served = await _answer(
            store, wanted, interval, stored, failed=False, historic=asked is not None
        )
        _audit(wanted, interval, window, served, cache_hit=True)

        return served

    QUOTE_CACHE_MISSES.inc()

    failed = await _fill(store, provider, wanted, interval, window, now, historic=asked is not None)

    stored = await store.candles_in(wanted, interval, *window)

    served = await _answer(
        store, wanted, interval, stored, failed=failed, historic=asked is not None
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
    """Record what was served and what it cost."""
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
    """The window of `Histórico` as two instants, or nothing when the mode is `Tiempo Real`."""
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
    """Midnight of today where the market is, as an instant."""
    return datetime.combine(now.astimezone(MARKET_TIMEZONE).date(), time.min, MARKET_TIMEZONE)


def _answers_already(
    stored: list[Quote], interval: QuoteInterval, now: datetime, historic: bool
) -> bool:
    """Whether what is cached can be served without spending a credit."""
    if not stored:
        return False

    return historic or now - stored[-1].ts < _TTL[interval]


async def _fill(
    store: QuoteStore,
    provider: MarketDataProvider,
    symbol: str,
    interval: QuoteInterval,
    window: tuple[datetime, datetime],
    now: datetime,
    historic: bool,
) -> bool:
    """Bring the window up to date through the gate, and say whether the provider refused."""
    gate = _GATEKEEPER.gate_for(symbol, interval)

    async with gate:
        fresh = await store.candles_in(symbol, interval, *window)

        if _answers_already(fresh, interval, now, historic=historic):
            return False

        if gate.asked_within(_TTL[interval], now):
            # Nothing came back the last time either, and the TTL has not passed: asking again
            # would spend a credit to be told the same thing.
            return False

        if historic:
            asked = window
        elif fresh:
            # The refresh of every minute: only what happened since the newest candle we hold.
            asked = (fresh[-1].ts, window[1])
        else:
            # A cold cache, or a day with no session yet. It costs the same credit and brings back
            # the last session there was, which is what the screen needs on a Sunday.
            asked = (now - REALTIME_LOOKBACK, window[1])

        return not await _fetch(store, provider, gate, symbol, interval, asked)


async def _fetch(
    store: QuoteStore,
    provider: MarketDataProvider,
    gate: _Gate,
    symbol: str,
    interval: QuoteInterval,
    window: tuple[datetime, datetime],
) -> bool:
    """Ask the world for that window and store what comes back; say whether it answered."""
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
        await store.save(symbol, interval, points)

    return True


async def _answer(
    store: QuoteStore,
    symbol: str,
    interval: QuoteInterval,
    stored: list[Quote],
    failed: bool,
    historic: bool,
) -> QuoteSeries:
    """Turn what the cache holds into the series the router serves, and say what it is."""
    if stored:
        return QuoteSeries(
            status="stale" if failed else "ok", points=_points(stored), session_date=None
        )

    if historic:
        return QuoteSeries(status="stale" if failed else "no_data", points=(), session_date=None)

    previous, traded_on = await _last_session(store, symbol, interval)

    if failed:
        return QuoteSeries(status="stale", points=_points(previous), session_date=None)

    if previous:
        return QuoteSeries(status="market_closed", points=_points(previous), session_date=traded_on)

    return QuoteSeries(status="no_data", points=(), session_date=None)


def _points(stored: list[Quote]) -> tuple[QuoteCandle, ...]:
    """The stored rows as what leaves this module: an instant and a price."""
    return tuple(QuoteCandle(ts=row.ts, price=row.close_price) for row in stored)


async def _last_session(
    store: QuoteStore, symbol: str, interval: QuoteInterval
) -> tuple[list[Quote], date | None]:
    """The newest session the cache holds, and the day it traded in market hours."""
    newest = await store.newest_ts(symbol, interval)

    if newest is None:
        return [], None

    traded_on = newest.astimezone(MARKET_TIMEZONE).date()
    opened = datetime.combine(traded_on, time.min, MARKET_TIMEZONE)

    return await store.candles_in(symbol, interval, opened, opened + timedelta(days=1)), traded_on
