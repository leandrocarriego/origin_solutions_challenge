"""The four states, over HTTP: all of them 200, and none of them naming anybody.

H4 decided in the service is tested in `tests/unit/test_quotes_status.py`; what is tested here
is the half the service cannot decide by itself -- the status code the browser gets, and the
bytes that reach the screen.

Both halves matter and neither covers the other. A service that returns `stale` proves nothing
about the response if the router turns a `ProviderQuotaExceeded` into a 429 on its way out, and
a 429 forwarded to the browser blames a user who has no account with any provider. The
same for the name: the service can be perfectly generic and a handler can still leak the
provider into an error body.

The four states are arranged from the outside, with rows and a provider double, because that is
how they happen in production: fresh candles are `ok`, a refusal upstream is `stale`, a day with
nothing but an earlier session in the cache is `market_closed`, and an empty cache with an empty
answer is `no_data`.
"""

from collections.abc import AsyncIterator, Iterator, Sequence
from datetime import UTC, datetime, timedelta
from decimal import Decimal
from typing import Any
from zoneinfo import ZoneInfo

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_session
from app.main import app
from app.modules.auth.models import User
from app.modules.favorites.models import UserStock
from app.modules.quotes.models import Quote
from app.modules.stocks.models import Stock
from app.providers import (
    MarketDataProvider,
    ProviderError,
    ProviderQuotaExceeded,
    ProviderRejectedCredentials,
    ProviderUnavailable,
    QuotePoint,
    StockRecord,
    SymbolNotFound,
    get_market_data_provider,
)
from app.security import create_access_token
from app.settings import get_settings
from tests.factories.user_factory import UserFactory

_QUOTES = "/api/quotes/TSLA"
_SYMBOL = "TSLA"
_SECRET = "a-signing-secret-of-at-least-32-chars"

# The one market of the catalogue (A4), which is where a session date is a date.
_MARKET = ZoneInfo("America/New_York")

# The four ways the world can refuse to answer. Not one of them is an error of ours.
_FAILURES = [
    ProviderUnavailable("down"),
    ProviderQuotaExceeded("spent"),
    ProviderRejectedCredentials("bad key"),
    SymbolNotFound("no series for that symbol"),
]
_FAILURE_IDS = ["unavailable", "quota", "credentials", "unknown symbol"]

# The four states of the contract (plan.md). A status outside this set is a screen with no
# notice to draw, which is the requirement broken from the other side.
_STATES = {"ok", "stale", "market_closed", "no_data"}


class _Double(MarketDataProvider):
    """The contract, answering with points or failing with one of the four errors."""

    def __init__(
        self, points: Sequence[QuotePoint] = (), failure: ProviderError | None = None
    ) -> None:
        """Answer with those points, or fail with that error."""
        self.points = list(points)
        self.failure = failure

    async def list_stocks(self, exchange: str) -> list[StockRecord]:
        """Not what this endpoint asks for."""
        return []

    async def get_time_series(
        self, symbol: str, interval: str, start: datetime, end: datetime
    ) -> list[QuotePoint]:
        """Answer or fail, which is the only thing these tests arrange it for."""
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
def provider() -> Iterator[_Double]:
    """The market data provider the request is served with, silent by default."""
    double = _Double()
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
    await _follow(session, user_id=user.id, symbol=_SYMBOL)

    return user


async def _follow(session: AsyncSession, user_id: int, symbol: str) -> None:
    """Make the symbol one of that user's favourites, catalogue row included."""
    await _catalogue(session, symbol)
    session.add(UserStock(user_id=user_id, symbol=symbol))
    await session.flush()


async def _catalogue(session: AsyncSession, symbol: str) -> None:
    """Insert the `stocks` row the two foreign keys need, if it is not there yet."""
    if await session.get(Stock, symbol) is not None:
        return

    session.add(
        Stock(
            symbol=symbol,
            name="Tesla Inc",
            currency="USD",
            exchange="NASDAQ",
            mic_code="XNGS",
            country="United States",
            instrument_type="Common Stock",
            last_seen_at=datetime.now(tz=UTC),
        )
    )
    await session.flush()


