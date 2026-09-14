"""Factory of `quotes` rows, which is the only table `quotes` owns.

The composite primary key is `(symbol, interval, ts)` and there is no surrogate id, so the three
halves are arguments: a series built without varying `ts` inserts the same row twice, which is
exactly what the key exists to refuse -- and what makes the cache a cache (ADR-001).

The catalogue row the foreign key needs is not written here: it is asked of `StockFactory`. A
factory that inserted another module's table by hand would be the same boundary violation as an
import, with the difference that the architecture test cannot see it.
"""

from datetime import UTC, datetime, timedelta
from decimal import Decimal

from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.quotes.models import Quote
from tests.factories.stock_factory import StockFactory

# How long each interval lasts, which is both the spacing of a series and the TTL of ADR-003.
STEP = {
    "1min": timedelta(minutes=1),
    "5min": timedelta(minutes=5),
    "15min": timedelta(minutes=15),
}

# A fixed instant instead of `now()`: a test that reads differently depending on the clock is a
# test that fails at midnight. The tests that care about "today" pass their own.
CAPTURED_AT = datetime(2026, 9, 11, 19, 59, tzinfo=UTC)

CLOSE = Decimal("365.47")


class QuoteFactory:
    """Rows of `quotes`: one candle of one symbol at one interval."""

    @staticmethod
    async def create(
        session: AsyncSession,
        symbol: str = "TSLA",
        interval: str = "1min",
        ts: datetime = CAPTURED_AT,
        close: Decimal = CLOSE,
    ) -> Quote:
        """Insert one candle, creating the catalogue row the foreign key needs if it is missing.

        The other three prices are derived from the close: no test so far asserts on them, and
        deriving them keeps a row from carrying numbers that mean nothing.
        """
        await StockFactory.ensure(session, symbol)

        candle = Quote(
            symbol=symbol,
            interval=interval,
            ts=ts,
            open_price=close - Decimal("0.5"),
            high_price=close + Decimal("0.75"),
            low_price=close - Decimal("0.75"),
            close_price=close,
            volume=100_000,
        )
        session.add(candle)
        await session.flush()

        return candle

    @staticmethod
    async def create_series(
        session: AsyncSession,
        symbol: str = "TSLA",
        interval: str = "1min",
        first_ts: datetime = CAPTURED_AT,
        count: int = 5,
    ) -> list[Quote]:
        """Insert `count` consecutive candles, spaced by the interval, oldest first."""
        step = STEP[interval]

        return [
            await QuoteFactory.create(
                session,
                symbol=symbol,
                interval=interval,
                ts=first_ts + step * position,
                close=CLOSE + Decimal(position),
            )
            for position in range(count)
        ]
