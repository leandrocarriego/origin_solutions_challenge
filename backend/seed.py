"""Loads the minimum dataset needed to exercise the application.

Without it there is nothing to develop against, and whoever clones the repository has no way in.

It runs from the container entrypoint when SEED_ON_START is true, which only the local compose
sets. It is never a default, and it refuses outright when the environment says production: the
passwords it writes live in this repository, so a seeded production database is a production
database with known credentials. Two mistakes rather than one.

Idempotent by construction. It runs on every `make up`, and a seed that fails the second time is
a seed nobody runs.

Like `alembic/env.py`, this reaches into the modules: it is a composition root, for the data
rather than for the schema or the routes.
"""

import asyncio
import sys
from dataclasses import dataclass
from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import SessionFactory
from app.modules.auth.models import User
from app.modules.favorites.models import UserStock
from app.modules.stocks.models import Stock
from app.security import hash_password
from app.settings import get_settings


class SeedRefused(Exception):
    """The seed declined to run, and the message says why."""


@dataclass(frozen=True, slots=True)
class DemoUser:
    """One of the accounts the README hands to whoever evaluates the project."""

    username: str
    full_name: str
    password: str


# Two, because one user cannot demonstrate that favourites are per user.
#
# The passwords are here in the open on purpose: they are demo credentials, the README hands
# them to whoever evaluates the project, and the seed refuses to run in production precisely
# because of them. That is what `noqa: S106` is saying, and it is the only place it is said.
DEMO_USERS = (
    DemoUser(username="juan", full_name="Juan Perez", password="origin-demo-juan"),  # noqa: S106
    DemoUser(username="ana", full_name="Ana Gomez", password="origin-demo-ana"),  # noqa: S106
)

# The three of the brief's own grid, so its screen is reproducible on the first run.
DEMO_FAVOURITES = ("TSLA", "AAPL", "NFLX")

# The favourites reference the catalogue, so the catalogue has to hold them. The ingestion
# refreshes these rows the first time it runs; until then this is what makes the demo work
# without spending a request of the quota.
DEMO_CATALOGUE = (
    ("TSLA", "Tesla, Inc.", "XNGS"),
    ("AAPL", "Apple Inc.", "XNGS"),
    ("NFLX", "Netflix Inc.", "XNGS"),
)


def refuses_to_run() -> str | None:
    """The reason the seed must not run here, or None when it may."""
    if get_settings().environment == "production":
        return "the environment is production, and these passwords are in the repository"

    return None


async def seed(session: AsyncSession) -> None:
    """Write the demo dataset, or raise if this is not a place for it.

    The refusal comes first, before a single row: refusing after inserting the users would be
    the worst of both.
    """
    refusal = refuses_to_run()
    if refusal is not None:
        raise SeedRefused(refusal)

    await _seed_catalogue(session)
    await _seed_users(session)
    await _seed_favourites(session)
    await session.commit()


async def _seed_catalogue(session: AsyncSession) -> None:
    """The three symbols the demo favourites point at."""
    rows = [
        {
            "symbol": symbol,
            "name": name,
            "currency": "USD",
            "exchange": "NASDAQ",
            "mic_code": mic,
            "country": "United States",
            "type": "Common Stock",
            "last_seen_at": datetime.now(UTC),
        }
        for symbol, name, mic in DEMO_CATALOGUE
    ]

    await session.execute(insert(Stock).values(rows).on_conflict_do_nothing())


async def _seed_users(session: AsyncSession) -> None:
    """The demo accounts, with their passwords hashed.

    `on_conflict_do_nothing` and not an update: rehashing on every start would change the stored
    hash for no reason, and a seed is not where a password gets rotated.
    """
    rows = [
        {
            "username": user.username,
            "full_name": user.full_name,
            "password_hash": hash_password(user.password),
        }
        for user in DEMO_USERS
    ]

    await session.execute(
        insert(User).values(rows).on_conflict_do_nothing(index_elements=[User.username])
    )


async def _seed_favourites(session: AsyncSession) -> None:
    """The grid of the wireframe, for the first demo user."""
    owner = await session.scalar(select(User.id).where(User.username == DEMO_USERS[0].username))
    if owner is None:
        raise SeedRefused("the demo user was not created, so its favourites have no owner")

    rows = [{"user_id": owner, "symbol": symbol} for symbol in DEMO_FAVOURITES]
    await session.execute(insert(UserStock).values(rows).on_conflict_do_nothing())


async def main() -> int:
    """Run the seed against the configured database, reporting what happened."""
    refusal = refuses_to_run()
    if refusal is not None:
        print(f"seed: no corre porque {refusal}")
        return 0

    async with SessionFactory() as session:
        await seed(session)

    print("seed: listo")
    return 0


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
