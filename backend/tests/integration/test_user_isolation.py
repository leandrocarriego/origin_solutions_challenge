"""Two users, real rows, and neither one reaches the other's data.

This is the half of the isolation rule that could not exist before there was an endpoint serving
belongs to somebody. The other half is already running and is static:
`TestNoRouteAcceptsAUserId` in `tests/architecture/test_route_authorization.py` fails for any
route that takes the identity of the user from the path, the query string or the body. That check
reads spellings, so it cannot see a repository that accepts the right argument and forgets it in
the `WHERE`. This one can.

It is API1:2023 -- Broken Object Level Authorization -- which is the number one of the OWASP API
Security Top 10 and the main risk of this project. The shape of the failure it catches is not an
exotic attack: it is a query that filters by nothing because the filter was assumed to be
somewhere else.

The file grows with the feature: the read is here from H1, the write of H2 and the delete of H3
add their own classes, and `003` adds the chart -- the first endpoint that serves data of a user
through an object of somebody else's choosing. Every endpoint that touches data of a
user gets a row here, or it is an IDOR that passes the pre-commit.
"""

from collections.abc import AsyncIterator, Iterator
from datetime import UTC, datetime

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_session
from app.main import app
from app.modules.auth.models import User
from app.modules.favorites.models import UserStock
from app.providers import (
    MarketDataProvider,
    QuotePoint,
    StockRecord,
    get_market_data_provider,
)
from app.security import create_access_token
from app.settings import get_settings
from tests.factories.user_factory import UserFactory
from tests.factories.user_stock_factory import UserStockFactory

_FAVORITES = "/api/favorites"
_SECRET = "a-signing-secret-of-at-least-32-chars"

_ADDED_AT = datetime(2026, 9, 13, 11, 0, tzinfo=UTC)


class _CallCounter(MarketDataProvider):
    """A provider that answers nothing and remembers every time it was asked."""

    def __init__(self) -> None:
        """Start with no calls recorded: what is under test is that there are none."""
        self.calls: list[tuple[str, str]] = []

    async def list_stocks(self, exchange: str) -> list[StockRecord]:
        """Not what the chart asks for."""
        return []

    async def get_time_series(
        self, symbol: str, interval: str, start: datetime, end: datetime
    ) -> list[QuotePoint]:
        """Record the call, then answer with nothing: reaching here is already the failure."""
        self.calls.append((symbol, interval))

        return []


@pytest.fixture(autouse=True)
def signing_secret(monkeypatch: pytest.MonkeyPatch) -> Iterator[str]:
    """A usable `JWT_SECRET`, read at call time the way a request reads it."""
    get_settings.cache_clear()
    monkeypatch.setenv("JWT_SECRET", _SECRET)

    yield _SECRET

    get_settings.cache_clear()


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
    """One of the two demo users, following TSLA and AAPL."""
    user = await UserFactory.create(session, username="juan", full_name="Juan Perez")
    await UserStockFactory.create(session, user_id=user.id, symbol="TSLA", added_at=_ADDED_AT)
    await UserStockFactory.create(session, user_id=user.id, symbol="AAPL", added_at=_ADDED_AT)

    return user


@pytest.fixture
async def ana(session: AsyncSession) -> User:
    """The other demo user, following something else entirely.

    Her list shares no symbol with juan's on purpose: if they overlapped, a leak would look like
    a legitimate row and the assertion would not be able to tell them apart.
    """
    user = await UserFactory.create(session, username="ana", full_name="Ana Gomez")
    await UserStockFactory.create(session, user_id=user.id, symbol="NFLX", added_at=_ADDED_AT)
    await UserStockFactory.create(session, user_id=user.id, symbol="MSFT", added_at=_ADDED_AT)

    return user


def _bearer(user: User) -> dict[str, str]:
    """The header a session token for that user travels in."""
    token = create_access_token(user_id=user.id, full_name=user.full_name)

    return {"Authorization": f"Bearer {token}"}


def _symbols(payload: list[dict[str, str]]) -> set[str]:
    """The symbols a grid response carried, as a set: which ones, not in what order."""
    return {row["symbol"] for row in payload}


