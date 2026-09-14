"""What serving a chart decides, before HTTP and before SQL (RF-24…RF-32, RF-36, RF-41…RF-45).

This is the core of the feature and the file the Article II claim rests on: the quota is finite,
and what keeps it finite is that a second reader of the same symbol costs nothing. None of that
is visible from a response body -- a chart drawn from ten provider calls looks exactly like a
chart drawn from one -- so what is measured here is **how many times the provider was called and
with what window**, which is the only way the claim is checkable at all.

Three collaborators are replaced, and they are three different kinds of thing:

- `candles_in`, `newest_ts` and `save` are this module's own repository, patched where the
  service consumes them. The double is backed by rows rather than scripted, because the service
  reads the database again after writing to it and a scripted double would make the second read
  answer something the first write did not produce.
- `is_favorite` belongs to `favorites` and arrives through its package, so it is patched **where
  it is consumed** -- `app.modules.quotes.service.is_favorite` -- and never where it is defined:
  that is what ties the test to the contract instead of to somebody else's interior (GEN-02).
- the provider is replaced by the abstract contract, never by an HTTP client. The service does
  not know TwelveData exists and neither does this file (GEN-08, TEST-03).

The clock is not injected, because `plan.md` fixes no seam for it: every assertion about "today"
is therefore written relative to the real `now`, with a tolerance where one is needed.
"""

import asyncio
import sys
from collections.abc import Iterator, Sequence
from datetime import UTC, datetime, timedelta
from decimal import Decimal
from typing import cast
from zoneinfo import ZoneInfo

import pytest
from app.modules.quotes.service import QuoteSeries, get_series
from sqlalchemy.ext.asyncio import AsyncSession

from app.errors import QuoteRangeInvalid, QuoteRangeTooLong, UnknownSymbolError
from app.modules.quotes.models import Quote, QuoteInterval
from app.providers import (
    MarketDataProvider,
    ProviderError,
    ProviderQuotaExceeded,
    ProviderRejectedCredentials,
    ProviderUnavailable,
    QuotePoint,
    StockRecord,
    SymbolNotFound,
)

# The one market of the catalogue (A4). Written here rather than imported from the service on
# purpose: a constant asserted against itself proves nothing, and what this file fixes is the
# product decision, not the spelling of the name that holds it.
_MARKET = ZoneInfo("America/New_York")

_SERVICE = "app.modules.quotes.service"

_JUAN = 1
_TSLA = "TSLA"

# The collaborators are replaced in every test, so the session is never touched. It is passed
# anyway because the signature takes one: the service is not the layer that opens it.
_UNUSED_SESSION = cast(AsyncSession, object())


def _now() -> datetime:
    """The instant the test runs, which is the only clock the service has."""
    return datetime.now(tz=UTC)


def _candle(ts: datetime, close: str = "365.47", interval: str = "1min") -> Quote:
    """One stored candle, which is what the repository hands the service."""
    price = Decimal(close)

    return Quote(
        symbol=_TSLA,
        interval=interval,
        ts=ts,
        open_price=price - Decimal("0.5"),
        high_price=price + Decimal("0.75"),
        low_price=price - Decimal("0.75"),
        close_price=price,
        volume=100_000,
    )


def _point(ts: datetime, close: str = "365.47") -> QuotePoint:
    """One candle as the provider hands it over, in the types of the contract (ADR-006)."""
    price = Decimal(close)

    return QuotePoint(
        ts=ts,
        open=price - Decimal("0.5"),
        high=price + Decimal("0.75"),
        low=price - Decimal("0.75"),
        close=price,
        volume=100_000,
    )


