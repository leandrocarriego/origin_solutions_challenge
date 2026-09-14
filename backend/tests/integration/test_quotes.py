"""GET /api/quotes/{symbol}: the series the chart is drawn from.

One route serves the two modes of the screen, because they are not two questions: without
`from`/`to` it is today's session in market time (`Tiempo Real`), with them it is the window the
user asked for (`Histórico`). Which window "today" is, is the backend's decision -- it is the
only side of the cable that knows what timezone the market lives in. This file is H1, so what it
asks for is the first mode; `Histórico` and the validation of its range are H3.

Three claims here are the ones an implementation that "works" still gets wrong:

- **A failure of the provider still answers 200**. A 429 forwarded to the browser
  blames a user who has no account with any provider, and nothing in the body names who failed
.
- **A fresh cache spends no credit**: the database answers when it can, which is the
  whole of the quota seen from the endpoint.
- **The upsert is `DO UPDATE`**: the last candle of an open session is still forming, so fetching
  the same instant twice has to leave one row carrying the *new* close. With `DO NOTHING` the
  cache would keep a half-made price with the face of a final one, forever.

The provider is a double that counts calls, and it is the whole point of the file: nothing in a
response body tells a cached answer from one that spent a credit.
"""

from collections.abc import AsyncIterator, Iterator, Sequence
from datetime import UTC, datetime, timedelta
from decimal import Decimal

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_session
from app.main import app
from app.modules.auth.models import User
from app.modules.quotes.models import Quote
from app.modules.quotes.repository import QuoteRepository
from app.providers import (
    MarketDataProvider,
    ProviderQuotaExceeded,
    QuotePoint,
    StockRecord,
    get_market_data_provider,
)
from app.security import create_access_token
from app.settings import get_settings
from tests.architecture.test_route_authorization import PUBLIC_ROUTES
from tests.factories.quote_factory import QuoteFactory
from tests.factories.user_factory import UserFactory
from tests.factories.user_stock_factory import UserStockFactory

_QUOTES = "/api/quotes/TSLA"
_SECRET = "a-signing-secret-of-at-least-32-chars"

# A session of the past, used by every test that does not talk about today. 13:35Z is 09:35 in
# New York, which is five minutes after the opening bell -- and, read as a server hour, it is
# half past one in the afternoon. That distance is what makes the timezone testable.
_TRADED_ON = datetime(2026, 9, 8, 13, 35, tzinfo=UTC)


class _CountingProvider(MarketDataProvider):
    """The contract, counting calls: the only way the quota is checkable from the outside."""

    def __init__(self, points: Sequence[QuotePoint] = (), failure: Exception | None = None) -> None:
        """Answer with those points, or fail with that error."""
        self.points = list(points)
        self.failure = failure
        self.calls: list[tuple[str, str, datetime, datetime]] = []

    async def list_stocks(self, exchange: str) -> list[StockRecord]:
        """Not what this endpoint asks for."""
        return []

    async def get_time_series(
        self, symbol: str, interval: str, start: datetime, end: datetime
    ) -> list[QuotePoint]:
        """Record the call before anything else, then answer or fail."""
        self.calls.append((symbol, interval, start, end))

        if self.failure is not None:
            raise self.failure

        return list(self.points)


@pytest.fixture(autouse=True)
def signing_secret(monkeypatch: pytest.MonkeyPatch) -> Iterator[str]:
    """A usable `JWT_SECRET`, read at call time the way a request reads it."""
    get_settings.cache_clear()
    monkeypatch.setenv("JWT_SECRET", _SECRET)

    yield _SECRET

    get_settings.cache_clear()


@pytest.fixture
def provider() -> Iterator[_CountingProvider]:
    """The market data provider the request will be served with, and its call counter."""
    double = _CountingProvider()
    app.dependency_overrides[get_market_data_provider] = lambda: double

    yield double

    app.dependency_overrides.pop(get_market_data_provider, None)


