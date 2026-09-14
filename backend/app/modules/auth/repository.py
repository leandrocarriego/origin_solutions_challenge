"""Data access for `auth`. The only layer of the module that writes SQL."""

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.auth.models import User


async def find_by_username(session: AsyncSession, username: str) -> User | None:
    """The user who answers to that name, matched without regard to case.

    It receives the name already lowercased and compares with `func.lower`, because the unique
    index is on the value as written: somebody whose phone capitalised the first letter would
    otherwise be a user that does not exist.

    The comparison does not use the index, and here that is fine: the table holds two rows and
    its only writer is the seed. The day there is sign-up, the normalisation moves to the write.
    """
    found = await session.execute(select(User).where(func.lower(User.username) == username))

    return found.scalars().first()
