"""Engine, session and declarative base. This is kernel: it imports no module (GEN-03)."""

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
    """Declarative base shared by every module.

    Tables belong to their module; this does not. It lives in the kernel because Alembic needs
    a single metadata to order a single chain of migrations.
    """


async def get_session() -> AsyncIterator[AsyncSession]:
    """Request-scoped session, injected by the router into the repository."""
    async with SessionFactory() as session:
        yield session


async def database_is_up() -> bool:
    """Whether the database answers a trivial query.

    This swallows the exception on purpose, and it is the one place where that is right: the
    caller asked a yes-or-no question, and the three ways it fails --server down, wrong
    credentials, host does not resolve-- are the same answer. The exception must not escape,
    because its text carries the DSN and the DSN carries the password (Article I).
    """
    try:
        async with engine.connect() as connection:
            await connection.execute(text("SELECT 1"))
    except Exception:  # noqa: BLE001 -- see the docstring: this is a probe, not a call
        return False
    return True


# What a router writes to receive the session: `session: SessionDep`.
#
# Spelling it out at the call site -- `Annotated[AsyncSession, Depends(get_session)]` -- would
# make the router import SQLAlchemy, and PY-06 forbids exactly that: the ORM belongs to the
# repository. The alias declares the type once, here, where the other half of it already lived,
# and the router names the ORM never. The fix is the alias, not an exception to the rule.
SessionDep = Annotated[AsyncSession, Depends(get_session)]
