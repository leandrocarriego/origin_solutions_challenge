"""Data access for `auth`. The only layer of the module that writes SQL (PY-06)."""

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.auth.models import User


async def find_by_username(session: AsyncSession, username: str) -> User | None:
    """The user who answers to that name, matched without regard to case (RF-14).

    It receives the name already lowercased and compares with `func.lower`, because the column is
    not case-insensitive and its unique index is on the value as written: somebody whose phone
    capitalised the first letter would otherwise be a different user, one that does not exist.

    That comparison does not use the index, and here that is fine: the table holds two rows and
    its only writer is the seed, which writes lower case. The day there is sign-up, the
    normalisation moves to the write (`plan.md` -> Datos).
    """
    found = await session.execute(select(User).where(func.lower(User.username) == username))

    return found.scalars().first()
