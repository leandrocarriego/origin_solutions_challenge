"""The catalogue reconciles against the provider's snapshot; it does not accumulate (ADR-002).

The response of `/stocks` is what is listed today and carries no status field, so the only signal
that a symbol stopped trading is that it stopped coming back. An upsert cannot see an absence,
which is why a catalogue kept by upserts grows forever and drifts from reality. These tests are
the difference between the two.

They run against Postgres and not a double (TEST-02), each inside a transaction that is rolled
back, and the provider is a stub: no test here spends a request of the Article II quota.
"""

from datetime import datetime

import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.stocks.models import Stock
from app.modules.stocks.repository import StockRepository
from app.modules.stocks.service import reconcile_catalogue
from app.providers import MarketDataProvider, ProviderUnavailable, QuotePoint, StockRecord


def listed(
    symbol: str,
    name: str = "A Company, Inc.",
    instrument_type: str = "Common Stock",
    exchange: str = "NASDAQ",
) -> StockRecord:
    """One row as the provider would send it."""
    return StockRecord(
        symbol=symbol,
        name=name,
        currency="USD",
        exchange=exchange,
        mic_code="XNGS",
        country="United States",
        instrument_type=instrument_type,
    )


class StubProvider(MarketDataProvider):
    """Answers a fixed snapshot per exchange, or raises for the ones told to fail."""

    def __init__(
        self, snapshots: dict[str, list[StockRecord]], failing: set[str] | None = None
    ) -> None:
        """Take what each exchange answers, and which ones answer with a failure."""
        self._snapshots = snapshots
        self._failing = failing or set()
        self.calls: list[str] = []

    async def list_stocks(self, exchange: str) -> list[StockRecord]:
        """The snapshot for that market, recording that it was asked for."""
        self.calls.append(exchange)
        if exchange in self._failing:
            raise ProviderUnavailable("the provider did not answer")

        return self._snapshots.get(exchange, [])

    async def get_time_series(
        self, symbol: str, interval: str, start: datetime, end: datetime
    ) -> list[QuotePoint]:
        """Not used by the ingestion."""
        return []


async def symbols_in(session: AsyncSession) -> dict[str, Stock]:
    """Every row of the catalogue, by symbol."""
    rows = (await session.scalars(select(Stock))).all()

    return {row.symbol: row for row in rows}


class TestItBringsInWhatIsNew:
    """The first run of an empty catalogue, and every symbol listed since."""

    async def test_it_inserts_the_symbols_the_provider_lists(self, session: AsyncSession) -> None:
        """Nothing in the table, four in the snapshot: four rows afterwards."""
        provider = StubProvider({"NASDAQ": [listed("TSLA"), listed("AAPL"), listed("NFLX")]})

        await reconcile_catalogue(StockRepository(session), provider, "NASDAQ")

        assert set(await symbols_in(session)) == {"TSLA", "AAPL", "NFLX"}

    async def test_it_drops_what_the_ingestion_filter_rejects(self, session: AsyncSession) -> None:
        """The filter of ADR-001 runs before anything reaches the table."""
        provider = StubProvider(
            {
                "NASDAQ": [
                    listed("TSLA"),
                    listed("!otc/FLZH"),
                    listed("ACHRWT", instrument_type="Warrant"),
                ]
            }
        )

        await reconcile_catalogue(StockRepository(session), provider, "NASDAQ")

        assert set(await symbols_in(session)) == {"TSLA"}

    async def test_it_records_when_each_symbol_was_last_seen(self, session: AsyncSession) -> None:
        """Telling "still listed" from "never checked" is what makes a delisting detectable."""
        provider = StubProvider({"NASDAQ": [listed("TSLA")]})

        await reconcile_catalogue(StockRepository(session), provider, "NASDAQ")

        assert (await symbols_in(session))["TSLA"].last_seen_at is not None


class TestItUpdatesWhatChanged:
    """A company renames, and the catalogue is where the name is stored once."""

    async def test_it_updates_a_name_that_changed(self, session: AsyncSession) -> None:
        """REQ-08 stores the name in `stocks`, so a stale name there is stale everywhere."""
        await reconcile_catalogue(
            StockRepository(session),
            StubProvider({"NASDAQ": [listed("TSLA", name="Tesla Motors, Inc.")]}),
            "NASDAQ",
        )

        await reconcile_catalogue(
            StockRepository(session),
            StubProvider({"NASDAQ": [listed("TSLA", name="Tesla, Inc.")]}),
            "NASDAQ",
        )

        assert (await symbols_in(session))["TSLA"].name == "Tesla, Inc."


