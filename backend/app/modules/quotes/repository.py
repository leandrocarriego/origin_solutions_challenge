"""Data access for the quote cache. The only layer here that writes SQL (PY-06).

Data and never decisions: which window to read, whether what it holds is still current and what
to do when it is not are the service's business. What this answers is what is stored.
"""

from collections.abc import Sequence
from datetime import datetime
from typing import Any, cast

from sqlalchemy import CursorResult, select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.quotes.models import Quote
from app.providers import QuotePoint


async def candles_in(
    session: AsyncSession, symbol: str, interval: str, start: datetime, end: datetime
) -> list[Quote]:
    """The candles of that symbol and interval inside that window, oldest first.

    Ascending because a chart is read forwards, and bounded at both ends because RF-16 is about
    the window the user asked for: a query that answered everything stored for the symbol looks
    right on a fresh database and wrong on a full one.
    """
    rows: Sequence[Quote] = (
        await session.scalars(
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


async def newest_ts(session: AsyncSession, symbol: str, interval: str) -> datetime | None:
    """The instant of the newest candle stored for that pair, or nothing if there is none.

    It is how the service finds the last session there was when today has nothing (RF-27), and
    it is unbounded on purpose: the question is what the cache knows, not what a window holds.
    """
    newest: datetime | None = await session.scalar(
        select(Quote.ts)
        .where(Quote.symbol == symbol, Quote.interval == interval)
        .order_by(Quote.ts.desc())
        .limit(1)
    )

    return newest


async def save(
    session: AsyncSession, symbol: str, interval: str, points: Sequence[QuotePoint]
) -> int:
    """Upsert what the provider answered, and say how many rows the statement touched.

    `ON CONFLICT DO UPDATE` and not `DO NOTHING`, which is the one place the difference is a
    wrong price rather than a wasted write: at 10:05:30 the 10:05 candle is still forming, so
    the same instant arrives twice with two different closes. `DO NOTHING` would keep the
    half-made one for good, wearing the face of a final price that nothing ever corrects.
    """
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
        await session.execute(
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
    await session.commit()

    return written.rowcount