async def _favourites_of(session: AsyncSession, user_id: int) -> set[str]:
    """The symbols that user follows, read from the table rather than from an endpoint."""
    rows = await session.scalars(select(UserStock.symbol).where(UserStock.user_id == user_id))

    return set(rows.all())


class TestReadingTheGrid:
    """The grid is the token's user's, and the other list does not exist for it."""

    async def test_each_token_gets_its_own_list(
        self, client: AsyncClient, juan: User, ana: User
    ) -> None:
        """Two tokens against the same endpoint, two different answers."""
        of_juan = await client.get(_FAVORITES, headers=_bearer(juan))
        of_ana = await client.get(_FAVORITES, headers=_bearer(ana))

        assert _symbols(of_juan.json()) == {"TSLA", "AAPL"}
        assert _symbols(of_ana.json()) == {"NFLX", "MSFT"}

    async def test_no_row_of_the_other_user_leaks_in(
        self, client: AsyncClient, juan: User, ana: User
    ) -> None:
        """The failure this catches is a query whose `WHERE` lost its filter.

        Said as an intersection and not as an absence of one symbol: a repository that returned
        the whole table would pass a check for "NFLX is not there" the day juan happens to
        follow NFLX too.
        """
        response = await client.get(_FAVORITES, headers=_bearer(juan))

        assert _symbols(response.json()).isdisjoint({"NFLX", "MSFT"})

    async def test_the_grid_is_not_the_whole_table(
        self, client: AsyncClient, juan: User, ana: User
    ) -> None:
        """Four favourites exist between the two users; one token may see two of them."""
        response = await client.get(_FAVORITES, headers=_bearer(juan))

        assert len(response.json()) == 2


class TestAddingToTheGrid:
    """One user adding is one user's row, and the other list does not move.

    The interesting case is the symbol ana **already follows**. A service that asked "is this
    symbol already a favourite" without filtering by user would answer juan a polite 200, write
    nothing, and leave him staring at a grid that did not change -- the same bug as the leak,
    seen from the writing side.
    """

    async def test_adding_a_symbol_the_other_user_follows_creates_a_row_of_ones_own(
        self, client: AsyncClient, session: AsyncSession, juan: User, ana: User
    ) -> None:
        """NFLX is in ana's list and not in juan's, so for juan this is a creation."""
        response = await client.post(_FAVORITES, json={"symbol": "NFLX"}, headers=_bearer(juan))

        assert response.status_code == 201
        assert await _favourites_of(session, juan.id) == {"TSLA", "AAPL", "NFLX"}

    async def test_the_other_users_list_is_untouched(
        self, client: AsyncClient, session: AsyncSession, juan: User, ana: User
    ) -> None:
        """Ana keeps exactly the two she had: not one more, not one fewer, none rewritten."""
        response = await client.post(_FAVORITES, json={"symbol": "NFLX"}, headers=_bearer(juan))

        assert response.status_code == 201
        assert await _favourites_of(session, ana.id) == {"NFLX", "MSFT"}

    async def test_the_other_user_still_reads_her_own_list(
        self, client: AsyncClient, juan: User, ana: User
    ) -> None:
        """Read back through the API, which is where somebody would notice the damage."""
        added = await client.post(_FAVORITES, json={"symbol": "NFLX"}, headers=_bearer(juan))

        response = await client.get(_FAVORITES, headers=_bearer(ana))

        assert added.status_code == 201
        assert _symbols(response.json()) == {"NFLX", "MSFT"}


