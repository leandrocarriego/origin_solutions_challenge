"""Engine, session and declarative base."""

from collections.abc import AsyncIterator
from typing import Annotated

from fastapi import Depends
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from app.settings import get_settings

engine = create_async_engine(get_settings().database_url, pool_pre_ping=True)

SessionFactory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


class Base(DeclarativeBase):
    """Declarative base shared by every module."""


async def get_session() -> AsyncIterator[AsyncSession]:
    """Request-scoped session, injected by the router into the repository."""
    async with SessionFactory() as session:
        yield session


async def database_is_up() -> bool:
    """Whether the database answers a trivial query."""
    try:
        async with engine.connect() as connection:
            await connection.execute(text("SELECT 1"))

    except Exception:  # noqa: BLE001 -- a probe answers yes or no, and its text carries the DSN
        return False

    return True


SessionDep = Annotated[AsyncSession, Depends(get_session)]
