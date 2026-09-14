"""The catalogue: what is worth ingesting, and how a snapshot becomes the table."""

import asyncio
import re
from collections.abc import Sequence
from datetime import UTC, datetime, timedelta

import structlog
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import SessionFactory
from app.modules.stocks.models import Stock
from app.modules.stocks.repository import (
    find_many,
    last_seen,
    mark_absent_as_delisted,
    search_listed,
    upsert,
)
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

# How old the catalogue may get before it is refreshed. Two credits out of 800 buys a full
# refresh, so the window is about how stale a new listing may be, not about cost.
MAX_CATALOGUE_AGE = timedelta(hours=24)

# The symbol travels in the URL, and a slash in it is not a symbol, it is a route. Dots
# and dashes are legal inside a path segment, so they stay: dropping them would lose real
# companies (BRK.B, ABR-D).
ROUTABLE_SYMBOL = re.compile(r"^[A-Z0-9][A-Z0-9.\-]{0,8}$")

# The only type dropped. A warrant is a derivative, not a stock, and it is the only thing that
# duplicates a symbol in the catalogue -- which is what makes the natural key true.
# Narrower than Common-Stock-only on purpose: that would have thrown away 393 ADRs and 214 REITs
# that collide with nothing and that somebody may search for.
DERIVATIVE = "Warrant"


def is_worth_ingesting(record: StockRecord) -> bool:
    """Whether a catalogue entry may become a row of `stocks`."""
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


async def is_catalogue_stale(
    session: AsyncSession, older_than: timedelta, exchange: str | None = None
) -> bool:
    """Whether the catalogue is old enough to be worth spending a request on.

    Per market when one is named, and "any of them" otherwise. That distinction is not
    cosmetic: each exchange is its own snapshot, so asking the table as a whole lets a
    successful NYSE make a failed NASDAQ look fresh -- and the failed one is then not retried
    for a day. That is what happened on the first real ingestion.

    A market nobody ever ingested is stale: an empty table is not fresh, it is unknown.
    """
    markets = (exchange,) if exchange is not None else CATALOGUE_EXCHANGES
    now = datetime.now(UTC)

    for market in markets:
        seen = await last_seen(session, market)
        if seen is None or now - seen > older_than:
            return True

    return False


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
    stale = [
        exchange
        for exchange in CATALOGUE_EXCHANGES
        if await is_catalogue_stale(session, older_than=older_than, exchange=exchange)
    ]
    if not stale:
        await log.adebug("catalogue_refresh_skipped", reason="every market is fresh")
        return CatalogueRefresh(reconciled=(), failed=(), skipped=True)

    done: list[CatalogueReconciliation] = []
    failed: list[str] = []

    for exchange in stale:
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
    """Refresh the catalogue when it goes stale, for as long as the process lives.

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


async def get_stocks(session: AsyncSession, symbols: Sequence[str]) -> list[StockInfo]:
    """Describe those symbols, in one call, for whoever asks from another module.

    Three properties of the contract, all of them deliberate:

    - **It is a set.** Repeated symbols collapse and unknown ones are simply absent, so the
      length of the answer does not follow the length of the question. A symbol the catalogue
      does not have is not a failure here: `add_favorite` is the one that decides what that
      absence means.
    - **The order is not promised.** Whoever consumes it reorders -- `favorites` already has its
      own, `added_at DESC, symbol ASC` -- which is what lets the repository resolve the `IN` as
      it pleases.
    - **The symbols arrive in upper case.** This does not normalise: normalising already has an
      owner, `add_favorite`, and two places that normalise are two places that one day do it
      differently. The price is written down and fixed by a test -- lower case gets `[]` and no
      error.

    An empty list never reaches the database: `WHERE symbol IN ()` is a round trip whose result
    is known before writing it. "Is this query worth making" is a decision, and decisions live
    here and not in the repository.
    """
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
        for row in await find_many(session, wanted)
    ]


# Shorter than this and no suggestion is worth showing, so the database is not asked. The router
# imports it for its `Query(min_length=...)`, which is what keeps the number in one place.
MIN_QUERY_LENGTH = 2

# What fits in a dropdown. A product decision, applied **after** the ranking.
SUGGESTION_LIMIT = 20

# A containment cap on the query, and a different number for a different reason. It is chosen so
# that today it cannot cut: the catalogue is ~7.200 rows, so even a text matching all of it comes
# back whole and the ranking is exact by construction rather than by luck. A small cap would have
# looked prudent and reintroduced the bug in its hard-to-see form -- truncating only on the most
# common texts, by an order that has nothing to do with relevance.
CANDIDATE_LIMIT = 10_000


def _relevance(stock: Stock, folded: str) -> tuple[int, str]:
    """Which of the four groups a row falls in, and its place inside the group.

    Exact symbol, then symbol that starts with the text, then name that starts with it, then
    everything else that matched; `symbol ASC` inside each, which is what makes the answer the
    same on every call.

    **Both sides are folded, once.** The two columns are not in the same case -- the catalogue
    stores `MSFT` and `Microsoft Corp` -- so upper-casing the text would serve the symbol groups
    and silently kill the name one: `"Microsoft Corp"` does not start with `MICRO`. `casefold()`
    and not `lower()` because it is the operation Python defines for comparing without case, and
    the catalogue carries the issuer names of two markets.
    """
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


async def search_stocks(session: AsyncSession, text: str) -> list[StockInfo]:
    """The suggestions for what somebody typed: at most twenty, most relevant first.

    Three decisions live here and none of them is the repository's:

    - **`strip()`, once, on the way in**, and the stripped text is what travels down. Sending the
      raw text instead would search `ILIKE '%  micro  %'` while the ranking reasoned about
      `micro` -- the two halves of one search talking about two different texts.
    - **Shorter than `MIN_QUERY_LENGTH` after that, and the database is never asked.** `"  "`
      passes the router's `min_length` and would become `ILIKE '%%'`, which is the whole
      catalogue: exactly the cost the minimum exists to avoid. `[]` is a result, not a failure,
      and not a 422 either -- a service that raised for the transport to translate would be
      opining about HTTP.
    - **Rank first, cut second.** The repository brings candidates; cutting at twenty before the
      ranking existed would mean ranking a set the database already chose, and `MSFT` would not
      be in the answer for `micro`.

    Nothing is upper-cased and nothing is escaped on the way down: `ILIKE` handles case on its
    own, and escaping is the syntax of an operator this layer does not know about.
    """
    needle = text.strip()
    if len(needle) < MIN_QUERY_LENGTH:
        return []

    candidates = await search_listed(session, needle, CANDIDATE_LIMIT)
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
