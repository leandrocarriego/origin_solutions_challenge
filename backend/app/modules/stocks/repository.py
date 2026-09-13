"""Data access for the catalogue. The only layer here that writes SQL (PY-06)."""

from datetime import datetime
from typing import Any, cast

from sqlalchemy import CursorResult, func, select, update
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.stocks.models import Stock
from app.providers import StockRecord


async def upsert(session: AsyncSession, records: list[StockRecord], seen_at: datetime) -> None:
    """Insert what is new and refresh what is already there, in one statement.

    `delisted_at` is cleared on conflict on purpose: a symbol that comes back is as real as one
    that goes away, and leaving the mark would hide it from the autocomplete forever.
    """
    if not records:
        return

    rows = [
        {
            "symbol": record.symbol,
            "name": record.name,
            "currency": record.currency,
            "exchange": record.exchange,
            "mic_code": record.mic_code,
            "country": record.country,
            "type": record.instrument_type,
            "last_seen_at": seen_at,
            "delisted_at": None,
        }
        for record in records
    ]

    statement = insert(Stock).values(rows)
    await session.execute(
        statement.on_conflict_do_update(
            index_elements=[Stock.symbol],
            set_={
                "name": statement.excluded.name,
                "currency": statement.excluded.currency,
                "exchange": statement.excluded.exchange,
                "mic_code": statement.excluded.mic_code,
                "country": statement.excluded.country,
                "type": statement.excluded.type,
                "last_seen_at": statement.excluded.last_seen_at,
                "delisted_at": None,
            },
        )
    )


async def mark_absent_as_delisted(
    session: AsyncSession, exchange: str, still_listed: set[str], at: datetime
) -> int:
    """Mark every symbol of that market that the snapshot no longer carries.

    Scoped to one exchange, because a snapshot of NYSE says nothing about NASDAQ. And it never
    deletes: `user_stocks` and `quotes` reference these rows.
    """
    condition = Stock.symbol.notin_(still_listed) if still_listed else Stock.symbol.is_not(None)

    result = cast(
        "CursorResult[Any]",
        await session.execute(
            update(Stock)
            .where(Stock.exchange == exchange, condition, Stock.delisted_at.is_(None))
            .values(delisted_at=at)
        ),
    )

    return result.rowcount


async def listed_symbols(session: AsyncSession, exchange: str) -> set[str]:
    """The symbols of a market that the catalogue currently considers listed."""
    rows = await session.scalars(
        select(Stock.symbol).where(Stock.exchange == exchange, Stock.delisted_at.is_(None))
    )

    return set(rows.all())


async def last_seen(session: AsyncSession) -> datetime | None:
    """When the catalogue was last refreshed, or None if it never was.

    None is not "old", it is "unknown", and on first boot that difference is what tells an empty
    database from a stale one.
    """
    return await session.scalar(select(func.max(Stock.last_seen_at)))