@pytest.fixture
async def client(session: AsyncSession) -> AsyncIterator[AsyncClient]:
    """A client whose requests run inside the test's transaction, so nothing is left behind."""
    app.dependency_overrides[get_session] = lambda: session
    transport = ASGITransport(app=app)

    async with AsyncClient(transport=transport, base_url="http://test") as opened:
        yield opened

    app.dependency_overrides.pop(get_session, None)


@pytest.fixture
async def juan(session: AsyncSession) -> User:
    """The demo user of the README, following the symbol of the wireframe."""
    user = await UserFactory.create(session, username="juan", full_name="Juan Perez")
    await UserStockFactory.create(session, user_id=user.id, symbol="TSLA")

    return user


def _bearer(user: User) -> dict[str, str]:
    """The header a session token for that user travels in."""
    token = create_access_token(user_id=user.id, full_name=user.full_name)

    return {"Authorization": f"Bearer {token}"}


def _instants(payload: dict[str, object]) -> list[datetime]:
    """The instants of a response, parsed: the wire format is not what is under test here."""
    points = payload["points"]
    assert isinstance(points, list)

    return [datetime.fromisoformat(point["ts"]) for point in points]


class TestAskingForTodaysSession:
    """No `from`/`to` is `Tiempo Real`, which is the session of the day."""

    async def test_it_answers_200(
        self, client: AsyncClient, juan: User, provider: _CountingProvider, session: AsyncSession
    ) -> None:
        """The call the screen makes when somebody presses `Graficar`."""
        await QuoteFactory.create_series(
            session, first_ts=datetime.now(tz=UTC) - timedelta(seconds=30), count=1
        )

        response = await client.get(_QUOTES, params={"interval": "1min"}, headers=_bearer(juan))

        assert response.status_code == 200

    async def test_it_answers_the_symbol_the_interval_the_status_and_the_points(
        self, client: AsyncClient, juan: User, provider: _CountingProvider, session: AsyncSession
    ) -> None:
        """The body of `plan.md`, which is what `make types` turns into the frontend's type."""
        await QuoteFactory.create_series(
            session, first_ts=datetime.now(tz=UTC) - timedelta(seconds=30), count=1
        )

        response = await client.get(_QUOTES, params={"interval": "1min"}, headers=_bearer(juan))

        assert set(response.json()) == {"symbol", "interval", "status", "session_date", "points"}

    async def test_a_point_carries_its_instant_and_its_price(
        self, client: AsyncClient, juan: User, provider: _CountingProvider, session: AsyncSession
    ) -> None:
        """The chart draws one value per instant: the close, as a string (plan.md)."""
        await QuoteFactory.create_series(
            session, first_ts=datetime.now(tz=UTC) - timedelta(seconds=30), count=1
        )

        response = await client.get(_QUOTES, params={"interval": "1min"}, headers=_bearer(juan))

        assert set(response.json()["points"][0]) == {"ts", "price"}

    async def test_the_price_crosses_the_wire_as_a_string(
        self, client: AsyncClient, juan: User, provider: _CountingProvider, session: AsyncSession
    ) -> None:
        """It comes from a Decimal that exists precisely so as not to be a float (plan.md)."""
        await QuoteFactory.create_series(
            session, first_ts=datetime.now(tz=UTC) - timedelta(seconds=30), count=1
        )

        response = await client.get(_QUOTES, params={"interval": "1min"}, headers=_bearer(juan))

        assert isinstance(response.json()["points"][0]["price"], str)

    async def test_the_instants_are_utc_and_ascending(
        self, client: AsyncClient, juan: User, provider: _CountingProvider, session: AsyncSession
    ) -> None:
        """The axis is rendered in market time, but the wire carries the instant."""
        await QuoteFactory.create_series(
            session, first_ts=datetime.now(tz=UTC) - timedelta(minutes=3), count=3
        )

        response = await client.get(_QUOTES, params={"interval": "1min"}, headers=_bearer(juan))

        instants = _instants(response.json())
        assert instants == sorted(instants)

    async def test_a_fresh_cache_answers_without_spending_a_credit(
        self, client: AsyncClient, juan: User, provider: _CountingProvider, session: AsyncSession
    ) -> None:
        """From the endpoint: the database answers when it can."""
        await QuoteFactory.create_series(
            session, first_ts=datetime.now(tz=UTC) - timedelta(seconds=20), count=1
        )

        await client.get(_QUOTES, params={"interval": "1min"}, headers=_bearer(juan))

        assert provider.calls == []

    async def test_an_anonymous_call_is_refused(
        self, client: AsyncClient, provider: _CountingProvider
    ) -> None:
        """Data that costs quota is not served to whoever asks."""
        response = await client.get(_QUOTES, params={"interval": "1min"})

        assert response.status_code == 401

    def test_the_route_is_not_public(self) -> None:
        """The chart never joins `PUBLIC_ROUTES`: making it public would be a decision."""
        assert not any(route.startswith("GET /api/quotes") for route in PUBLIC_ROUTES)