class TestItMarksWhatIsGone:
    """The half an upsert cannot do, and the reason this is a reconciliation."""

    async def test_a_symbol_that_stopped_coming_back_is_marked_delisted(
        self, session: AsyncSession
    ) -> None:
        """The absence is the signal: the provider sends no status field."""
        await reconcile_catalogue(
            StockRepository(session),
            StubProvider({"NASDAQ": [listed("TSLA"), listed("OLD")]}),
            "NASDAQ",
        )

        await reconcile_catalogue(
            StockRepository(session), StubProvider({"NASDAQ": [listed("TSLA")]}), "NASDAQ"
        )

        assert (await symbols_in(session))["OLD"].delisted_at is not None

    async def test_it_never_deletes_the_row(self, session: AsyncSession) -> None:
        """`user_stocks` and `quotes` reference it: deleting takes away a favourite or a history."""
        await reconcile_catalogue(
            StockRepository(session), StubProvider({"NASDAQ": [listed("OLD")]}), "NASDAQ"
        )

        await reconcile_catalogue(StockRepository(session), StubProvider({"NASDAQ": []}), "NASDAQ")

        assert "OLD" in await symbols_in(session)

    async def test_a_symbol_that_comes_back_stops_being_delisted(
        self, session: AsyncSession
    ) -> None:
        """A relisting is as real as a delisting, and leaving the mark would hide the symbol."""
        await reconcile_catalogue(
            StockRepository(session), StubProvider({"NASDAQ": [listed("TSLA")]}), "NASDAQ"
        )
        await reconcile_catalogue(StockRepository(session), StubProvider({"NASDAQ": []}), "NASDAQ")

        await reconcile_catalogue(
            StockRepository(session), StubProvider({"NASDAQ": [listed("TSLA")]}), "NASDAQ"
        )

        assert (await symbols_in(session))["TSLA"].delisted_at is None


class TestItIsSafeToRunAgain:
    """It runs on every start and every day, so running twice has to be running once."""

    async def test_running_it_twice_changes_nothing(self, session: AsyncSession) -> None:
        """A catalogue that drifts on a second run would drift on every scheduled refresh."""
        provider = StubProvider({"NASDAQ": [listed("TSLA"), listed("AAPL")]})
        await reconcile_catalogue(StockRepository(session), provider, "NASDAQ")
        first = {symbol: row.delisted_at for symbol, row in (await symbols_in(session)).items()}

        await reconcile_catalogue(StockRepository(session), provider, "NASDAQ")

        assert {
            symbol: row.delisted_at for symbol, row in (await symbols_in(session)).items()
        } == first


class TestOneExchangeDoesNotSpeakForAnother:
    """The failure mode that would cost the most, and the reason it is part of the decision."""

    async def test_it_only_touches_the_exchange_it_was_given(self, session: AsyncSession) -> None:
        """NYSE's snapshot says nothing about NASDAQ, so it cannot delist it."""
        await reconcile_catalogue(
            StockRepository(session), StubProvider({"NASDAQ": [listed("TSLA")]}), "NASDAQ"
        )

        await reconcile_catalogue(StockRepository(session), StubProvider({"NYSE": []}), "NYSE")

        assert (await symbols_in(session))["TSLA"].delisted_at is None

    async def test_a_snapshot_that_failed_delists_nothing(self, session: AsyncSession) -> None:
        """Marking everything that "did not arrive" would delist the whole exchange."""
        await reconcile_catalogue(
            StockRepository(session), StubProvider({"NASDAQ": [listed("TSLA")]}), "NASDAQ"
        )

        with pytest.raises(ProviderUnavailable):
            await reconcile_catalogue(
                StockRepository(session), StubProvider({}, failing={"NASDAQ"}), "NASDAQ"
            )

        assert (await symbols_in(session))["TSLA"].delisted_at is None


class TestACatalogueThatIsActuallyBig:
    """The real one is 7.155 rows, and that is where a statement stops being one statement."""

    async def test_it_ingests_more_rows_than_fit_in_a_single_statement(
        self, session: AsyncSession
    ) -> None:
        """Past 32767 bind parameters asyncpg refuses, and nine columns reach that at 3641.

        Found in production on the first real ingestion, with the whole catalogue behind it.
        Every test above uses three rows, so none of them could ever have seen it.
        """
        snapshot = [listed(f"SYM{index:04d}") for index in range(4000)]

        await reconcile_catalogue(
            StockRepository(session), StubProvider({"NASDAQ": snapshot}), "NASDAQ"
        )

        assert len(await symbols_in(session)) == 4000
