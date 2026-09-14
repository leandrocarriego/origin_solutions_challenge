"""The four states of a chart, and the order they are decided in.

H4 is the historia about telling the user what they are looking at, and the whole of it is one
`if` chain whose *order* is the requirement. Three of the four states are reachable at the same
time on the same request -- the provider refused, today has no candles, and there is an earlier
session in the cache -- so an implementation that checks them in the wrong order is green on
every individual claim and lies on the screen.

The sentence the order defends: when the provider fails we do not know whether the market is
closed or whether the provider is down, and answering `market_closed` would be inventing the
first. So a failed provider is `stale`, always, even when the window is empty.

Three collaborators are replaced, and they are three different kinds of thing:

- `candles_in`, `newest_ts` and `save` are this module's own repository, patched where the
  service consumes them and backed by rows rather than scripted: the service reads the database
  again after writing to it, and a scripted double would make the second read answer something
  the first write did not produce.
- `is_favorite` belongs to `favorites` and arrives through its package, so it is patched **where
  it is consumed** and never where it is defined -- which is what ties the test to the contract
  instead of to somebody else's interior.
- the provider is the abstract contract, never an HTTP client. The service does not know
  TwelveData exists and neither does this file.

The clock is not injected, because `plan.md` fixes no seam for it: every assertion about "today"
is written relative to the real `now`, and the sessions that must not be today are put days back.
"""

import sys
from collections.abc import Iterator, Sequence
from datetime import UTC, datetime, timedelta
from decimal import Decimal
from typing import cast
from zoneinfo import ZoneInfo

import pytest
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.quotes.models import Quote, QuoteInterval
from app.modules.quotes.schemas import QuoteSeries
from app.modules.quotes.service import FavoriteCheck, get_series
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

_SERVICE = "app.modules.quotes.service"

# The one market of the catalogue (A4). Written here rather than imported from the service on
# purpose: a constant asserted against itself proves nothing, and what this file fixes is the
# product decision, not the spelling of the name that holds it.
_MARKET = ZoneInfo("America/New_York")

_JUAN = 1
_TSLA = "TSLA"

# The four states of the contract (plan.md). A status outside this set is a frontend that has no
# notice to draw, which is the requirement broken from the other side.
_STATES = {"ok", "stale", "market_closed", "no_data"}

# The four ways the world can refuse to answer. None of them may escape the service:
# Answering 200 is what keeps a spent quota from becoming a 429 blaming a user who has no account
# anybody.
_FAILURES = [
    ProviderUnavailable("down"),
    ProviderQuotaExceeded("spent"),
    ProviderRejectedCredentials("bad key"),
    SymbolNotFound("no series for that symbol"),
]
_FAILURE_IDS = ["unavailable", "quota", "credentials", "unknown symbol"]

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


def _an_earlier_session() -> list[Quote]:
    """Three candles of a session three days back, which is never today whatever day it is.

    Three days rather than one is what makes the test independent of the day it runs on: a
    Monday would put "yesterday" on a Sunday that never traded, and the assertion would be about
    the calendar instead of about the rule.
    """
    opened = (
        (_now() - timedelta(days=3))
        .astimezone(_MARKET)
        .replace(hour=10, minute=0, second=0, microsecond=0)
    )

    return [_candle(opened.astimezone(UTC) + timedelta(minutes=minute)) for minute in range(3)]


class _Store:
    """Stand-in for `quotes/repository.py`, backed by rows instead of by a script."""

    def __init__(self, stored: Sequence[Quote] = ()) -> None:
        """Start from the candles the test says are already cached."""
        self.rows: dict[tuple[str, str, datetime], Quote] = {
            (row.symbol, row.interval, row.ts): row for row in stored
        }

    async def candles_in(
        self, symbol: str, interval: str, start: datetime, end: datetime
    ) -> list[Quote]:
        """The candles of that window, oldest first, which is what the chart reads."""
        return sorted(
            (
                row
                for key, row in self.rows.items()
                if key[0] == symbol and key[1] == interval and start <= row.ts <= end
            ),
            key=lambda row: row.ts,
        )

    async def newest_ts(self, symbol: str, interval: str) -> datetime | None:
        """The instant of the newest candle there is, or nothing if there is none."""
        instants = [key[2] for key in self.rows if key[0] == symbol and key[1] == interval]

        return max(instants) if instants else None

    async def save(self, symbol: str, interval: str, points: Sequence[QuotePoint]) -> int:
        """Upsert what the provider returned, the way the composite key makes it an upsert."""
        for point in points:
            self.rows[(symbol, interval, point.ts)] = _candle(
                point.ts, str(point.close), interval=interval
            )

        return len(points)


