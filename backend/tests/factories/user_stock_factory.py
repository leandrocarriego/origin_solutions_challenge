"""Factory of `user_stocks` rows, which is the only table `favorites` owns.

`added_at` is an argument and not a default on purpose: RF-06 orders the grid by it, and the
case that breaks the order -- two favourites inserted in the same statement, sharing the value
`now()` gave the whole transaction -- is only reachable if a test can hand the same instant
twice.

The catalogue row the foreign key needs is not written here: it is asked of `StockFactory`. A
factory that inserted another module's table by hand would be the same boundary violation as an
import, with the difference that the architecture test cannot see it.
"""

from datetime import UTC, datetime

from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.favorites.models import UserStock
from tests.factories.stock_factory import StockFactory

# The instant a favourite is added when the test does not care which. Fixed rather than `now()`
# so that two rows are ordered by what the test wrote, never by how fast it ran.
ADDED_AT = datetime(2026, 9, 13, 15, 0, tzinfo=UTC)


class UserStockFactory:
    """Rows of `user_stocks`: one symbol somebody follows."""

    @staticmethod
    async def create(
        session: AsyncSession,
        user_id: int,
        symbol: str = "TSLA",
        added_at: datetime = ADDED_AT,
        **stock_kwargs: object,
    ) -> UserStock:
        """Make that user follow that symbol, creating the catalogue row if it is missing.

        The composite key is `(user_id, symbol)` and there is no surrogate id, so both halves
        are arguments: a batch that did not vary them would insert the same row twice, which is
        exactly what the key exists to refuse.
        """
        await StockFactory.ensure(session, symbol, **stock_kwargs)

        favourite = UserStock(user_id=user_id, symbol=symbol, added_at=added_at)
        session.add(favourite)
        await session.flush()

        return favourite
