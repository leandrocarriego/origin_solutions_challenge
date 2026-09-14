"""Data access for `auth`. The only layer of the module that writes SQL."""

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.auth.models import User


async def find_by_username(session: AsyncSession, username: str) -> User | None:
    """The user who answers to that name, matched without regard to case."""
    found = await session.execute(select(User).where(func.lower(User.username) == username))

    return found.scalars().first()
