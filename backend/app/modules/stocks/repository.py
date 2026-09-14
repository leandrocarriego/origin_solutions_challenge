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
# asyncpg refuses before the server ever sees it.
_ROWS_PER_STATEMENT = 1_000


def _escape_like(text: str) -> str:
    """Turn a text the person typed into something that means itself inside an `ILIKE`."""
    return text.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")


class StockRepository:
    """The rows of `stocks`, read and written through one session."""

    def __init__(self, session: AsyncSession) -> None:
        """Work through that session, which is the request's and not this object's to close."""
        self._session = session

    async def commit(self) -> None:
        """Make permanent what the reconciliation wrote, once both halves are done."""
        await self._session.commit()

    async def upsert(self, records: list[StockRecord], seen_at: datetime) -> None:
        """Insert what is new and refresh what is already there."""
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
            await self._session.execute(
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
        self, exchange: str, still_listed: set[str], at: datetime
    ) -> int:
        """Mark every symbol of that market that the snapshot no longer carries."""
        condition = Stock.symbol.notin_(still_listed) if still_listed else Stock.symbol.is_not(None)

        result = cast(
            "CursorResult[Any]",
            await self._session.execute(
                update(Stock)
                .where(Stock.exchange == exchange, condition, Stock.delisted_at.is_(None))
                .values(delisted_at=at)
            ),
        )

        return result.rowcount

    async def listed_symbols(self, exchange: str) -> set[str]:
        """The symbols of a market that the catalogue currently considers listed."""
        rows = await self._session.scalars(
            select(Stock.symbol).where(Stock.exchange == exchange, Stock.delisted_at.is_(None))
        )

        return set(rows.all())

    async def last_seen(self, exchange: str) -> datetime | None:
        """When that market was last refreshed, or None if it never was."""
        seen: datetime | None = await self._session.scalar(
            select(func.max(Stock.last_seen_at)).where(Stock.exchange == exchange)
        )

        return seen

    async def find_many(self, symbols: Sequence[str]) -> list[Stock]:
        """The catalogue rows for those symbols, in whatever order the database returns them."""
        rows = await self._session.scalars(select(Stock).where(Stock.symbol.in_(symbols)))

        return list(rows.all())

    async def search_listed(self, text: str, limit: int) -> list[Stock]:
        """Catalogue rows still trading whose symbol or name contains that text."""
        pattern = f"%{_escape_like(text)}%"

        rows = await self._session.scalars(
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
