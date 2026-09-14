"""Data access for the catalogue. The only layer here that writes SQL."""

from collections.abc import Sequence
from datetime import datetime
from typing import Any, cast

from sqlalchemy import CursorResult, func, or_, select, update
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.stocks.models import Stock
from app.providers import StockRecord

# Postgres carries at most 32767 bind parameters in one statement, and a row here is nine of
# them. The real catalogue is 7.155 rows, so "insert them all at once" is 64.395 parameters and
# asyncpg refuses before the server ever sees it -- which is exactly what the first real
# ingestion hit in production.
_ROWS_PER_STATEMENT = 1_000


async def upsert(session: AsyncSession, records: list[StockRecord], seen_at: datetime) -> None:
    """Insert what is new and refresh what is already there.

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

    for start in range(0, len(rows), _ROWS_PER_STATEMENT):
        statement = insert(Stock).values(rows[start : start + _ROWS_PER_STATEMENT])
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


async def last_seen(session: AsyncSession, exchange: str) -> datetime | None:
    """When that market was last refreshed, or None if it never was.

    Per market and not over the whole table. Each exchange is its own snapshot: one of them
    succeeding says nothing about the other, and asking the table as a whole would let a
    successful NYSE make a failed NASDAQ look fresh for a day.

    None is not "old", it is "unknown", and on first boot that difference is what tells an empty
    database from a stale one.
    """
    seen: datetime | None = await session.scalar(
        select(func.max(Stock.last_seen_at)).where(Stock.exchange == exchange)
    )

    return seen


async def find_many(session: AsyncSession, symbols: Sequence[str]) -> list[Stock]:
    """The catalogue rows for those symbols, in whatever order the database returns them.

    One statement for the whole batch: the grid of N favourites is one question and not N.
    Ordering is left to the caller on purpose -- an `IN` promises nothing about the sequence of
    its rows, and an `ORDER BY` nobody asked for is a guarantee somebody starts depending on.
    """
    rows = await session.scalars(select(Stock).where(Stock.symbol.in_(symbols)))

    return list(rows.all())


def _escape_like(text: str) -> str:
    """Turn a text the person typed into something that means itself inside an `ILIKE`.

    `%` and `_` are operators there -- "anything" and "any one character" -- so leaving them be
    hands the query to whoever types in the box: `"%a"` would match everything with an `a` in it,
    and `"a_c"` would match `abc`. Neither is injection (the text is bound, never concatenated);
    what it is, is a dropdown answering things the person cannot explain, and a wide scan that
    the two-character minimum does not stop because two characters were supposed to narrow it.

    **The backslash goes first.** Escaping it after `%` would escape the backslashes this
    function just added, and the pattern would end up looking for slashes nobody typed. That is
    the classic bug of this function, and the reason the order is written down.
    """
    return text.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")


async def search_listed(session: AsyncSession, text: str, limit: int) -> list[Stock]:
    r"""Catalogue rows still trading whose symbol or name contains that text.

    `text` arrives stripped and never empty -- the service already decided that -- and arrives
    unescaped, because building the pattern is this layer's job: `%` only means anything because
    *this* function chose `ILIKE`, and the day the query becomes `similarity()` the escaping does
    not become unnecessary, it becomes wrong.

    `ILIKE` is case-insensitive on its own, so nothing is upper-cased here. `ESCAPE '\'`
    is declared rather than left to the default: it makes visible that the pattern has syntax,
    and `pg_trgm` parses the pattern assuming that very character -- another one would leave the
    index reading something Postgres does not evaluate, and that can only lose rows.

    `limit` is a **containment cap on candidates**, not the number of suggestions: ranking by
    relevance and cutting at twenty are decisions, and they belong to the service.
    Reading `search_listed(..., limit=20)` anywhere is a bug, not a shortcut.
    """
    pattern = f"%{_escape_like(text)}%"

    rows = await session.scalars(
        select(Stock)
        .where(
            Stock.delisted_at.is_(None),
            or_(
                Stock.symbol.ilike(pattern, escape="\\"),
                Stock.name.ilike(pattern, escape="\\"),
            ),
        )
        .limit(limit)
    )

    return list(rows.all())
