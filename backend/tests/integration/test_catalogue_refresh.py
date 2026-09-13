"""Nobody has to remember to refresh the catalogue (ADR-002).

The reconciliation exists and works, and that is not enough: a catalogue refreshed by whoever
remembers is the thing ADR-002 was rewritten to stop being. So it runs on its own -- when the
process starts if the last success is older than a day, and once a day after that.

Two credits per full refresh out of 800 is 0.25% of the quota, which is what makes "refresh
automatically" a rounding error instead of a decision. But the staleness check is not decoration:
`restart: unless-stopped` can try many times a minute, and a refresh on every start would turn a
crash loop into an exhausted quota.

And the freshness is published, because "the catalogue is up to date" has to be something
somebody can look at rather than something everybody assumes.
"""

from datetime import UTC, datetime, timedelta

from prometheus_client import REGISTRY
from sqlalchemy import update
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.stocks.models import Stock
from app.modules.stocks.service import (
    CATALOGUE_EXCHANGES,
    is_catalogue_stale,
    reconcile_catalogue,
    refresh_catalogue_if_stale,
)
from tests.integration.test_catalogue_ingestion import StubProvider, listed

A_DAY = timedelta(hours=24)


async def age_the_catalogue(session: AsyncSession, by: timedelta) -> None:
    """Move every `last_seen_at` back, so staleness can be tested without waiting a day."""
    await session.execute(update(Stock).values(last_seen_at=datetime.now(UTC) - by))


class TestWhenTheCatalogueIsStale:
    """The question the refresher asks before spending a request."""

    async def test_a_catalogue_that_was_never_ingested_is_stale(
        self, session: AsyncSession
    ) -> None:
        """An empty table is not fresh, it is unknown, and the difference matters on first boot."""
        assert await is_catalogue_stale(session, older_than=A_DAY)

    async def test_a_catalogue_ingested_just_now_is_not_stale(self, session: AsyncSession) -> None:
        """This is the guard that stops a restart loop from spending the day's quota."""
        await reconcile_catalogue(session, StubProvider({"NASDAQ": [listed("TSLA")]}), "NASDAQ")

        assert not await is_catalogue_stale(session, older_than=A_DAY, exchange="NASDAQ")

    async def test_a_catalogue_older_than_the_window_is_stale(self, session: AsyncSession) -> None:
        """A day is the window ADR-002 chose, and it is an argument so it can be changed."""
        await reconcile_catalogue(session, StubProvider({"NASDAQ": [listed("TSLA")]}), "NASDAQ")
        await age_the_catalogue(session, by=timedelta(hours=25))

        assert await is_catalogue_stale(session, older_than=A_DAY, exchange="NASDAQ")


class TestTheRefresherSpendsNothingItDoesNotNeed:
    """Every request it does not make is a request the chart can make instead."""

    async def test_it_does_not_call_the_provider_when_every_market_is_fresh(
        self, session: AsyncSession
    ) -> None:
        """The whole point of the staleness check: no call at all, not a cheaper call.

        Every market, not the catalogue as a whole. The first version of this test refreshed
        one and expected silence, which is what let a failed NASDAQ hide behind a fresh NYSE.
        """
        for exchange in CATALOGUE_EXCHANGES:
            await reconcile_catalogue(
                session,
                StubProvider({exchange: [listed(f"X{exchange}", exchange=exchange)]}),
                exchange,
            )
        provider = StubProvider({"NASDAQ": [listed("TSLA")], "NYSE": []})

        await refresh_catalogue_if_stale(session, provider, older_than=A_DAY)

        assert provider.calls == []

    async def test_a_market_that_failed_is_retried_while_the_other_stays_fresh(
        self, session: AsyncSession
    ) -> None:
        """The bug the first real ingestion found, and the reason staleness is per market.

        NYSE answered and NASDAQ did not, so the table as a whole looked fresh and the market
        that failed was not retried for a day. It is retried on the next pass now, and the one
        that succeeded is not asked again.
        """
        await refresh_catalogue_if_stale(
            session,
            StubProvider({"NYSE": [listed("A", exchange="NYSE")]}, failing={"NASDAQ"}),
            older_than=A_DAY,
        )
        provider = StubProvider(
            {"NASDAQ": [listed("TSLA")], "NYSE": [listed("A", exchange="NYSE")]}
        )

        await refresh_catalogue_if_stale(session, provider, older_than=A_DAY)

        assert provider.calls == ["NASDAQ"]

    async def test_it_refreshes_both_markets_when_the_catalogue_is_stale(
        self, session: AsyncSession
    ) -> None:
        """A4: NYSE and NASDAQ, because the brief's own grid is NASDAQ and its text says NYSE."""
        provider = StubProvider(
            {"NASDAQ": [listed("TSLA")], "NYSE": [listed("A", exchange="NYSE")]}
        )

        await refresh_catalogue_if_stale(session, provider, older_than=A_DAY)

        assert sorted(provider.calls) == sorted(CATALOGUE_EXCHANGES)

    async def test_the_two_markets_of_a4_are_the_ones_it_refreshes(self) -> None:
        """Written down, because dropping one silently would empty half the autocomplete."""
        assert set(CATALOGUE_EXCHANGES) == {"NYSE", "NASDAQ"}


