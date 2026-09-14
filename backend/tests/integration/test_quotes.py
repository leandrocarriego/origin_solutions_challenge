"""GET /api/quotes/{symbol}: the series the chart is drawn from (RF-13, RF-16, RF-26, RF-41…RF-47).

One route serves the two modes of the screen, because they are not two questions: without
`from`/`to` it is today's session in market time (`Tiempo Real`), with them it is the window the
user asked for (`Histórico`). Which window "today" is, is the backend's decision -- it is the
only side of the cable that knows what timezone the market lives in.

Four claims here are the ones an implementation that "works" still gets wrong:

- **The four states answer 200** (`ERR-05`). A 429 forwarded to the browser blames a user who has
  no account with any provider, and a 404 for a symbol that is in our own catalogue says something
  that is not true.
- **`from` and `to` are market hours**, not server hours. The pair of tests that fixes this asks
  for the same candle twice, once in each reading: only one of them may find it.
- **An invalid range costs nothing** (`RF-47`): no credit, and not even a query. It is refused
  before the window is resolved.
- **The upsert is `DO UPDATE`**: the last candle of an open session is still forming, so fetching
  the same instant twice has to leave one row carrying the *new* close. With `DO NOTHING` the
  cache would keep a half-made price with the face of a final one, forever.

The provider is a double that counts calls, and it is the whole point of the file: nothing in a
response body tells a cached answer from one that spent a credit (Article II, TEST-03).
"""

from collections.abc import AsyncIterator, Iterator, Sequence
from datetime import UTC, datetime, timedelta
from decimal import Decimal

import pytest
from app.modules.quotes.repository import save
from httpx import ASGITransport, AsyncClient
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_session
from app.main import app
from app.modules.auth.models import User
from app.modules.quotes.models import Quote
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
    """The contract, counting calls: the only way Article II is checkable from the outside."""

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
    """RF-13: no `from`/`to` is `Tiempo Real`, which is the session of the day."""

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
        """RF-15: the axis is rendered in market time, but the wire carries the instant."""
        await QuoteFactory.create_series(
            session, first_ts=datetime.now(tz=UTC) - timedelta(minutes=3), count=3
        )

        response = await client.get(_QUOTES, params={"interval": "1min"}, headers=_bearer(juan))

        instants = _instants(response.json())
        assert instants == sorted(instants)

    async def test_a_fresh_cache_answers_without_spending_a_credit(
        self, client: AsyncClient, juan: User, provider: _CountingProvider, session: AsyncSession
    ) -> None:
        """RF-24 seen from the endpoint: the database answers when it can (Article II)."""
        await QuoteFactory.create_series(
            session, first_ts=datetime.now(tz=UTC) - timedelta(seconds=20), count=1
        )

        await client.get(_QUOTES, params={"interval": "1min"}, headers=_bearer(juan))

        assert provider.calls == []

    async def test_an_anonymous_call_is_refused(
        self, client: AsyncClient, provider: _CountingProvider
    ) -> None:
        """PY-08: data that costs quota is not served to whoever asks."""
        response = await client.get(_QUOTES, params={"interval": "1min"})

        assert response.status_code == 401

    def test_the_route_is_not_public(self) -> None:
        """The chart never joins `PUBLIC_ROUTES`: making it public would be a decision."""
        assert not any(route.startswith("GET /api/quotes") for route in PUBLIC_ROUTES)


