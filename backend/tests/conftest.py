"""Shared fixtures.

TEST-03: the suite runs with no network and no API key. Anything that would reach outside is
replaced here -- never reached, and never a reason to skip a test.

Two variables are set before anything of `app` is imported, and that ordering is the whole point:
both are required fields of `Settings`, `Settings` is read while `app.main` is imported, so
without them every module that reaches `app` would fail at collection. `setdefault` and not an
assignment, so a run against a real environment keeps what it was given.

`MARKET_DATA_PROVIDER` is the upstream one because that is what the suite exercises: the real
parsing, against fixed JSON, through a transport that never opens a socket (`TEST-03`). Nothing
here reaches the network, and no test builds a provider from the environment without saying so.

The value is not a secret and does not pretend to be one: it says so, and it is long enough to
clear the floor and good for nothing else. It lives in the tests and never in `app/`, which is
the line `SEC-05` actually draws -- what must not exist is a default *the application ships
with*.
"""

import os

os.environ.setdefault("JWT_SECRET", "test-signing-secret-not-a-real-one")
os.environ.setdefault("MARKET_DATA_PROVIDER", "twelvedata")

from collections.abc import AsyncIterator, Iterator
from typing import Any

import pytest
import sentry_sdk
from sqlalchemy import text
from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

from app import observability
from app.settings import get_settings


@pytest.fixture
def database_is_reachable(monkeypatch: pytest.MonkeyPatch) -> Iterator[None]:
    """The database answers a trivial query.

    Health only needs to know whether the connection works, so what gets faked here is the
    probe, not the engine. A real engine against a real database is the job of the tests that
    exercise repositories.
    """

    async def _probe_succeeds() -> bool:
        return True

    monkeypatch.setattr("app.health.database_is_up", _probe_succeeds)
    yield


@pytest.fixture
def database_is_unreachable(monkeypatch: pytest.MonkeyPatch) -> Iterator[None]:
    """The database is down, or the credentials are wrong, or the host does not resolve.

    All three look the same from the endpoint's side and are reported the same way: degraded,
    and without saying anything about the connection string.
    """

    async def _probe_fails() -> bool:
        return False

    monkeypatch.setattr("app.health.database_is_up", _probe_fails)
    yield


SENTINEL_API_KEY = "sentinel-api-key-do-not-log"


@pytest.fixture
def sentinel_api_key(monkeypatch: pytest.MonkeyPatch) -> Iterator[str]:
    """A recognisable API key, so a leak is visible instead of plausible.

    A real-looking key would hide in the noise of a log line. This one cannot be confused with
    anything else, which is what makes the assertion meaningful.
    """
    get_settings.cache_clear()
    monkeypatch.setenv("MARKET_DATA_API_KEY", SENTINEL_API_KEY)
    yield SENTINEL_API_KEY
    get_settings.cache_clear()


@pytest.fixture
def captured_logs(monkeypatch: pytest.MonkeyPatch) -> Iterator[list[str]]:
    """Every line the application logs during the test, as raw strings.

    Raw and not parsed on purpose: whether the line is valid JSON is one of the things under
    test, so parsing it here would hide the failure it exists to catch.
    """
    written: list[str] = []

    class _Collector:
        """A file-like sink that keeps what was written instead of printing it."""

        def write(self, message: str) -> int:
            """Record one line, ignoring the blank ones the logger emits between records."""
            stripped = message.strip()
            if stripped:
                written.append(stripped)
            return len(message)

        def flush(self) -> None:
            """Nothing is buffered, so there is nothing to flush."""
            return None

    observability.configure_logging(stream=_Collector())
    yield written
    observability.configure_logging()


@pytest.fixture
def sentry_configured(monkeypatch: pytest.MonkeyPatch) -> Iterator[Any]:
    """Initialise Sentry against a fake DSN and hand back the resulting client."""
    get_settings.cache_clear()
    monkeypatch.setenv("SENTRY_DSN", "https://public@o0.ingest.sentry.io/0")

    observability.configure_sentry()
    yield sentry_sdk.get_client()

    sentry_sdk.init(dsn=None)
    get_settings.cache_clear()


@pytest.fixture
async def session() -> AsyncIterator[AsyncSession]:
    """A session against the real database, inside a transaction that is always rolled back.

    Integration tests run against Postgres and not against a double (TEST-02), so they need the
    schema that `alembic upgrade head` creates. What they must not need is cleanup, and they
    must not need an empty database either: a developer who ran `make up` has the seed's rows in
    there, and a test that only passes on a pristine database fails later for a reason that
    looks nothing like the cause.

    So the transaction starts by emptying the four tables and ends by rolling back. TRUNCATE is
    transactional in Postgres, so the developer's data is untouched: every test sees a known
    state, and the order they run in cannot change what they see.
    """
    engine = create_async_engine(get_settings().database_url)

    async with engine.connect() as connection:
        transaction = await connection.begin()
        await connection.execute(
            text("TRUNCATE users, stocks, user_stocks, quotes RESTART IDENTITY CASCADE")
        )
        factory = async_sessionmaker(
            bind=connection, expire_on_commit=False, join_transaction_mode="create_savepoint"
        )

        async with factory() as opened:
            yield opened

        await transaction.rollback()

    await engine.dispose()