class TestOneMarketFailingDoesNotStopTheOther:
    """They are independent snapshots, and a bad day for one is not a reason to skip both."""

    async def test_the_market_that_answered_is_still_reconciled(
        self, session: AsyncSession
    ) -> None:
        """Skipping NASDAQ because NYSE timed out would be losing data for no reason."""
        provider = StubProvider({"NASDAQ": [listed("TSLA")]}, failing={"NYSE"})

        await refresh_catalogue_if_stale(session, provider, older_than=A_DAY)

        assert await session.get(Stock, "TSLA") is not None

    async def test_it_reports_the_market_that_failed(self, session: AsyncSession) -> None:
        """A refresh that half worked has to say so, or it reads as a refresh that worked."""
        provider = StubProvider({"NASDAQ": [listed("TSLA")]}, failing={"NYSE"})

        outcome = await refresh_catalogue_if_stale(session, provider, older_than=A_DAY)

        assert outcome.failed == ("NYSE",)

    async def test_it_does_not_raise_when_a_market_fails(self, session: AsyncSession) -> None:
        """It runs in the background: an exception there takes the task down for good."""
        provider = StubProvider({}, failing={"NYSE", "NASDAQ"})

        outcome = await refresh_catalogue_if_stale(session, provider, older_than=A_DAY)

        assert sorted(outcome.failed) == sorted(CATALOGUE_EXCHANGES)


class TestTheFreshnessIsPublished:
    """Being up to date becomes something to look at instead of something to assume."""

    async def test_the_gauge_carries_the_instant_of_the_last_success(
        self, session: AsyncSession
    ) -> None:
        """Grafana charts its age, so a refresher that quietly died is visible (ADR-009)."""
        provider = StubProvider({"NASDAQ": [listed("TSLA")], "NYSE": [listed("A")]})

        await refresh_catalogue_if_stale(session, provider, older_than=A_DAY)

        published = REGISTRY.get_sample_value("catalogue_last_success_timestamp_seconds")
        assert published is not None
        assert abs(published - datetime.now(UTC).timestamp()) < 60

    async def test_a_refresh_where_everything_failed_does_not_move_the_gauge(
        self, session: AsyncSession
    ) -> None:
        """A gauge that advances on failure is a dashboard that lies about being healthy."""
        provider = StubProvider(
            {"NASDAQ": [listed("TSLA")], "NYSE": [listed("A", exchange="NYSE")]}
        )
        await refresh_catalogue_if_stale(session, provider, older_than=A_DAY)
        before = REGISTRY.get_sample_value("catalogue_last_success_timestamp_seconds")

        await age_the_catalogue(session, by=timedelta(hours=25))
        await refresh_catalogue_if_stale(
            session, StubProvider({}, failing=set(CATALOGUE_EXCHANGES)), older_than=A_DAY
        )

        assert REGISTRY.get_sample_value("catalogue_last_success_timestamp_seconds") == before