async def _candle(session: AsyncSession, ts: datetime, close: str = "365.47") -> None:
    """Store one `1min` candle of `TSLA`, which is what a warm cache looks like."""
    price = Decimal(close)
    await _catalogue(session, _SYMBOL)

    session.add(
        Quote(
            symbol=_SYMBOL,
            interval="1min",
            ts=ts,
            open_price=price - Decimal("0.5"),
            high_price=price + Decimal("0.75"),
            low_price=price - Decimal("0.75"),
            close_price=price,
            volume=100_000,
        )
    )
    await session.flush()


async def _an_earlier_session(session: AsyncSession) -> datetime:
    """Store three candles of a session three days back, and answer the instant it opened.

    Three days rather than one keeps the test off the calendar: "yesterday" lands on a Sunday
    once a week, and then the arrangement would be saying something it did not mean.
    """
    opened = (
        (datetime.now(tz=UTC) - timedelta(days=3))
        .astimezone(_MARKET)
        .replace(hour=10, minute=0, second=0, microsecond=0)
    ).astimezone(UTC)

    for minute in range(3):
        await _candle(session, ts=opened + timedelta(minutes=minute))

    return opened


def _bearer(user: User) -> dict[str, str]:
    """The header a session token for that user travels in."""
    token = create_access_token(user_id=user.id, full_name=user.full_name)

    return {"Authorization": f"Bearer {token}"}


async def _chart(client: AsyncClient, user: User) -> Any:
    """Ask for today's chart at `1min`, which is the call the screen makes."""
    return await client.get(_QUOTES, params={"interval": "1min"}, headers=_bearer(user))


class TestDataThatIsUpToDate:
    """Nothing to explain, so nothing is said."""

    async def test_fresh_data_answers_ok(
        self, client: AsyncClient, juan: User, provider: _Double, session: AsyncSession
    ) -> None:
        """A candle ten seconds old is inside its TTL, so the cache answers and says so."""
        await _candle(session, ts=datetime.now(tz=UTC) - timedelta(seconds=10))

        response = await _chart(client, juan)

        assert response.json()["status"] == "ok"

    async def test_ok_carries_no_session_date(
        self, client: AsyncClient, juan: User, provider: _Double, session: AsyncSession
    ) -> None:
        """`session_date` is the `{fecha}` of the notice and travels only with `market_closed`."""
        await _candle(session, ts=datetime.now(tz=UTC) - timedelta(seconds=10))

        response = await _chart(client, juan)

        assert response.json()["session_date"] is None


class TestADayWithNoSession:
    """The Saturday of the demo, charted with the last session there was."""

    async def test_an_empty_today_with_an_earlier_session_is_market_closed(
        self, client: AsyncClient, juan: User, provider: _Double, session: AsyncSession
    ) -> None:
        """Nothing traded today and the provider confirms it with an empty series."""
        await _an_earlier_session(session)

        response = await _chart(client, juan)

        assert response.json()["status"] == "market_closed"

    async def test_it_charts_that_earlier_session(
        self, client: AsyncClient, juan: User, provider: _Double, session: AsyncSession
    ) -> None:
        """The last session available, and not a blank screen."""
        opened = await _an_earlier_session(session)

        response = await _chart(client, juan)

        assert datetime.fromisoformat(response.json()["points"][0]["ts"]) == opened

    async def test_it_names_the_day_that_session_traded_in_market_time(
        self, client: AsyncClient, juan: User, provider: _Double, session: AsyncSession
    ) -> None:
        """A session that crosses midnight in UTC is still one day where it happened."""
        opened = await _an_earlier_session(session)

        response = await _chart(client, juan)

        assert response.json()["session_date"] == opened.astimezone(_MARKET).date().isoformat()