class _Repository:
    """Stand-in for `quotes/repository.py`, backed by rows instead of by a script.

    It counts reads as well as answering them: RF-47 says an invalid range is refused *before*
    anything else happens, and "before anything else" includes the database.
    """

    def __init__(self, stored: Sequence[Quote] = ()) -> None:
        """Start from the candles the test says are already cached."""
        self.rows: dict[tuple[str, str, datetime], Quote] = {
            (row.symbol, row.interval, row.ts): row for row in stored
        }
        self.reads = 0
        self.saved: list[QuotePoint] = []

    async def candles_in(
        self, session: AsyncSession, symbol: str, interval: str, start: datetime, end: datetime
    ) -> list[Quote]:
        """The candles of that window, oldest first, which is what the chart reads."""
        self.reads += 1

        return sorted(
            (
                row
                for key, row in self.rows.items()
                if key[0] == symbol and key[1] == interval and start <= row.ts <= end
            ),
            key=lambda row: row.ts,
        )

    async def newest_ts(self, session: AsyncSession, symbol: str, interval: str) -> datetime | None:
        """The instant of the newest candle there is, or nothing if there is none."""
        self.reads += 1
        instants = [key[2] for key in self.rows if key[0] == symbol and key[1] == interval]

        return max(instants) if instants else None

    async def save(
        self, session: AsyncSession, symbol: str, interval: str, points: Sequence[QuotePoint]
    ) -> int:
        """Upsert what the provider returned, the way the composite key makes it an upsert."""
        self.saved.extend(points)
        for point in points:
            self.rows[(symbol, interval, point.ts)] = _candle(
                point.ts, str(point.close), interval=interval
            )

        return len(points)


class _Provider(MarketDataProvider):
    """The contract, counting every call and remembering the window it was asked for.

    The counter is the whole point of the file: `RF-24` and `RF-25` are claims about how many
    times this was called, and nothing in a response body can tell them apart.
    """

    def __init__(
        self,
        points: Sequence[QuotePoint] = (),
        failure: ProviderError | None = None,
        delay: float = 0.0,
    ) -> None:
        """Answer with those points, or fail with that error, after that delay."""
        self.points = list(points)
        self.failure = failure
        self.delay = delay
        self.calls: list[tuple[str, str, datetime, datetime]] = []

    async def list_stocks(self, exchange: str) -> list[StockRecord]:
        """Not what this service asks for; the catalogue is another module's business."""
        return []

    async def get_time_series(
        self, symbol: str, interval: str, start: datetime, end: datetime
    ) -> list[QuotePoint]:
        """Record the call before anything else, then answer or fail."""
        self.calls.append((symbol, interval, start, end))

        if self.delay:
            await asyncio.sleep(self.delay)

        if self.failure is not None:
            raise self.failure

        return list(self.points)


@pytest.fixture(autouse=True)
def a_gate_that_remembers_nothing(monkeypatch: pytest.MonkeyPatch) -> Iterator[None]:
    """Empty the gate before and after each test, so no test can be decided by another one.

    The gate of `plan.md` is process state -- a lock plus the last attempt per
    `(symbol, interval)` -- so a leftover entry would suppress a provider call in a test that
    was written to count one. Reaching for the private name is the price of the gate being
    process state, and it is cheaper than a test that passes depending on what ran first.
    """
    gates = getattr(sys.modules.get(_SERVICE), "_GATES", None)
    clear = getattr(gates, "clear", None)

    if callable(clear):
        clear()

    yield

    if callable(clear):
        clear()


@pytest.fixture(autouse=True)
def the_symbol_is_the_users(monkeypatch: pytest.MonkeyPatch) -> None:
    """`favorites` says yes, which is the case every test but the authorization one is about."""

    async def _yes(session: AsyncSession, user_id: int, symbol: str) -> bool:
        return True

    monkeypatch.setattr(f"{_SERVICE}.is_favorite", _yes)


@pytest.fixture
def repository(monkeypatch: pytest.MonkeyPatch) -> _Repository:
    """An empty cache, wired where the service consumes its three repository functions."""
    return _wire(monkeypatch, _Repository())


def _wire(monkeypatch: pytest.MonkeyPatch, double: _Repository) -> _Repository:
    """Patch the three repository names in the service's namespace."""
    monkeypatch.setattr(f"{_SERVICE}.candles_in", double.candles_in)
    monkeypatch.setattr(f"{_SERVICE}.newest_ts", double.newest_ts)
    monkeypatch.setattr(f"{_SERVICE}.save", double.save)

    return double


def _cached(monkeypatch: pytest.MonkeyPatch, *candles: Quote) -> _Repository:
    """A cache that already holds those candles."""
    return _wire(monkeypatch, _Repository(candles))


async def _ask(
    provider: MarketDataProvider,
    interval: QuoteInterval = QuoteInterval.ONE_MINUTE,
    start: datetime | None = None,
    end: datetime | None = None,
) -> QuoteSeries:
    """One call to the service, with the arguments `plan.md` fixes for it."""
    return await get_series(
        _UNUSED_SESSION,
        provider,
        symbol=_TSLA,
        interval=interval,
        user_id=_JUAN,
        start=start,
        end=end,
    )


