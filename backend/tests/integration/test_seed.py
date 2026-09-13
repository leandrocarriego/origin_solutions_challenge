"""The demo data, which the brief asks for by name (REQ-19).

*"insertar una cantidad minima de datos para poder probar la aplicacion"* is why the seed is in
phase 0 and not at the end: without it there is nothing to develop against, and the evaluator
who clones the repository has no way in.

It runs on every `make up`, so running it twice has to be running it once. And it refuses to run
in production, because the passwords it writes are in the repository.
"""

import pytest
from app.security import verify_password
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.auth.models import User
from app.modules.favorites.models import UserStock
from app.modules.stocks.models import Stock
from app.settings import get_settings
from seed import DEMO_FAVOURITES, DEMO_USERS, SeedRefused, seed


async def count_of(session: AsyncSession, model: type[User] | type[UserStock] | type[Stock]) -> int:
    """How many rows the table holds right now."""
    return (await session.scalar(select(func.count()).select_from(model))) or 0


class TestItCreatesWhatTheBriefAsksFor:
    """Two users and their favourites, which is what "minimum data to try it" means here."""

    async def test_it_creates_the_demo_users(self, session: AsyncSession) -> None:
        """The README hands these credentials to whoever evaluates the project."""
        await seed(session)

        usernames = set((await session.scalars(select(User.username))).all())
        assert usernames == {user.username for user in DEMO_USERS}

    async def test_every_demo_password_is_hashed(self, session: AsyncSession) -> None:
        """SEC-06 applies to the seed first, because the seed writes the first row."""
        await seed(session)

        stored = (await session.scalars(select(User))).all()
        assert all(user.password_hash.startswith("$argon2id$") for user in stored)

    async def test_the_demo_passwords_actually_work(self, session: AsyncSession) -> None:
        """Credentials in a README that do not log in are worse than no credentials."""
        await seed(session)

        first = DEMO_USERS[0]
        stored = await session.scalar(select(User).where(User.username == first.username))
        assert stored is not None
        assert verify_password(first.password, stored.password_hash)

    async def test_it_creates_the_favourites_of_the_wireframe(self, session: AsyncSession) -> None:
        """TSLA, AAPL and NFLX: the grid of the brief's own screen, reproducible on first run."""
        await seed(session)

        assert set(DEMO_FAVOURITES) == {"TSLA", "AAPL", "NFLX"}
        symbols = set((await session.scalars(select(UserStock.symbol))).all())
        assert {"TSLA", "AAPL", "NFLX"} <= symbols

    async def test_the_favourites_point_at_symbols_that_exist(self, session: AsyncSession) -> None:
        """A favourite whose symbol is not in the catalogue is a foreign key waiting to fire."""
        await seed(session)

        catalogue = set((await session.scalars(select(Stock.symbol))).all())
        favourites = set((await session.scalars(select(UserStock.symbol))).all())
        assert favourites <= catalogue


class TestItIsSafeToRunAgain:
    """`make up` runs it on every start, so a second run cannot fail or duplicate."""

    async def test_running_it_twice_does_not_fail(self, session: AsyncSession) -> None:
        """A unique violation on the second `make up` is a broken development loop."""
        await seed(session)

        await seed(session)

    async def test_running_it_twice_leaves_the_same_rows(self, session: AsyncSession) -> None:
        """Idempotent means the same state, not merely no exception."""
        await seed(session)
        before = (await count_of(session, User), await count_of(session, UserStock))

        await seed(session)

        assert (await count_of(session, User), await count_of(session, UserStock)) == before


class TestItRefusesWhereItDoesNotBelong:
    """The passwords it writes are in the repository, so production is not a place for it."""

    async def test_it_refuses_to_run_in_production(
        self, session: AsyncSession, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """Two mistakes rather than one: SEC_ON_START is absent there and this refuses anyway."""
        get_settings.cache_clear()
        monkeypatch.setenv("SENTRY_ENVIRONMENT", "production")

        with pytest.raises(SeedRefused):
            await seed(session)

        get_settings.cache_clear()

    async def test_it_writes_nothing_when_it_refuses(
        self, session: AsyncSession, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """Refusing after inserting the users would be the worst of both."""
        get_settings.cache_clear()
        monkeypatch.setenv("SENTRY_ENVIRONMENT", "production")

        with pytest.raises(SeedRefused):
            await seed(session)

        get_settings.cache_clear()
        assert await count_of(session, User) == 0
