"""Data access for the favourites. The only layer here that writes SQL."""

from collections.abc import Sequence
from typing import Any, cast

from sqlalchemy import CursorResult, delete, exists, select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.favorites.models import UserStock


async def symbols_of(session: AsyncSession, user_id: int) -> list[str]:
    """The symbols that user follows, most recently added first.

    `user_id` is the first argument and there is no way to call this without one: a query that
    could be asked without it is an IDOR waiting for somebody to forget.

    The tie-break by symbol is not decoration. The seed inserts three favourites in one
    statement, so `now()` is the same for all of them, and without a second criterion the grid
    would reshuffle between two reloads -- an order that is merely usually right.
    """
    rows: Sequence[str] = (
        await session.scalars(
            select(UserStock.symbol)
            .where(UserStock.user_id == user_id)
            .order_by(UserStock.added_at.desc(), UserStock.symbol.asc())
        )
    ).all()

    return list(rows)


async def add(session: AsyncSession, user_id: int, symbol: str) -> bool:
    """Make that user follow that symbol, and say whether this call is what created the row.

    `ON CONFLICT DO NOTHING` over the composite primary key is what makes the add idempotent by
    construction rather than by an `if`: the second request of a double click cannot write a
    second row even while the first one is still being served, which is where a read-then-write
    would have a gap.

    The boolean is the decision the service needs and the router turns into 201 or 200. Returning
    a status from here would be this layer talking about HTTP; returning nothing would lose the
    one fact the screen reacts to.
    """
    inserted = cast(
        "CursorResult[Any]",
        await session.execute(
            insert(UserStock)
            .values(user_id=user_id, symbol=symbol)
            .on_conflict_do_nothing(index_elements=[UserStock.user_id, UserStock.symbol])
        ),
    )
    await session.commit()

    return inserted.rowcount == 1


async def remove(session: AsyncSession, user_id: int, symbol: str) -> None:
    """Stop that user following that symbol, if they were.

    The `user_id` is in the `WHERE` and there is no way to call this without one: the delete of
    one user cannot reach the row of another, and no extra check is needed to make that true.

    It says nothing about how many rows it touched, because nobody may act on that: removing
    something that was not there is the same answer as removing something that was.
    """
    await session.execute(
        delete(UserStock).where(UserStock.user_id == user_id, UserStock.symbol == symbol)
    )
    await session.commit()


async def follows(session: AsyncSession, user_id: int, symbol: str) -> bool:
    """Whether that user follows that symbol.

    `user_id` is the first argument and it is in the `WHERE`: there is no way to ask this
    question about somebody else's list, which is what makes it safe to answer a module that
    serves data costing quota.

    It asks for existence and not for the row: the caller asked a yes or no, and a row would be
    an invitation to read a column the answer does not include.
    """
    found = await session.scalar(
        select(exists().where(UserStock.user_id == user_id, UserStock.symbol == symbol))
    )

    return bool(found)