class TestNothingAnywhere:
    """No series for that symbol and interval, which is not the same as a closed market."""

    async def test_an_empty_cache_and_an_empty_answer_is_no_data(
        self, client: AsyncClient, juan: User, provider: _Double
    ) -> None:
        """The state the screen turns into the notice that names the symbol."""
        response = await _chart(client, juan)

        assert response.json()["status"] == "no_data"

    async def test_no_data_carries_no_points(
        self, client: AsyncClient, juan: User, provider: _Double
    ) -> None:
        """The screen has to tell an empty chart from a chart it never drew."""
        response = await _chart(client, juan)

        assert response.json()["points"] == []


class TestAProviderThatFailed:
    """The failure is answered, and it is answered as `stale`."""

    async def test_a_refusal_with_a_warm_cache_is_stale(
        self, client: AsyncClient, juan: User, provider: _Double, session: AsyncSession
    ) -> None:
        """What is charted could not be refreshed, and that is what is said."""
        await _an_earlier_session(session)
        provider.failure = ProviderQuotaExceeded("spent")

        response = await _chart(client, juan)

        assert response.json()["status"] == "stale"

    async def test_a_refusal_is_never_reported_as_a_closed_market(
        self, client: AsyncClient, juan: User, provider: _Double, session: AsyncSession
    ) -> None:
        """We do not know whether the market is closed, so we do not say that it is."""
        await _an_earlier_session(session)
        provider.failure = ProviderUnavailable("no answer")

        response = await _chart(client, juan)

        assert response.json()["status"] != "market_closed"

    async def test_a_stale_answer_still_carries_the_last_prices_known(
        self, client: AsyncClient, juan: User, provider: _Double, session: AsyncSession
    ) -> None:
        """The chart is drawn anyway, which is the whole point of the notice."""
        await _an_earlier_session(session)
        provider.failure = ProviderUnavailable("no answer")

        response = await _chart(client, juan)

        assert len(response.json()["points"]) == 3


class TestEveryStateAnswers200:
    """A failure upstream never reaches the browser as a failure of ours."""

    @pytest.mark.parametrize("failure", _FAILURES, ids=_FAILURE_IDS)
    async def test_a_provider_failure_is_not_an_error_of_the_endpoint(
        self,
        client: AsyncClient,
        juan: User,
        provider: _Double,
        session: AsyncSession,
        failure: ProviderError,
    ) -> None:
        """A 429 forwarded blames a user who has no account with anybody; a 401 blames nobody."""
        await _an_earlier_session(session)
        provider.failure = failure

        response = await _chart(client, juan)

        assert response.status_code == 200

    async def test_a_day_with_no_session_is_not_an_error(
        self, client: AsyncClient, juan: User, provider: _Double, session: AsyncSession
    ) -> None:
        """A closed market is the normal state of two days out of seven."""
        await _an_earlier_session(session)

        response = await _chart(client, juan)

        assert response.status_code == 200

    async def test_a_symbol_with_no_series_is_not_a_404(
        self, client: AsyncClient, juan: User, provider: _Double
    ) -> None:
        """The symbol is in our catalogue and in the user's list: 404 would say otherwise."""
        response = await _chart(client, juan)

        assert response.status_code == 200


class TestTheProviderIsNeverNamed:
    """Not in the happy path, and not in any of the three notices."""

    @pytest.mark.parametrize("failure", _FAILURES, ids=_FAILURE_IDS)
    async def test_no_body_names_the_provider(
        self,
        client: AsyncClient,
        juan: User,
        provider: _Double,
        session: AsyncSession,
        failure: ProviderError,
    ) -> None:
        """The status says what happened, never who failed.

        The state is asserted alongside the absence: a body that named nobody because it was not
        a chart at all would pass the second half of this on its own.
        """
        await _an_earlier_session(session)
        provider.failure = failure

        response = await _chart(client, juan)

        assert response.json()["status"] in _STATES
        assert "twelvedata" not in response.text.lower()
