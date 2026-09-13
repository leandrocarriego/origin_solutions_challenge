"""The catalogue: what is worth ingesting, and how a snapshot becomes the table (ADR-002)."""

import re
from dataclasses import dataclass
from datetime import UTC, datetime

from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.stocks.repository import mark_absent_as_delisted, upsert
from app.providers import MarketDataProvider, StockRecord

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
