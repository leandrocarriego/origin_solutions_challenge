"""The catalogue: what is worth ingesting, and how a snapshot becomes the table."""

import asyncio
import re
from collections.abc import Sequence
from datetime import UTC, datetime, timedelta
from typing import Protocol

import structlog
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import SessionDep, SessionFactory
from app.modules.stocks.models import Stock
from app.modules.stocks.repository import StockRepository
from app.modules.stocks.schemas import (
    CatalogueReconciliation,
    CatalogueRefresh,
    StockInfo,
)
from app.observability import CATALOGUE_LAST_SUCCESS
from app.providers import MarketDataProvider, ProviderError, StockRecord, get_market_data_provider

log = structlog.get_logger()

# The two markets of A4: the brief's text says NYSE and the three symbols of its own grid are
# NASDAQ, so following it to the letter would leave its own screen impossible to reproduce.
CATALOGUE_EXCHANGES = ("NYSE", "NASDAQ")

# How old the catalogue may get before it is refreshed.
MAX_CATALOGUE_AGE = timedelta(hours=24)

# The symbol travels in the URL, and a slash in it is not a symbol, it is a route.
ROUTABLE_SYMBOL = re.compile(r"^[A-Z0-9][A-Z0-9.\-]{0,8}$")

# The only type dropped. A warrant is a derivative, not a stock, and it is the only thing that
# duplicates a symbol in the catalogue.
DERIVATIVE = "Warrant"


def is_worth_ingesting(record: StockRecord) -> bool:
    """Whether a catalogue entry may become a row of `stocks`."""
    if record.instrument_type == DERIVATIVE:
        return False

    return bool(ROUTABLE_SYMBOL.match(record.symbol))


class SymbolLookup(Protocol):
    """What describing a symbol needs, and no more.

    Narrower than `CatalogueStore` on purpose: `describe` is what the cross-module entry runs
    on, and a lookup that also demanded `commit()` would make every caller carry a write it
    never makes.
    """

    async def find_many(self, symbols: Sequence[str]) -> list[Stock]:
        """The rows of those symbols, in one query."""
        ...


class CatalogueStore(SymbolLookup, Protocol):
    """What this module needs from whatever stores the catalogue it serves."""

    async def upsert(self, records: list[StockRecord], seen_at: datetime) -> None:
        """Write those entries, refreshing the ones already there."""
        ...

    async def mark_absent_as_delisted(
        self, exchange: str, still_listed: set[str], at: datetime
    ) -> int:
        """Mark every symbol of that market the snapshot no longer carries."""
        ...

    async def last_seen(self, exchange: str) -> datetime | None:
        """When that market was last reconciled, or nothing if it never was."""
        ...

    async def search_listed(self, text: str, limit: int) -> list[Stock]:
        """Candidates still trading whose symbol or name contains that text."""
        ...

    async def commit(self) -> None:
        """Make permanent what the reconciliation wrote."""
        ...


def catalogue_store(session: SessionDep) -> CatalogueStore:
    """The catalogue a route is served with."""
    return StockRepository(session)


async def reconcile_catalogue(
    store: CatalogueStore, provider: MarketDataProvider, exchange: str
) -> CatalogueReconciliation:
    """Bring the catalogue of one market in line with what the provider lists today."""
    snapshot = await provider.list_stocks(exchange)

    keeping = [record for record in snapshot if is_worth_ingesting(record)]
    now = datetime.now(UTC)

    await store.upsert(keeping, seen_at=now)
    delisted = await store.mark_absent_as_delisted(
        exchange, {record.symbol for record in keeping}, at=now
    )
    await store.commit()

    return CatalogueReconciliation(
        exchange=exchange,
        listed=len(keeping),
        delisted=delisted,
        discarded=len(snapshot) - len(keeping),
    )


async def is_catalogue_stale(
    store: CatalogueStore, older_than: timedelta, exchange: str | None = None
) -> bool:
    """Whether the catalogue is old enough to be worth spending a request on."""
    markets = (exchange,) if exchange is not None else CATALOGUE_EXCHANGES
    now = datetime.now(UTC)

    for market in markets:
        seen = await store.last_seen(market)

        if seen is None or now - seen > older_than:
            return True

    return False


