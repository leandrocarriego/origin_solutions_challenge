"""Data access for `auth`. The only layer of the module that writes SQL."""

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.auth.models import User


class UserRepository:
    """The rows of `users`, read through one session."""

    def __init__(self, session: AsyncSession) -> None:
        """Work through that session, which is the request's and not this object's to close."""
        self._session = session

    async def find_by_username(self, username: str) -> User | None:
        """The user who answers to that name, matched without regard to case."""
        found = await self._session.execute(
            select(User).where(func.lower(User.username) == username)
        )

        return found.scalars().first()