class TestOnlyTheOwnerOfTheSymbolGetsAChart:
    """RF-35 and Article III: the chart is served for the favourites of whoever is asking."""

    async def test_a_symbol_that_is_not_a_favourite_is_refused(
        self, monkeypatch: pytest.MonkeyPatch, repository: _Repository
    ) -> None:
        """The service says no with a domain error; the router is what turns it into a 404."""

        async def _no(session: AsyncSession, user_id: int, symbol: str) -> bool:
            return False

        monkeypatch.setattr(f"{_SERVICE}.is_favorite", _no)
        provider = _Provider()

        with pytest.raises(UnknownSymbolError):
            await _ask(provider)

    async def test_a_symbol_that_is_not_a_favourite_costs_no_quota(
        self, monkeypatch: pytest.MonkeyPatch, repository: _Repository
    ) -> None:
        """Article II with Article III on top: somebody else's symbol never reaches the world."""

        async def _no(session: AsyncSession, user_id: int, symbol: str) -> bool:
            return False

        monkeypatch.setattr(f"{_SERVICE}.is_favorite", _no)
        provider = _Provider()

        with pytest.raises(UnknownSymbolError):
            await _ask(provider)

        assert provider.calls == []

    async def test_it_asks_favorites_about_the_user_of_the_token(
        self, monkeypatch: pytest.MonkeyPatch, repository: _Repository
    ) -> None:
        """`is_favorite` receives the id the service was given, as its first argument."""
        asked: list[tuple[int, str]] = []

        async def _record(session: AsyncSession, user_id: int, symbol: str) -> bool:
            asked.append((user_id, symbol))
            return True

        monkeypatch.setattr(f"{_SERVICE}.is_favorite", _record)

        await _ask(_Provider(points=[_point(_now())]))

        assert asked == [(_JUAN, _TSLA)]


