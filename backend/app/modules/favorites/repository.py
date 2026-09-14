"""Data access for the favourites. The only layer here that writes SQL."""

from collections.abc import Sequence
from typing import Any, cast

from sqlalchemy import CursorResult, delete, exists, select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.favorites.models import UserStock


class FavoritesRepository:
    """The favourites of `user_stocks`, read and written through one session."""

    def __init__(self, session: AsyncSession) -> None:
        """Work through that session, which is the request's and not this object's to close."""
        self._session = session

    async def symbols_of(self, user_id: int) -> list[str]:
        """The symbols that user follows, most recently added first."""
        rows: Sequence[str] = (
            await self._session.scalars(
                select(UserStock.symbol)
                .where(UserStock.user_id == user_id)
                .order_by(UserStock.added_at.desc(), UserStock.symbol.asc())
            )
        ).all()

        return list(rows)

    async def add(self, user_id: int, symbol: str) -> bool:
        """
        Make that user follow that symbol, and say whether this call is what created the row.

        `ON CONFLICT DO NOTHING` over the composite primary key is what makes the add idempotent
        by construction.
        """
        inserted = cast(
            "CursorResult[Any]",
            await self._session.execute(
                insert(UserStock)
                .values(user_id=user_id, symbol=symbol)
                .on_conflict_do_nothing(index_elements=[UserStock.user_id, UserStock.symbol])
            ),
        )
        await self._session.commit()

        return inserted.rowcount == 1

    async def remove(self, user_id: int, symbol: str) -> None:
        """Stop that user following that symbol, if they were."""
        await self._session.execute(
            delete(UserStock).where(UserStock.user_id == user_id, UserStock.symbol == symbol)
        )
        await self._session.commit()

    async def follows(self, user_id: int, symbol: str) -> bool:
        """Whether that user follows that symbol."""
        found = await self._session.scalar(
            select(exists().where(UserStock.user_id == user_id, UserStock.symbol == symbol))
        )

        return bool(found)