class _Provider(MarketDataProvider):
    """The contract, answering with points or failing with one of the four errors."""

    def __init__(
        self, points: Sequence[QuotePoint] = (), failure: ProviderError | None = None
    ) -> None:
        """Answer with those points, or fail with that error."""
        self.points = list(points)
        self.failure = failure
        self.calls: list[tuple[str, str, datetime, datetime]] = []

    async def list_stocks(self, exchange: str) -> list[StockRecord]:
        """Not what this service asks for; the catalogue is another module's business."""
        return []

    async def get_time_series(
        self, symbol: str, interval: str, start: datetime, end: datetime
    ) -> list[QuotePoint]:
        """Record the call before anything else, then answer or fail."""
        self.calls.append((symbol, interval, start, end))

        if self.failure is not None:
            raise self.failure

        return list(self.points)


@pytest.fixture(autouse=True)
def a_gate_that_remembers_nothing() -> Iterator[None]:
    """Empty the gate before and after each test, so no test can be decided by another one.

    The gate of `plan.md` is process state -- a lock plus the last attempt per
    `(symbol, interval)` -- so a leftover entry would suppress the provider call a test was
    written to make, and the status would come out of somebody else's arrangement. Reaching for
    the private name is the price of the gate being process state, and it is cheaper than a test
    that passes depending on what ran first.
    """
    gates = getattr(sys.modules.get(_SERVICE), "_GATEKEEPER", None)
    clear = getattr(gates, "clear", None)

    if callable(clear):
        clear()

    yield

    if callable(clear):
        clear()


async def _its_theirs(user_id: int, symbol: str) -> bool:
    """The default `FavoriteCheck`: whoever is asking follows the symbol."""
    return True


@pytest.fixture
def empty_cache() -> _Store:
    """A cache with nothing in it, handed to the service instead of patched into it."""
    return _Store()


def _cached(*candles: Quote) -> _Store:
    """A cache that already holds those candles."""
    return _Store(candles)


async def _ask(
    provider: MarketDataProvider,
    store: _Store,
    follows: FavoriteCheck = _its_theirs,
    interval: QuoteInterval = QuoteInterval.ONE_MINUTE,
) -> QuoteSeries:
    """One `Tiempo Real` call to the service, with the arguments `plan.md` fixes for it."""
    return await get_series(
        store,
        follows,
        provider,
        symbol=_TSLA,
        interval=interval,
        user_id=_JUAN,
        start=None,
        end=None,
    )


class TestDataThatIsUpToDate:
    """While what is charted is current, nothing is said about it."""

    async def test_fresh_data_is_ok(self, monkeypatch: pytest.MonkeyPatch) -> None:
        """The TTL is the interval, so a candle ten seconds old is still current."""
        store = _cached(_candle(_now() - timedelta(seconds=10)))

        series = await _ask(_Provider(), store)

        assert series.status == "ok"

    async def test_ok_carries_no_session_date(self, monkeypatch: pytest.MonkeyPatch) -> None:
        """`session_date` is the `{fecha}` of the notice and travels only with `market_closed`."""
        store = _cached(_candle(_now() - timedelta(seconds=10)))

        series = await _ask(_Provider(), store)

        assert series.session_date is None

    async def test_ok_still_carries_the_points(self, monkeypatch: pytest.MonkeyPatch) -> None:
        """From the happy side: there is always a chart, a notice, or both."""
        store = _cached(_candle(_now() - timedelta(seconds=10)))

        series = await _ask(_Provider(), store)

        assert series.points


