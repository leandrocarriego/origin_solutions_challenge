"""The catalogue: what is worth ingesting, and how a snapshot becomes the table (ADR-002)."""

import asyncio
import re
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta

import structlog
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import SessionFactory
from app.modules.stocks.repository import last_seen, mark_absent_as_delisted, upsert
from app.observability import CATALOGUE_LAST_SUCCESS
from app.providers import MarketDataProvider, ProviderError, StockRecord, get_market_data_provider

log = structlog.get_logger()

# The two markets of A4: the brief's text says NYSE and the three symbols of its own grid are
# NASDAQ, so following it to the letter would leave its own screen impossible to reproduce.
CATALOGUE_EXCHANGES = ("NYSE", "NASDAQ")

# How old the catalogue may get before it is refreshed. Two credits out of 800 buys a full
# refresh, so the window is about how stale a new listing may be, not about cost.
MAX_CATALOGUE_AGE = timedelta(hours=24)

# The symbol travels in the URL (REQ-11), and a slash in it is not a symbol, it is a route. Dots
# and dashes are legal inside a path segment, so they stay: dropping them would lose real
# companies (BRK.B, ABR-D).
ROUTABLE_SYMBOL = re.compile(r"^[A-Z0-9][A-Z0-9.\-]{0,8}$")

# The only type dropped. A warrant is a derivative, not a stock, and it is the only thing that
# duplicates a symbol in the catalogue -- which is what makes ADR-001's natural key true.
# Narrower than Common-Stock-only on purpose: that would have thrown away 393 ADRs and 214 REITs
# that collide with nothing and that somebody may search for.
DERIVATIVE = "Warrant"


@dataclass(frozen=True, slots=True)
class CatalogueReconciliation:
    """What one reconciliation did, for the log line and the metric that follow it."""

    exchange: str
    listed: int
    delisted: int
    discarded: int


def is_worth_ingesting(record: StockRecord) -> bool:
    """Whether a catalogue entry may become a row of `stocks` (ADR-001)."""
    if record.instrument_type == DERIVATIVE:
        return False

    return bool(ROUTABLE_SYMBOL.match(record.symbol))


async def reconcile_catalogue(
    session: AsyncSession, provider: MarketDataProvider, exchange: str
) -> CatalogueReconciliation:
    """Bring the catalogue of one market in line with what the provider lists today.

    Three outcomes per symbol: new ones are inserted, known ones are refreshed, and the ones
    that stopped coming back are marked `delisted_at`. That third branch is the whole point --
    the provider's response carries no status field, so an absence is the only signal that a
    symbol stopped trading, and an upsert cannot see an absence.

    The snapshot is fetched first and on its own. If the provider fails, the exception leaves
    this function before anything is written: reconciling against half a snapshot would mark
    everything that did not arrive as delisted, which for a failed request is the whole market.
    """
    snapshot = await provider.list_stocks(exchange)

    keeping = [record for record in snapshot if is_worth_ingesting(record)]
    now = datetime.now(UTC)

    await upsert(session, keeping, seen_at=now)
    delisted = await mark_absent_as_delisted(
        session, exchange, {record.symbol for record in keeping}, at=now
    )
    await session.commit()

    return CatalogueReconciliation(
        exchange=exchange,
        listed=len(keeping),
        delisted=delisted,
        discarded=len(snapshot) - len(keeping),
    )


@dataclass(frozen=True, slots=True)
class CatalogueRefresh:
    """What one scheduled refresh did, including the markets that did not answer."""

    reconciled: tuple[CatalogueReconciliation, ...]
    failed: tuple[str, ...]
    skipped: bool


async def is_catalogue_stale(session: AsyncSession, older_than: timedelta) -> bool:
    """Whether the catalogue is old enough to be worth spending two requests on.

    A catalogue nobody ever ingested is stale: an empty table is not fresh, it is unknown.
    """
    seen = await last_seen(session)
    if seen is None:
        return True

    return datetime.now(UTC) - seen > older_than


async def refresh_catalogue_if_stale(
    session: AsyncSession,
    provider: MarketDataProvider,
    older_than: timedelta = MAX_CATALOGUE_AGE,
) -> CatalogueRefresh:
    """Reconcile both markets, but only when the catalogue has gone stale.

    The staleness check is what keeps this affordable in the one case that would not be:
    `restart: unless-stopped` can try many times a minute, and a refresh on every start turns a
    crash loop into an exhausted quota.

    It never raises. This runs as a background task, and an exception there kills the task for
    the life of the process -- the catalogue would stop refreshing with nothing to show for it.
    A market that failed comes back in the result and in the log instead.
    """
    if not await is_catalogue_stale(session, older_than=older_than):
        return CatalogueRefresh(reconciled=(), failed=(), skipped=True)

    done: list[CatalogueReconciliation] = []
    failed: list[str] = []

    for exchange in CATALOGUE_EXCHANGES:
        try:
            done.append(await reconcile_catalogue(session, provider, exchange))
        except ProviderError as error:
            # One market is one snapshot. Skipping the other because this one timed out would
            # be losing data for no reason.
            failed.append(exchange)
            await log.awarning(
                "catalogue_refresh_failed", exchange=exchange, reason=type(error).__name__
            )

    if done:
        # Only on a success: a gauge that advances after a failure is a dashboard that lies
        # about being healthy.
        CATALOGUE_LAST_SUCCESS.set(datetime.now(UTC).timestamp())

    await log.ainfo(
        "catalogue_refreshed",
        reconciled=[outcome.exchange for outcome in done],
        failed=failed,
    )

    return CatalogueRefresh(reconciled=tuple(done), failed=tuple(failed), skipped=False)


async def keep_the_catalogue_fresh(every: timedelta = MAX_CATALOGUE_AGE) -> None:
    """Refresh the catalogue when it goes stale, for as long as the process lives (ADR-002).

    Started by the composition root and cancelled with it. The first pass happens immediately,
    which is what covers the case of a container that came up after being down for a week; the
    staleness check is what stops that from costing anything when it came up ten seconds ago.

    Nothing escapes this loop. A background task that raises is a background task that is gone,
    and a catalogue that silently stopped refreshing looks exactly like one that is up to date
    -- which is why the freshness is a gauge and why this catches everything.
    """
    while True:
        try:
            async with SessionFactory() as session:
                await refresh_catalogue_if_stale(session, get_market_data_provider())
        except asyncio.CancelledError:
            raise
        except Exception as error:  # noqa: BLE001 -- see the docstring: the loop has to survive
            await log.aexception("catalogue_refresh_crashed", reason=type(error).__name__)

        await asyncio.sleep(every.total_seconds())
