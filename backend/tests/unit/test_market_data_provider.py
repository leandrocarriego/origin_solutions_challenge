"""The contract every provider implements, and the fake that runs the suite.

`MarketDataProvider` is an abstract base class, so a missing method fails when someone tries to
build the object rather than only under `mypy`. These tests are what say that is true.

`FakeProvider` is not a convenience: the whole suite runs with no network and no API
key, and the the quota quota is why. A fake that drifts from the contract leaves the suite green
against a shape the real provider stopped returning, which is the failure this abstraction chose the
explicit contract to avoid.
"""

import inspect
from datetime import UTC, datetime, timedelta
from decimal import Decimal

import pytest

from app.providers import (
    FakeProvider,
    MarketDataProvider,
    QuotePoint,
    StockRecord,
)

# One day of the fixed session, aware and in UTC: the window a service hands a provider.
_WINDOW = (datetime(2026, 9, 11, tzinfo=UTC), datetime(2026, 9, 12, tzinfo=UTC))


class TestTheContractIsAbstract:
    """An abstract base class refuses to be built, which is the point of choosing one."""

    def test_the_contract_cannot_be_instantiated(self) -> None:
        """Building the abstraction itself would mean the contract had an implementation."""
        with pytest.raises(TypeError):
            MarketDataProvider()  # type: ignore[abstract]

    def test_an_implementation_that_forgets_a_method_cannot_be_built(self) -> None:
        """This is what the ABC buys over a Protocol: it fails without anyone running mypy."""

        class Incomplete(MarketDataProvider):
            """Implements one of the two methods, and is therefore still abstract."""

            async def list_stocks(self, exchange: str) -> list[StockRecord]:
                """Half a provider."""
                return []

        with pytest.raises(TypeError):
            Incomplete()  # type: ignore[abstract]

    @pytest.mark.parametrize("method", ["list_stocks", "get_time_series"])
    def test_the_contract_declares_the_two_methods_it_needs(self, method: str) -> None:
        """`list_stocks` feeds the catalogue reconciliation; `get_time_series` feeds the chart."""
        assert getattr(MarketDataProvider, method, None) is not None

    def test_there_is_no_search_method(self) -> None:
        """Searching is a Postgres query, not a capability of the provider."""
        declared = {
            name
            for name, _ in inspect.getmembers(MarketDataProvider, inspect.isfunction)
            if not name.startswith("_")
        }

        assert declared == {"list_stocks", "get_time_series"}


class TestTheFakeIsARealImplementation:
    """The fake runs the whole suite, so it has to be the same shape as the real one."""

    def test_it_implements_the_contract(self) -> None:
        """A fake that is not a provider is a second shape nobody keeps in sync."""
        assert isinstance(FakeProvider(), MarketDataProvider)

    async def test_it_answers_the_catalogue_with_the_contract_type(self) -> None:
        """The provider returns its own types and never the JSON it received."""
        catalogue = await FakeProvider().list_stocks("NASDAQ")

        assert catalogue
        assert all(isinstance(entry, StockRecord) for entry in catalogue)

    async def test_it_answers_a_series_with_the_contract_type(self) -> None:
        """Same for the series: a dict of strings would push parsing into the service."""
        series = await FakeProvider().get_time_series(
            "TSLA",
            "1min",
            datetime(2026, 9, 11, tzinfo=UTC),
            datetime(2026, 9, 12, tzinfo=UTC),
        )

        assert series
        assert all(isinstance(point, QuotePoint) for point in series)

    async def test_it_answers_the_same_thing_twice(self) -> None:
        """A fake that varies makes a failing test a coin toss instead of a bug."""
        provider = FakeProvider()
        window = (datetime(2026, 9, 11, tzinfo=UTC), datetime(2026, 9, 12, tzinfo=UTC))

        first = await provider.get_time_series("TSLA", "1min", *window)
        second = await provider.get_time_series("TSLA", "1min", *window)

        assert first == second

    async def test_its_prices_are_decimals(self) -> None:
        """Money is never a float, in the fake as much as in the real one."""
        series = await FakeProvider().get_time_series(
            "TSLA",
            "1min",
            datetime(2026, 9, 11, tzinfo=UTC),
            datetime(2026, 9, 12, tzinfo=UTC),
        )

        assert isinstance(series[0].close, Decimal)

    async def test_it_knows_the_symbols_the_wireframe_uses(self) -> None:
        """The demo of the brief is TSLA, AAPL and NFLX: the fake has to be able to serve them."""
        catalogue = await FakeProvider().list_stocks("NASDAQ")

        assert {"TSLA", "AAPL", "NFLX"} <= {entry.symbol for entry in catalogue}


class TestTheSeriesIsAnsweredInUtc:
    """The window goes out aware in UTC, and the answer comes back the same.

    The most expensive bug of the chart is a series sitting four or five hours away from where it
    belongs, with nothing failing anywhere: every point still lands neatly on an axis. The real
    client's half of that is fixed against the recorded JSON, in `test_upstream_client.py`. What
    belongs here is the contract's half -- what *any* implementation has to hand the service, the
    fake that runs the whole suite included, since it is also what runs locally.
    """

    async def test_its_instants_are_aware(self) -> None:
        """A naive instant read as a market hour and as a server hour is two different charts."""
        series = await FakeProvider().get_time_series("TSLA", "1min", *_WINDOW)

        assert all(point.ts.tzinfo is not None for point in series)

    async def test_its_instants_carry_no_offset(self) -> None:
        """UTC on the wire and in the cache; the market hour is presentation (plan.md)."""
        series = await FakeProvider().get_time_series("TSLA", "1min", *_WINDOW)

        assert all(point.ts.utcoffset() == timedelta(0) for point in series)

    async def test_no_point_falls_outside_the_window_it_was_asked_for(self) -> None:
        """The service stores what it is given, so a point outside the window is cache poison."""
        start, end = _WINDOW

        series = await FakeProvider().get_time_series("TSLA", "1min", start, end)

        assert all(start <= point.ts <= end for point in series)