class TestAProviderThatFailedIsStale:
    """the precedence they depend on."""

    async def test_a_failed_provider_with_a_warm_cache_is_stale(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """What is charted could not be refreshed, and that is what is said."""
        store = _cached(*_an_earlier_session())

        series = await _ask(_Provider(failure=ProviderQuotaExceeded("spent")), store)

        assert series.status == "stale"

    async def test_a_failed_provider_is_never_market_closed(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """The order of the chain, stated as the sentence it defends.

        Both branches are reachable here -- the provider refused *and* today has no candles --
        and only one of the two answers is honest: we do not know whether the market is closed
        or whether the provider is down, and saying the first would be inventing it.
        """
        store = _cached(*_an_earlier_session())

        series = await _ask(_Provider(failure=ProviderQuotaExceeded("spent")), store)

        assert series.status != "market_closed"

    async def test_a_stale_answer_still_carries_the_last_prices_known(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """The chart is drawn anyway, which is the whole point of the notice."""
        stored = _an_earlier_session()
        store = _cached(*stored)

        series = await _ask(_Provider(failure=ProviderUnavailable("no answer")), store)

        assert [point.ts for point in series.points] == [candle.ts for candle in stored]

    async def test_stale_carries_no_session_date(self, monkeypatch: pytest.MonkeyPatch) -> None:
        """The date belongs to the `market_closed` text and to no other (plan.md)."""
        store = _cached(*_an_earlier_session())

        series = await _ask(_Provider(failure=ProviderUnavailable("no answer")), store)

        assert series.session_date is None


class TestADayWithNoSessionShowsTheLastOne:
    """The Saturday of the demo, and the date that names it."""

    async def test_today_empty_with_an_earlier_session_stored_is_market_closed(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """The Saturday case: the provider has nothing for today because nothing traded."""
        store = _cached(*_an_earlier_session())

        series = await _ask(_Provider(points=[]), store)

        assert series.status == "market_closed"

    async def test_market_closed_charts_that_earlier_session(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """The last session there was, and not a blank screen."""
        stored = _an_earlier_session()
        store = _cached(*stored)

        series = await _ask(_Provider(points=[]), store)

        assert [point.ts for point in series.points] == [candle.ts for candle in stored]

    async def test_market_closed_names_the_day_that_session_traded(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """`session_date` is the `{fecha}` the notice puts in front of the user."""
        stored = _an_earlier_session()
        store = _cached(*stored)

        series = await _ask(_Provider(points=[]), store)

        assert series.session_date == stored[0].ts.astimezone(_MARKET).date()

    async def test_a_session_that_crosses_midnight_in_utc_is_still_one_day(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """The date is the market's, and the market is where the session happened.

        The stored candle is at 21:30 in New York, which is already the next day in UTC. An
        implementation that took the date off the instant as stored would answer tomorrow for
        yesterday's session, and the notice would name a day that never traded.
        """
        traded_on = (_now().astimezone(_MARKET) - timedelta(days=3)).date()
        late = datetime(
            traded_on.year, traded_on.month, traded_on.day, 21, 30, tzinfo=_MARKET
        ).astimezone(UTC)
        store = _cached(_candle(late))

        series = await _ask(_Provider(points=[]), store)

        assert series.session_date == traded_on


class TestNothingAnywhereIsNoData:
    """The symbol has no series for that interval, and it is said plainly."""

    async def test_an_empty_cache_and_an_empty_provider_is_no_data(
        self, empty_cache: _Store
    ) -> None:
        """Neither the cache nor the world has anything, which is a different thing from closed."""
        series = await _ask(_Provider(points=[]), empty_cache)

        assert series.status == "no_data"

    async def test_no_data_carries_no_points(self, empty_cache: _Store) -> None:
        """The screen has to tell an empty chart from a chart it never drew."""
        series = await _ask(_Provider(points=[]), empty_cache)

        assert series.points == ()

    async def test_no_data_carries_no_session_date(self, empty_cache: _Store) -> None:
        """There is no session to name, so no date is offered."""
        series = await _ask(_Provider(points=[]), empty_cache)

        assert series.session_date is None


class TestNoProviderFailureEscapes:
    """The four ways the world refuses are answered, never raised at the router."""

    @pytest.mark.parametrize("failure", _FAILURES, ids=_FAILURE_IDS)
    async def test_the_service_answers_instead_of_raising(
        self, monkeypatch: pytest.MonkeyPatch, failure: ProviderError
    ) -> None:
        """A failure upstream is not a failure of the endpoint (plan.md)."""
        store = _cached(*_an_earlier_session())

        series = await _ask(_Provider(failure=failure), store)

        assert series.status in _STATES

    @pytest.mark.parametrize("failure", _FAILURES, ids=_FAILURE_IDS)
    async def test_it_answers_even_with_nothing_cached(
        self, empty_cache: _Store, failure: ProviderError
    ) -> None:
        """The harder half: nothing to fall back on, and still an answer and not an exception."""
        series = await _ask(_Provider(failure=failure), empty_cache)

        assert series.status in _STATES

    @pytest.mark.parametrize("failure", _FAILURES, ids=_FAILURE_IDS)
    async def test_no_failure_is_caught_in_silence(
        self,
        monkeypatch: pytest.MonkeyPatch,
        captured_logs: list[str],
        failure: ProviderError,
    ) -> None:
        """Every `except` decides *and* leaves a line behind.

        A swallowed failure is the one that costs most later: the screen says `stale`, the chart
        looks plausible, and there is nothing anywhere saying why the data stopped moving.
        """
        store = _cached(*_an_earlier_session())

        await _ask(_Provider(failure=failure), store)

        assert captured_logs


class TestTheProviderIsNeverNamed:
    """The user has no account with anybody, and neither does a log line."""

    @pytest.mark.parametrize("failure", _FAILURES, ids=_FAILURE_IDS)
    async def test_what_is_answered_does_not_name_the_provider(
        self, monkeypatch: pytest.MonkeyPatch, failure: ProviderError
    ) -> None:
        """The status says what happened, never who failed."""
        store = _cached(*_an_earlier_session())

        series = await _ask(_Provider(failure=failure), store)

        assert "twelvedata" not in repr(series).lower()

    @pytest.mark.parametrize("failure", _FAILURES, ids=_FAILURE_IDS)
    async def test_the_log_of_a_failure_does_not_name_the_provider(
        self,
        monkeypatch: pytest.MonkeyPatch,
        captured_logs: list[str],
        failure: ProviderError,
    ) -> None:
        """A log line ends up in a dashboard and in a screenshot, and both are covered."""
        store = _cached(*_an_earlier_session())

        await _ask(_Provider(failure=failure), store)

        assert not any("twelvedata" in line.lower() for line in captured_logs)