class TestTheProviderIsNeverNamed:
    """Not in the happy path, and not in any of the three notices."""

    async def test_the_body_does_not_name_the_provider(
        self, client: AsyncClient, juan: User, provider: _CountingProvider, session: AsyncSession
    ) -> None:
        """The status says what happened, never who failed."""
        await QuoteFactory.create(session, ts=_TRADED_ON)
        provider.failure = ProviderQuotaExceeded("spent")

        response = await client.get(_QUOTES, params={"interval": "1min"}, headers=_bearer(juan))

        assert "twelvedata" not in response.text.lower()

    async def test_a_spent_quota_is_not_a_429_for_the_user(
        self, client: AsyncClient, juan: User, provider: _CountingProvider, session: AsyncSession
    ) -> None:
        """A 429 forwarded blames a client who has no account with anybody."""
        await QuoteFactory.create(session, ts=_TRADED_ON)
        provider.failure = ProviderQuotaExceeded("spent")

        response = await client.get(_QUOTES, params={"interval": "1min"}, headers=_bearer(juan))

        assert response.status_code == 200


class TestTheCacheKeepsOneRowPerInstant:
    """The upsert of the open candle, which is the one place `DO NOTHING` would be wrong."""

    async def test_fetching_the_same_instant_twice_leaves_one_row(
        self, session: AsyncSession
    ) -> None:
        """The composite key is the cache: a refresh cannot duplicate the series."""
        await QuoteFactory.create(session, ts=_TRADED_ON, close=Decimal("100.00"))

        await QuoteRepository(session).save("TSLA", "1min", [_forming(close="101.00")])

        rows = await session.scalar(
            select(func.count()).select_from(Quote).where(Quote.ts == _TRADED_ON)
        )
        assert rows == 1

    async def test_the_row_keeps_the_newer_close(self, session: AsyncSession) -> None:
        """At 10:05:30 the 10:05 candle is not the one that will stay.

        With `DO NOTHING` the cache would hold the half-made price for good, wearing the face of
        a final one -- which is a wrong closing price that nothing ever corrects.
        """
        await QuoteFactory.create(session, ts=_TRADED_ON, close=Decimal("100.00"))

        await QuoteRepository(session).save("TSLA", "1min", [_forming(close="101.00")])

        stored = await session.get(Quote, ("TSLA", "1min", _TRADED_ON))
        assert stored is not None
        assert stored.close_price == Decimal("101.00")


def _forming(close: str) -> QuotePoint:
    """The same instant as the stored candle, with the price it has a minute later."""
    price = Decimal(close)

    return QuotePoint(
        ts=_TRADED_ON,
        open=price - Decimal("0.5"),
        high=price + Decimal("0.75"),
        low=price - Decimal("0.75"),
        close=price,
        volume=200_000,
    )