async def _publish_catalogue_age(store: CatalogueStore) -> None:
    """Set the gauge from the database, which outlives the process that fills it.

    The oldest market wins: the panel reads the age of the catalogue, and a catalogue is as old
    as the market that was reconciled longest ago.
    """
    seen = [await store.last_seen(market) for market in CATALOGUE_EXCHANGES]
    known = [moment for moment in seen if moment is not None]

    if known:
        CATALOGUE_LAST_SUCCESS.set(min(known).timestamp())


async def refresh_catalogue_if_stale(
    store: CatalogueStore,
    provider: MarketDataProvider,
    older_than: timedelta = MAX_CATALOGUE_AGE,
) -> CatalogueRefresh:
    """Reconcile both markets, but only when the catalogue has gone stale."""
    stale = [
        exchange
        for exchange in CATALOGUE_EXCHANGES
        if await is_catalogue_stale(store, older_than=older_than, exchange=exchange)
    ]

    if not stale:
        # A gauge lives in the process, and the process restarts. After a deploy this one reads
        # zero -- which the dashboard shows as "sin refrescar" -- until the next reconciliation,
        # and the next one may be a day away precisely because the catalogue is fresh. The
        # database remembers what the process forgot, so a skip is the moment to restore it.
        await _publish_catalogue_age(store)

        await log.adebug("catalogue_refresh_skipped", reason="every market is fresh")

        return CatalogueRefresh(reconciled=(), failed=(), skipped=True)

    done: list[CatalogueReconciliation] = []
    failed: list[str] = []

    for exchange in stale:
        try:
            done.append(await reconcile_catalogue(store, provider, exchange))

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
    """Refresh the catalogue when it goes stale, for as long as the process lives."""
    while True:
        try:
            async with SessionFactory() as session:
                await refresh_catalogue_if_stale(
                    StockRepository(session), get_market_data_provider()
                )

        except asyncio.CancelledError:
            raise

        except Exception as error:  # noqa: BLE001 -- see the docstring: the loop has to survive
            await log.aexception("catalogue_refresh_crashed", reason=type(error).__name__)

        await asyncio.sleep(every.total_seconds())


async def describe(store: SymbolLookup, symbols: Sequence[str]) -> list[StockInfo]:
    """Describe those symbols, in one call, for whoever asks from another module."""
    wanted = list(dict.fromkeys(symbols))

    if not wanted:
        return []

    return [
        StockInfo(
            symbol=row.symbol,
            name=row.name,
            currency=row.currency,
            is_listed=row.delisted_at is None,
        )
        for row in await store.find_many(wanted)
    ]


async def get_stocks(session: AsyncSession, symbols: Sequence[str]) -> list[StockInfo]:
    """Describe those symbols for whoever asks from another module."""
    return await describe(StockRepository(session), symbols)


# Shorter than this and no suggestion is worth showing, so the database is not asked.
MIN_QUERY_LENGTH = 2

# It is truncated to avoid a dropdown that is too long to be useful
SUGGESTION_LIMIT = 20

# A containment cap on the query, and a different number for a different reason.
CANDIDATE_LIMIT = 10_000


def _relevance(stock: Stock, folded: str) -> tuple[int, str]:
    """Which of the four groups a row falls in, and its place inside the group."""
    symbol = stock.symbol.casefold()

    if symbol == folded:
        group = 0
    elif symbol.startswith(folded):
        group = 1
    elif stock.name.casefold().startswith(folded):
        group = 2
    else:
        group = 3

    return group, stock.symbol


async def search_stocks(store: CatalogueStore, text: str) -> list[StockInfo]:
    """The suggestions for what somebody typed: at most twenty, most relevant first."""
    needle = text.strip()

    if len(needle) < MIN_QUERY_LENGTH:
        return []

    candidates = await store.search_listed(needle, CANDIDATE_LIMIT)

    if len(candidates) == CANDIDATE_LIMIT:
        # The cap was reached, so the ranking is no longer trustworthy: the rows that did not
        # come back were chosen by nothing in particular. A tope that ages in silence is a
        # dropdown that quietly stops finding things, so it leaves a trace instead.
        await log.awarning("stock_search_truncated", limit=CANDIDATE_LIMIT)

    folded = needle.casefold()
    ranked = sorted(candidates, key=lambda stock: _relevance(stock, folded))

    return [
        StockInfo(
            symbol=stock.symbol,
            name=stock.name,
            currency=stock.currency,
            is_listed=stock.delisted_at is None,
        )
        for stock in ranked[:SUGGESTION_LIMIT]
    ]