class TestAskingForAWindowOfThePast:
    """RF-16 and RF-36: `Histórico`, and the hours the user writes are the market's."""

    async def test_from_and_to_are_read_as_market_hours(
        self, client: AsyncClient, juan: User, provider: _CountingProvider, session: AsyncSession
    ) -> None:
        """09:30 to 10:00 is the opening of the session, and the candle is inside it."""
        await QuoteFactory.create(session, ts=_TRADED_ON)

        response = await client.get(
            _QUOTES,
            params={
                "interval": "1min",
                "from": "2026-09-08T09:30:00",
                "to": "2026-09-08T10:00:00",
            },
            headers=_bearer(juan),
        )

        assert len(response.json()["points"]) == 1

    async def test_from_and_to_are_not_read_as_server_hours(
        self, client: AsyncClient, juan: User, provider: _CountingProvider, session: AsyncSession
    ) -> None:
        """The same candle, asked for by its UTC wall clock, must not be found.

        This is the half that catches the bug. A service that stamped UTC on the naive input
        would answer the 13:35Z candle here as well, and both tests would be green while the
        whole chart sat four hours away from where the user asked for it.
        """
        await QuoteFactory.create(session, ts=_TRADED_ON)

        response = await client.get(
            _QUOTES,
            params={
                "interval": "1min",
                "from": "2026-09-08T13:30:00",
                "to": "2026-09-08T14:00:00",
            },
            headers=_bearer(juan),
        )

        assert response.json()["points"] == []

    async def test_the_series_falls_entirely_inside_the_window(
        self, client: AsyncClient, juan: User, provider: _CountingProvider, session: AsyncSession
    ) -> None:
        """RF-16: no point before `from`, no point after `to`."""
        await QuoteFactory.create(session, ts=_TRADED_ON - timedelta(hours=2))
        await QuoteFactory.create(session, ts=_TRADED_ON)
        await QuoteFactory.create(session, ts=_TRADED_ON + timedelta(hours=8))

        response = await client.get(
            _QUOTES,
            params={
                "interval": "1min",
                "from": "2026-09-08T09:30:00",
                "to": "2026-09-08T16:00:00",
            },
            headers=_bearer(juan),
        )

        assert _instants(response.json()) == [_TRADED_ON]

    async def test_a_cached_window_of_the_past_spends_no_credit(
        self, client: AsyncClient, juan: User, provider: _CountingProvider, session: AsyncSession
    ) -> None:
        """Yesterday's prices do not expire, so a closed window is never refetched (RF-24)."""
        await QuoteFactory.create_series(session, first_ts=_TRADED_ON, count=3)

        await client.get(
            _QUOTES,
            params={
                "interval": "1min",
                "from": "2026-09-08T09:30:00",
                "to": "2026-09-08T16:00:00",
            },
            headers=_bearer(juan),
        )

        assert provider.calls == []


