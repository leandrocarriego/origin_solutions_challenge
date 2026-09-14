"""Data access for the quote cache. The only layer here that writes SQL."""

from collections.abc import Sequence
from datetime import datetime
from typing import Any, cast

from sqlalchemy import CursorResult, select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.quotes.models import Quote
from app.providers import QuotePoint


class QuoteRepository:
    """The rows of `quotes`, read and written through one session."""

    def __init__(self, session: AsyncSession) -> None:
        """Work through that session, which is the request's and not this object's to close."""
        self._session = session

    async def candles_in(
        self, symbol: str, interval: str, start: datetime, end: datetime
    ) -> list[Quote]:
        """The candles of that symbol and interval inside that window, oldest first."""
        rows: Sequence[Quote] = (
            await self._session.scalars(
                select(Quote)
                .where(
                    Quote.symbol == symbol,
                    Quote.interval == interval,
                    Quote.ts >= start,
                    Quote.ts <= end,
                )
                .order_by(Quote.ts.asc())
            )
        ).all()

        return list(rows)

    async def newest_ts(self, symbol: str, interval: str) -> datetime | None:
        """The instant of the newest candle stored for that pair, or nothing if there is none."""
        newest: datetime | None = await self._session.scalar(
            select(Quote.ts)
            .where(Quote.symbol == symbol, Quote.interval == interval)
            .order_by(Quote.ts.desc())
            .limit(1)
        )

        return newest

    async def save(self, symbol: str, interval: str, points: Sequence[QuotePoint]) -> int:
        """Upsert what the provider answered, and say how many rows the statement touched."""
        if not points:
            return 0

        statement = insert(Quote).values(
            [
                {
                    "symbol": symbol,
                    "interval": interval,
                    "ts": point.ts,
                    "open": point.open,
                    "high": point.high,
                    "low": point.low,
                    "close": point.close,
                    "volume": point.volume,
                }
                for point in points
            ]
        )

        written = cast(
            "CursorResult[Any]",
            await self._session.execute(
                statement.on_conflict_do_update(
                    index_elements=[Quote.symbol, Quote.interval, Quote.ts],
                    set_={
                        "open": statement.excluded.open,
                        "high": statement.excluded.high,
                        "low": statement.excluded.low,
                        "close": statement.excluded.close,
                        "volume": statement.excluded.volume,
                    },
                )
            ),
        )

        await self._session.commit()

        return written.rowcount