class TestRemovingFromTheGrid:
    """One user removing is one user's row leaving, and the other list does not move.

    This is the test that matters of the three, and the reason is the shape of the failure. The
    read leaks data and the write adds a row; a delete that lost its filter **destroys** somebody
    else's data, silently and with a perfectly polite 204 -- there is no body to look wrong and no
    error to notice. And the removal is idempotent on purpose, so "it answered 204" says
    nothing at all about whose row it reached.

    So the interesting request is the symbol juan does **not** follow and ana **does**: the one
    row in the table with that symbol belongs to her. A `DELETE ... WHERE symbol = 'NFLX'` that
    forgot `user_id` answers juan exactly the same 204 and takes NFLX out of ana's grid.
    """

    async def test_removing_a_symbol_the_other_user_follows_answers_204(
        self, client: AsyncClient, juan: User, ana: User
    ) -> None:
        """For juan this is a removal of something that was never in his list, which is 204."""
        response = await client.delete(f"{_FAVORITES}/NFLX", headers=_bearer(juan))

        assert response.status_code == 204

    async def test_the_other_users_row_is_still_there(
        self, client: AsyncClient, session: AsyncSession, juan: User, ana: User
    ) -> None:
        """Ana keeps exactly the two she had: the 204 was about juan's list, which had none."""
        response = await client.delete(f"{_FAVORITES}/NFLX", headers=_bearer(juan))

        assert response.status_code == 204
        assert await _favourites_of(session, ana.id) == {"NFLX", "MSFT"}

    async def test_the_other_user_still_reads_her_own_list(
        self, client: AsyncClient, juan: User, ana: User
    ) -> None:
        """Read back through the API, which is where somebody would notice the damage."""
        removed = await client.delete(f"{_FAVORITES}/NFLX", headers=_bearer(juan))

        response = await client.get(_FAVORITES, headers=_bearer(ana))

        assert removed.status_code == 204
        assert _symbols(response.json()) == {"NFLX", "MSFT"}

    async def test_removing_ones_own_symbol_leaves_the_other_list_alone(
        self, client: AsyncClient, session: AsyncSession, juan: User, ana: User
    ) -> None:
        """The same claim with the roles swapped: a real removal is still only one user's.

        Without it, a repository that filtered by symbol alone would still be caught above --
        but one that filtered by neither, and emptied `user_stocks`, would not.
        """
        response = await client.delete(f"{_FAVORITES}/TSLA", headers=_bearer(juan))

        assert response.status_code == 204
        assert await _favourites_of(session, juan.id) == {"AAPL"}
        assert await _favourites_of(session, ana.id) == {"NFLX", "MSFT"}


class TestReadingTheChart:
    """The chart is served only for the favourites of who is asking.

    404 and not 403: a 403 confirms that the symbol exists and belongs to another user, and here
    there is nothing to confirm. It is also the answer `002` gives for a symbol that cannot be
    added, so the frontend has one case to handle and not two.

    The pair of tests is the whole statement: the 404 is the part a reviewer looks for, and the
    call counter is the part that matters for the quota -- an implementation that authorizes
    *after* fetching answers the same 404 and has already spent a credit on somebody else's
    symbol.
    """

    @pytest.fixture
    def provider(self) -> Iterator[_CallCounter]:
        """The market data provider the request would be served with, counting its calls."""
        counter = _CallCounter()
        app.dependency_overrides[get_market_data_provider] = lambda: counter

        yield counter

        app.dependency_overrides.pop(get_market_data_provider, None)

    async def test_a_symbol_of_the_other_user_is_not_found(
        self, client: AsyncClient, juan: User, ana: User, provider: _CallCounter
    ) -> None:
        """TSLA is juan's. For ana's token it does not exist."""
        response = await client.get(
            "/api/quotes/TSLA", params={"interval": "1min"}, headers=_bearer(ana)
        )

        assert response.status_code == 404

    async def test_a_symbol_of_the_other_user_costs_no_quota(
        self, client: AsyncClient, juan: User, ana: User, provider: _CallCounter
    ) -> None:
        """Authorizing first is what makes the refusal free."""
        await client.get("/api/quotes/TSLA", params={"interval": "1min"}, headers=_bearer(ana))

        assert provider.calls == []

    async def test_the_owner_of_the_symbol_is_served(
        self, client: AsyncClient, juan: User, provider: _CallCounter
    ) -> None:
        """The same request, with the token of whoever has TSLA in their list."""
        response = await client.get(
            "/api/quotes/TSLA", params={"interval": "1min"}, headers=_bearer(juan)
        )

        assert response.status_code == 200