class TestARangeThatCannotBeAskedFor:
    """RF-41 to RF-45 and RF-47: the 422 the screen turns into the text under the fields."""

    @pytest.mark.parametrize(
        "start,end",
        [
            ("2026-09-08T10:00:00", "2026-09-08T10:00:00"),
            ("2026-09-08T11:00:00", "2026-09-08T10:00:00"),
        ],
        ids=["equal", "reversed"],
    )
    async def test_from_not_before_to_is_422(
        self,
        client: AsyncClient,
        juan: User,
        provider: _CountingProvider,
        start: str,
        end: str,
    ) -> None:
        """RF-41, and 422 rather than 400: it is the shape of the query that is wrong."""
        response = await client.get(
            _QUOTES,
            params={"interval": "1min", "from": start, "to": end},
            headers=_bearer(juan),
        )

        assert response.status_code == 422

    async def test_an_inverted_range_says_which_rule_it_broke(
        self, client: AsyncClient, juan: User, provider: _CountingProvider
    ) -> None:
        """The `code` is what the screen maps to a literal of COPY.md; the body carries no text."""
        response = await client.get(
            _QUOTES,
            params={
                "interval": "1min",
                "from": "2026-09-08T11:00:00",
                "to": "2026-09-08T10:00:00",
            },
            headers=_bearer(juan),
        )

        assert response.json()["detail"]["code"] == "range_invalid"

    @pytest.mark.parametrize(
        "interval,days",
        [("1min", 8), ("5min", 31), ("15min", 91)],
    )
    async def test_a_range_longer_than_its_interval_allows_is_422(
        self,
        client: AsyncClient,
        juan: User,
        provider: _CountingProvider,
        interval: str,
        days: int,
    ) -> None:
        """RF-42 to RF-44, from the side that refuses: one day past the cap."""
        start = datetime(2026, 6, 1, 10, 0)

        response = await client.get(
            _QUOTES,
            params={
                "interval": interval,
                "from": start.strftime("%Y-%m-%dT%H:%M:%S"),
                "to": (start + timedelta(days=days)).strftime("%Y-%m-%dT%H:%M:%S"),
            },
            headers=_bearer(juan),
        )

        assert response.status_code == 422

    @pytest.mark.parametrize(
        "interval,days",
        [("1min", 7), ("5min", 30), ("15min", 90)],
    )
    async def test_a_range_exactly_at_the_cap_is_accepted(
        self,
        client: AsyncClient,
        juan: User,
        provider: _CountingProvider,
        interval: str,
        days: int,
    ) -> None:
        """RF-42 to RF-44, from the side that graphs: the boundary is allowed."""
        start = datetime(2026, 6, 1, 10, 0)

        response = await client.get(
            _QUOTES,
            params={
                "interval": interval,
                "from": start.strftime("%Y-%m-%dT%H:%M:%S"),
                "to": (start + timedelta(days=days)).strftime("%Y-%m-%dT%H:%M:%S"),
            },
            headers=_bearer(juan),
        )

        assert response.status_code == 200

    async def test_a_range_too_long_carries_the_interval_and_its_cap(
        self, client: AsyncClient, juan: User, provider: _CountingProvider
    ) -> None:
        """RF-45: `{intervalo}` and `{N}` of the text are filled in from the body, not guessed.

        The caps live in the service and nowhere else: a browser that carried its own copy would
        be a business rule written twice, and one of the two would go stale.
        """
        response = await client.get(
            _QUOTES,
            params={
                "interval": "1min",
                "from": "2026-06-01T10:00:00",
                "to": "2026-06-30T10:00:00",
            },
            headers=_bearer(juan),
        )

        detail = response.json()["detail"]
        assert (detail["code"], detail["interval"], detail["max_days"]) == (
            "range_too_long",
            "1min",
            7,
        )

    @pytest.mark.parametrize(
        "params",
        [
            {"interval": "1min", "from": "2026-09-08T09:30:00"},
            {"interval": "1min", "to": "2026-09-08T16:00:00"},
        ],
        ids=["only from", "only to"],
    )
    async def test_half_a_range_is_refused(
        self,
        client: AsyncClient,
        juan: User,
        provider: _CountingProvider,
        params: dict[str, str],
    ) -> None:
        """`from` and `to` are both or neither: half a window is not a window (plan.md)."""
        response = await client.get(_QUOTES, params=params, headers=_bearer(juan))

        assert response.status_code == 422

    async def test_an_interval_that_is_not_one_of_the_three_is_refused(
        self, client: AsyncClient, juan: User, provider: _CountingProvider
    ) -> None:
        """RF-06: the screen offers three, and the API accepts three."""
        response = await client.get(_QUOTES, params={"interval": "2min"}, headers=_bearer(juan))

        assert response.status_code == 422

    @pytest.mark.parametrize(
        "params",
        [
            {"interval": "1min", "from": "2026-09-08T11:00:00", "to": "2026-09-08T10:00:00"},
            {"interval": "1min", "from": "2026-06-01T10:00:00", "to": "2026-06-30T10:00:00"},
            {"interval": "1min", "from": "2026-09-08T09:30:00"},
        ],
        ids=["reversed", "too long", "half"],
    )
    async def test_an_invalid_range_spends_no_credit(
        self,
        client: AsyncClient,
        juan: User,
        provider: _CountingProvider,
        params: dict[str, str],
    ) -> None:
        """RF-47: a query the screen would not have sent does not reach the world either."""
        await client.get(_QUOTES, params=params, headers=_bearer(juan))

        assert provider.calls == []


class TestTheProviderIsNeverNamed:
    """RF-26 and Article I: not in the happy path, and not in any of the three notices."""

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
        """ERR-05: a 429 forwarded blames a client who has no account with anybody."""
        await QuoteFactory.create(session, ts=_TRADED_ON)
        provider.failure = ProviderQuotaExceeded("spent")

        response = await client.get(_QUOTES, params={"interval": "1min"}, headers=_bearer(juan))

        assert response.status_code == 200


class TestTheCacheKeepsOneRowPerInstant:
    """The upsert of the open candle, which is the one place `DO NOTHING` would be wrong."""

    async def test_fetching_the_same_instant_twice_leaves_one_row(
        self, session: AsyncSession
    ) -> None:
        """The composite key is the cache: a refresh cannot duplicate the series (ADR-001)."""
        await QuoteFactory.create(session, ts=_TRADED_ON, close=Decimal("100.00"))

        await save(session, "TSLA", "1min", [_forming(close="101.00")])

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

        await save(session, "TSLA", "1min", [_forming(close="101.00")])

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