class TestTheQuotaIsSpentOncePerSymbolAndInterval:
    """RF-24 and RF-25: the reason this feature exists (Article II)."""

    async def test_a_cached_candle_inside_the_ttl_is_served_without_calling_the_provider(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """RF-24: the TTL is the interval, so a candle ten seconds old is still current."""
        _cached(monkeypatch, _candle(_now() - timedelta(seconds=10)))
        provider = _Provider()

        await _ask(provider)

        assert provider.calls == []

    async def test_asking_twice_in_a_row_reaches_the_provider_once(
        self, repository: _Repository
    ) -> None:
        """RF-24: the second reader of a symbol pays nothing, which is the whole claim."""
        provider = _Provider(points=[_point(_now())])

        await _ask(provider)
        await _ask(provider)

        assert len(provider.calls) == 1

    async def test_ten_requests_launched_in_parallel_reach_the_provider_once(
        self, repository: _Repository
    ) -> None:
        """RF-25: ten browsers on the same symbol cost what one costs.

        Launched with `gather` and against a provider that takes a moment, which is what makes
        this different from the test above: a TTL alone is green in sequence and spends ten
        credits the moment two requests land in the same second. Only the gate passes this.
        """
        provider = _Provider(points=[_point(_now())], delay=0.05)

        await asyncio.gather(*(_ask(provider) for _ in range(10)))

        assert len(provider.calls) == 1

    async def test_a_symbol_with_no_series_is_not_asked_again_inside_a_ttl(
        self, repository: _Repository
    ) -> None:
        """A Sunday is not paid ten times because somebody pressed `Graficar` ten times.

        Nothing gets cached here -- the provider answers with an empty series -- so the TTL on
        the data cannot help: what stops the tenth call is the gate remembering the attempt.
        """
        provider = _Provider(points=[])

        for _ in range(10):
            await _ask(provider)

        assert len(provider.calls) == 1

    async def test_a_closed_window_in_the_past_that_is_cached_is_not_asked_again(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """RF-24 for `Histórico`: yesterday's prices do not expire, so they are never refetched."""
        start = datetime(2026, 9, 8, 9, 30)
        _cached(
            monkeypatch,
            _candle(datetime(2026, 9, 8, 13, 35, tzinfo=UTC)),
            _candle(datetime(2026, 9, 8, 13, 36, tzinfo=UTC)),
        )
        provider = _Provider()

        await _ask(provider, start=start, end=datetime(2026, 9, 8, 16, 0))

        assert provider.calls == []


class TestTheWindowTheServiceAsksFor:
    """Which window goes out is the service's decision, and it is two of them (plan.md)."""

    async def test_with_a_cold_cache_it_asks_for_the_last_days(
        self, repository: _Repository
    ) -> None:
        """A week in one request: the provider charges per request, not per candle.

        It is also what makes RF-27 possible on a Sunday with an empty database: the last
        session is inside the window, so it arrives without a second call.
        """
        provider = _Provider(points=[_point(_now())])

        await _ask(provider)

        _, _, start, end = provider.calls[0]
        # Against the span and not against the constant: a constant asserted against itself
        # proves nothing, and what plan.md fixes is "seven days", not the name.
        assert timedelta(days=6, hours=23) <= end - start <= timedelta(days=7, hours=1)

    async def test_with_todays_session_cached_it_asks_only_for_what_is_missing(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """The refresh of every minute is the cheap window: from the newest candle to now."""
        newest = _now() - timedelta(minutes=30)
        _cached(monkeypatch, _candle(newest - timedelta(minutes=1)), _candle(newest))
        provider = _Provider(points=[_point(_now())])

        await _ask(provider)

        _, _, start, _ = provider.calls[0]
        assert start == newest

    async def test_the_window_travels_in_utc(self, repository: _Repository) -> None:
        """Both ends aware and at zero offset: a naive instant is the bug of this feature."""
        provider = _Provider(points=[_point(_now())])

        await _ask(provider)

        _, _, start, end = provider.calls[0]
        assert start.utcoffset() == timedelta(0)
        assert end.utcoffset() == timedelta(0)

    async def test_it_asks_for_the_symbol_and_the_interval_it_was_given(
        self, repository: _Repository
    ) -> None:
        """The cache is keyed by the pair, so the request has to carry the pair."""
        provider = _Provider(points=[_point(_now())])

        await _ask(provider, interval=QuoteInterval.FIFTEEN_MINUTES)

        assert provider.calls[0][0] == _TSLA
        assert provider.calls[0][1] == "15min"


class TestTheHistoricWindowIsReadInMarketTime:
    """RF-16 and RF-36: the user writes a market hour, and the backend is what localises it."""

    async def test_the_window_is_localised_in_the_market_timezone(
        self, repository: _Repository
    ) -> None:
        """09:30 means the opening bell, not 09:30 on whatever clock the server runs on.

        The pair of assertions is the point: a service that stamped UTC on the naive input
        would send 09:30Z, which is 05:30 in New York and four hours of chart nobody asked for.
        """
        provider = _Provider(points=[])

        await _ask(
            provider,
            start=datetime(2026, 9, 8, 9, 30),
            end=datetime(2026, 9, 8, 16, 0),
        )

        _, _, start, end = provider.calls[0]
        assert start == datetime(2026, 9, 8, 9, 30, tzinfo=_MARKET).astimezone(UTC)
        assert end == datetime(2026, 9, 8, 16, 0, tzinfo=_MARKET).astimezone(UTC)

    async def test_it_answers_only_candles_inside_the_window(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """RF-16: the first point is not before `from` and the last is not after `to`."""
        inside = datetime(2026, 9, 8, 13, 35, tzinfo=UTC)
        _cached(
            monkeypatch,
            _candle(inside - timedelta(hours=2)),
            _candle(inside),
            _candle(inside + timedelta(hours=8)),
        )
        provider = _Provider()

        series = await _ask(
            provider,
            start=datetime(2026, 9, 8, 9, 30),
            end=datetime(2026, 9, 8, 16, 0),
        )

        instants = [point.ts for point in series.points]
        assert instants == [inside]


class TestARangeThatCannotBeAskedFor:
    """RF-41 to RF-45 and RF-47: refused before the database and before the world."""

    @pytest.mark.parametrize(
        "start,end",
        [
            (datetime(2026, 9, 8, 10, 0), datetime(2026, 9, 8, 10, 0)),
            (datetime(2026, 9, 8, 11, 0), datetime(2026, 9, 8, 10, 0)),
        ],
        ids=["equal", "reversed"],
    )
    async def test_from_not_before_to_is_refused(
        self, repository: _Repository, start: datetime, end: datetime
    ) -> None:
        """RF-41: `desde` equal to `hasta` is an empty window, and after it is a mistake."""
        with pytest.raises(QuoteRangeInvalid):
            await _ask(_Provider(), start=start, end=end)

    @pytest.mark.parametrize(
        "interval,days",
        [
            (QuoteInterval.ONE_MINUTE, 8),
            (QuoteInterval.FIVE_MINUTES, 31),
            (QuoteInterval.FIFTEEN_MINUTES, 91),
        ],
    )
    async def test_a_range_longer_than_its_interval_allows_is_refused(
        self, repository: _Repository, interval: QuoteInterval, days: int
    ) -> None:
        """RF-42 to RF-45: one day past the cap of each interval."""
        start = datetime(2026, 6, 1, 10, 0)

        with pytest.raises(QuoteRangeTooLong):
            await _ask(_Provider(), interval=interval, start=start, end=start + timedelta(days))

    @pytest.mark.parametrize(
        "interval,days",
        [
            (QuoteInterval.ONE_MINUTE, 7),
            (QuoteInterval.FIVE_MINUTES, 30),
            (QuoteInterval.FIFTEEN_MINUTES, 90),
        ],
    )
    async def test_a_range_exactly_at_the_cap_is_accepted(
        self, repository: _Repository, interval: QuoteInterval, days: int
    ) -> None:
        """The boundary belongs to the allowed side: 7 days at `1min` graphs, 8 does not."""
        start = datetime(2026, 6, 1, 10, 0)

        await _ask(_Provider(), interval=interval, start=start, end=start + timedelta(days))

    async def test_an_invalid_range_never_reaches_the_provider(
        self, repository: _Repository
    ) -> None:
        """RF-47: a query the screen could not make does not cost a credit."""
        provider = _Provider()

        with pytest.raises(QuoteRangeInvalid):
            await _ask(
                provider,
                start=datetime(2026, 9, 8, 11, 0),
                end=datetime(2026, 9, 8, 10, 0),
            )

        assert provider.calls == []

    async def test_an_invalid_range_never_reaches_the_database(
        self, repository: _Repository
    ) -> None:
        """The validation is step 2 of the plan, before the window is even resolved."""
        with pytest.raises(QuoteRangeTooLong):
            await _ask(
                _Provider(),
                start=datetime(2026, 6, 1, 10, 0),
                end=datetime(2026, 6, 30, 10, 0),
            )

        assert repository.reads == 0


class TestTheFourStatusesAndTheirPrecedence:
    """ADR-005 and RF-27 to RF-32: where an `if` in the wrong order lies on a screen."""

    async def test_fresh_data_is_ok(self, monkeypatch: pytest.MonkeyPatch) -> None:
        """RF-32: nothing to explain, so nothing is said."""
        _cached(monkeypatch, _candle(_now() - timedelta(seconds=10)))

        series = await _ask(_Provider())

        assert series.status == "ok"

    async def test_ok_carries_no_session_date(self, monkeypatch: pytest.MonkeyPatch) -> None:
        """`session_date` is the `{fecha}` of RF-28 and travels only with `market_closed`."""
        _cached(monkeypatch, _candle(_now() - timedelta(seconds=10)))

        series = await _ask(_Provider())

        assert series.session_date is None

    async def test_a_provider_that_failed_is_stale_and_never_market_closed(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """The precedence, stated as the sentence it defends.

        With the provider refusing and no candle for today, both branches are reachable and only
        one is honest: we do not know whether the market is closed or whether the provider is
        down, and saying the first would be inventing (RF-29, RF-30).
        """
        yesterday = _now() - timedelta(days=3)
        _cached(monkeypatch, _candle(yesterday))

        series = await _ask(_Provider(failure=ProviderQuotaExceeded("spent")))

        assert series.status == "stale"

    async def test_a_stale_answer_still_carries_the_last_prices_known(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """RF-29: the chart is drawn anyway, which is what the notice is about."""
        yesterday = _now() - timedelta(days=3)
        _cached(monkeypatch, _candle(yesterday))

        series = await _ask(_Provider(failure=ProviderUnavailable("no answer")))

        assert series.points

    @pytest.mark.parametrize(
        "failure",
        [
            ProviderUnavailable("down"),
            ProviderQuotaExceeded("spent"),
            ProviderRejectedCredentials("bad key"),
            SymbolNotFound("no series"),
        ],
        ids=["unavailable", "quota", "credentials", "unknown symbol"],
    )
    async def test_no_provider_failure_escapes_the_service(
        self, monkeypatch: pytest.MonkeyPatch, failure: ProviderError
    ) -> None:
        """ERR-05: the four of them are answered, never raised at the router."""
        _cached(monkeypatch, _candle(_now() - timedelta(days=3)))

        series = await _ask(_Provider(failure=failure))

        assert series.status in {"stale", "market_closed", "no_data", "ok"}

    async def test_today_empty_with_an_earlier_session_stored_is_market_closed(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """RF-27 and RF-28: the Saturday case, which is the likeliest day of the demo."""
        _cached(monkeypatch, *_an_earlier_session())

        series = await _ask(_Provider(points=[]))

        assert series.status == "market_closed"

    async def test_market_closed_charts_that_earlier_session(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """RF-27: the last session there was, not a blank screen."""
        stored = _an_earlier_session()
        _cached(monkeypatch, *stored)

        series = await _ask(_Provider(points=[]))

        assert [point.ts for point in series.points] == [candle.ts for candle in stored]

    async def test_the_session_date_is_the_day_the_market_had(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """RF-36: a session that crosses midnight in UTC is still one day in market time.

        The stored candle is at 21:30 in New York, which is already the next day in UTC. An
        implementation that took the date of the instant as it is stored would answer tomorrow's
        date for yesterday's session, and the notice of RF-28 would name a day that never
        traded.
        """
        traded_on = (_now().astimezone(_MARKET) - timedelta(days=3)).date()
        late = datetime(
            traded_on.year, traded_on.month, traded_on.day, 21, 30, tzinfo=_MARKET
        ).astimezone(UTC)
        _cached(monkeypatch, _candle(late))

        series = await _ask(_Provider(points=[]))

        assert series.session_date == traded_on

    async def test_nothing_anywhere_is_no_data(self, repository: _Repository) -> None:
        """RF-31: the symbol has no series for that interval and range, and it is said so."""
        series = await _ask(_Provider(points=[]))

        assert series.status == "no_data"

    async def test_no_data_carries_no_points(self, repository: _Repository) -> None:
        """The screen needs to be able to tell an empty chart from a chart it did not draw."""
        series = await _ask(_Provider(points=[]))

        assert series.points == ()


class TestTheProviderIsNeverNamed:
    """RF-26 and Article I: the user has no account with anybody."""

    async def test_a_failure_does_not_name_the_provider_in_what_it_answers(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """The status is generic on purpose: it says what happened, not who failed."""
        _cached(monkeypatch, _candle(_now() - timedelta(days=3)))

        series = await _ask(_Provider(failure=ProviderQuotaExceeded("spent")))

        assert "twelvedata" not in repr(series).lower()

    async def test_a_failure_is_logged_and_not_swallowed(
        self, monkeypatch: pytest.MonkeyPatch, captured_logs: list[str]
    ) -> None:
        """ERR-01 and ERR-07: every `except` decides, and every call is auditable."""
        _cached(monkeypatch, _candle(_now() - timedelta(days=3)))

        await _ask(_Provider(failure=ProviderUnavailable("down")))

        assert captured_logs

    async def test_the_log_of_a_failure_does_not_name_the_provider(
        self, monkeypatch: pytest.MonkeyPatch, captured_logs: list[str]
    ) -> None:
        """A log line ends up in Loki and in a screenshot; Article I covers both."""
        _cached(monkeypatch, _candle(_now() - timedelta(days=3)))

        await _ask(_Provider(failure=ProviderUnavailable("down")))

        assert not any("twelvedata" in line.lower() for line in captured_logs)


def _an_earlier_session() -> list[Quote]:
    """Three candles of a session three days back, which is never today whatever day it is."""
    opened = (
        (_now() - timedelta(days=3))
        .astimezone(_MARKET)
        .replace(hour=10, minute=0, second=0, microsecond=0)
    )

    return [_candle(opened.astimezone(UTC) + timedelta(minutes=minute)) for minute in range(3)]
