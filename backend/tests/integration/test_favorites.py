"""GET /api/favorites: the grid of My Actions (RF-01, RF-03, RF-05, RF-06, RF-07).

The endpoint the screen of the wireframe is painted from. Four claims here are the ones a
well-meaning implementation gets wrong, and each has its own class:

- **The list is the one of the token's user**, and the name and the currency come from the
  catalogue and not from `user_stocks`, which does not store them (RF-03). That a *second*
  user's rows never appear is the same statement seen from the outside, and it lives in
  `test_user_isolation.py` because it is Article III and deserves its own file.
- **The order is `added_at DESC, symbol ASC`** (RF-06). The tie-break is not decoration: the
  seed inserts the three favourites in one statement, so `now()` is the same for all of them,
  and without a second criterion the grid would reshuffle between two reloads. The test asks
  twice and compares, because an order that is merely usually right is the worst kind.
- **No favourites is `200 []`** and never a 404 (RF-07): an empty list is a result. The text
  `Todavía no agregaste ninguna acción.` belongs to the screen, so nothing here asserts it.
- **It is persisted, not remembered.** RF-05 is verified against Postgres with two distinct
  sessions of the same user -- the second one obtained by signing in again through the API, the
  way somebody who closed the tab gets one. A re-request on the same client would prove nothing.

And the delisted favourite, which is where `is_listed` earns its place in `StockInfo`: a symbol
that stopped trading disappears from the suggestions and **stays** in the grid of whoever had
it, with its name and its currency.
"""

from collections.abc import AsyncIterator, Iterator
from datetime import UTC, datetime

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_session
from app.main import app
from app.modules.auth.models import User
from app.security import create_access_token
from app.settings import get_settings
from tests.factories.stock_factory import StockFactory
from tests.factories.user_factory import PASSWORD, UserFactory
from tests.factories.user_stock_factory import UserStockFactory

_FAVORITES = "/api/favorites"
_LOGIN = "/api/auth/login"
_SECRET = "a-signing-secret-of-at-least-32-chars"

# Two instants, and the older one is what puts TSLA at the bottom of the grid. AAPL and NFLX
# share the newer one on purpose: that is the seed's case, and the one the tie-break exists for.
_EARLIER = datetime(2026, 9, 13, 10, 0, tzinfo=UTC)
_LATER = datetime(2026, 9, 13, 11, 0, tzinfo=UTC)


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
    """The demo user of the README, the one whose grid the wireframe draws."""
    return await UserFactory.create(session, username="juan", full_name="Juan Perez")


@pytest.fixture
async def the_grid_of_the_wireframe(session: AsyncSession, juan: User) -> User:
    """The three favourites of the brief's own screen, with AAPL and NFLX added together."""
    await UserStockFactory.create(
        session, user_id=juan.id, symbol="TSLA", added_at=_EARLIER, name="Tesla Inc"
    )
    await UserStockFactory.create(
        session, user_id=juan.id, symbol="AAPL", added_at=_LATER, name="Apple Inc"
    )
    await UserStockFactory.create(
        session, user_id=juan.id, symbol="NFLX", added_at=_LATER, name="Netflix Inc"
    )

    return juan


def _bearer(token: str) -> dict[str, str]:
    """The `Authorization` header a client presents a session token in."""
    return {"Authorization": f"Bearer {token}"}


def _token_of(user: User) -> str:
    """A session token for that user, signed the way the login signs one."""
    return create_access_token(user_id=user.id, full_name=user.full_name)


def _symbols(payload: list[dict[str, str]]) -> list[str]:
    """The symbols of a grid response, in the order the endpoint answered them."""
    return [row["symbol"] for row in payload]


class TestTheGridOfWhoeverIsAsking:
    """RF-01 and RF-03: the favourites of the token's user, described by the catalogue."""

    async def test_it_answers_200(
        self, client: AsyncClient, the_grid_of_the_wireframe: User
    ) -> None:
        """The call `Mis Acciones` makes when it mounts."""
        response = await client.get(
            _FAVORITES, headers=_bearer(_token_of(the_grid_of_the_wireframe))
        )

        assert response.status_code == 200

    async def test_it_answers_the_favourites_of_that_user(
        self, client: AsyncClient, the_grid_of_the_wireframe: User
    ) -> None:
        """RF-01: the three symbols of the wireframe, and nothing else."""
        response = await client.get(
            _FAVORITES, headers=_bearer(_token_of(the_grid_of_the_wireframe))
        )

        assert sorted(_symbols(response.json())) == ["AAPL", "NFLX", "TSLA"]

    async def test_every_row_carries_the_symbol_the_name_and_the_currency(
        self, client: AsyncClient, the_grid_of_the_wireframe: User
    ) -> None:
        """RF-03: the three columns of the grid, read from `stocks` and not from `user_stocks`.

        The favourites table stores neither the name nor the currency, so a row that carries
        them proves the cross-module read happened. The three are asserted together, each with
        its own name: checking one row would leave a batch read that pairs the descriptions
        with the wrong symbols -- `AAPL` wearing the name of `NFLX` -- looking correct.
        """
        response = await client.get(
            _FAVORITES, headers=_bearer(_token_of(the_grid_of_the_wireframe))
        )

        rows = {row["symbol"]: (row["name"], row["currency"]) for row in response.json()}
        assert rows == {
            "TSLA": ("Tesla Inc", "USD"),
            "AAPL": ("Apple Inc", "USD"),
            "NFLX": ("Netflix Inc", "USD"),
        }

    async def test_a_row_answers_those_three_fields_and_nothing_else(
        self, client: AsyncClient, the_grid_of_the_wireframe: User
    ) -> None:
        """A field added for convenience is API3:2023 (BOPLA), and the grid shows three."""
        response = await client.get(
            _FAVORITES, headers=_bearer(_token_of(the_grid_of_the_wireframe))
        )

        assert all(set(row) == {"symbol", "name", "currency"} for row in response.json())

    async def test_an_anonymous_call_is_refused(self, client: AsyncClient) -> None:
        """PY-08: the route is protected, and it is not in `PUBLIC_ROUTES`."""
        response = await client.get(_FAVORITES)

        assert response.status_code == 401


class TestTheOrderOfTheGrid:
    """RF-06: most recently added first, and the same order every time it is asked."""

    async def test_the_most_recent_comes_first_even_when_its_symbol_sorts_last(
        self, client: AsyncClient, session: AsyncSession, the_grid_of_the_wireframe: User
    ) -> None:
        """The freshly added row heads the grid, and recency beats the alphabet.

        The three of the wireframe happen to be in alphabetical order, so on their own they
        cannot tell `added_at DESC, symbol ASC` apart from a plain `symbol ASC`: the tie-break
        test below fixes the second criterion, not the first. A fourth favourite added after
        all of them, carrying the symbol that sorts last, separates the two -- ordering by
        symbol would send it to the bottom, and so would ordering by `added_at ASC`.
        """
        await UserStockFactory.create(
            session,
            user_id=the_grid_of_the_wireframe.id,
            symbol="ZZZZ",
            added_at=datetime(2026, 9, 13, 12, 0, tzinfo=UTC),
        )

        response = await client.get(
            _FAVORITES, headers=_bearer(_token_of(the_grid_of_the_wireframe))
        )

        assert _symbols(response.json()) == ["ZZZZ", "AAPL", "NFLX", "TSLA"]

    async def test_favourites_added_together_break_the_tie_by_symbol(
        self, client: AsyncClient, the_grid_of_the_wireframe: User
    ) -> None:
        """`added_at DESC, symbol ASC`: AAPL and NFLX share the instant, so AAPL wins."""
        response = await client.get(
            _FAVORITES, headers=_bearer(_token_of(the_grid_of_the_wireframe))
        )

        assert _symbols(response.json()) == ["AAPL", "NFLX", "TSLA"]

    async def test_asking_twice_answers_the_same_order(
        self, client: AsyncClient, the_grid_of_the_wireframe: User
    ) -> None:
        """Reloading twice must not move a row: an intermittent order is the worst failure.

        Without the tie-break this passes whenever Postgres happens to return the two rows of
        `_LATER` in the same sequence, which is most of the time and not always.
        """
        headers = _bearer(_token_of(the_grid_of_the_wireframe))

        first = await client.get(_FAVORITES, headers=headers)
        second = await client.get(_FAVORITES, headers=headers)

        assert _symbols(first.json()) == _symbols(second.json())
        assert _symbols(second.json()) == ["AAPL", "NFLX", "TSLA"]


class TestAUserWithNoFavourites:
    """RF-07: an empty list is a result, not a failure."""

    async def test_it_answers_an_empty_list(self, client: AsyncClient, juan: User) -> None:
        """200 and `[]`; the screen is the one that writes the empty-state text."""
        response = await client.get(_FAVORITES, headers=_bearer(_token_of(juan)))

        assert response.status_code == 200
        assert response.json() == []


class TestTheListSurvivesTheSession:
    """RF-05: the grid lives in Postgres, so a second sign-in finds it there."""

    async def test_a_second_session_of_the_same_user_sees_the_same_grid(
        self, session: AsyncSession, the_grid_of_the_wireframe: User
    ) -> None:
        """Two sessions, two clients, one list.

        The second token is obtained by signing in again through `POST /api/auth/login`, which
        is what somebody who closed the tab does. Re-requesting on the same client would only
        prove that the endpoint answers twice.
        """
        app.dependency_overrides[get_session] = lambda: session
        transport = ASGITransport(app=app)

        async with AsyncClient(transport=transport, base_url="http://test") as first_session:
            before = await first_session.get(
                _FAVORITES, headers=_bearer(_token_of(the_grid_of_the_wireframe))
            )

        async with AsyncClient(transport=transport, base_url="http://test") as second_session:
            signed_in = await second_session.post(
                _LOGIN, json={"username": "juan", "password": PASSWORD}
            )
            after = await second_session.get(
                _FAVORITES, headers=_bearer(signed_in.json()["access_token"])
            )

        app.dependency_overrides.pop(get_session, None)

        assert after.status_code == 200
        assert after.json() == before.json()
        assert _symbols(after.json()) == ["AAPL", "NFLX", "TSLA"]


class TestAFavouriteThatStoppedTrading:
    """The business rule `is_listed` exists for: it leaves the suggestions, not the grid."""

    async def test_a_delisted_favourite_is_still_in_the_grid(
        self, client: AsyncClient, session: AsyncSession, juan: User
    ) -> None:
        """Filtering it out of `get_stocks` would take away a row the user saved."""
        await StockFactory.create(
            session,
            symbol="ZZZZ",
            name="Zombie Holdings",
            currency="USD",
            delisted_at=datetime(2026, 8, 1, tzinfo=UTC),
        )
        await UserStockFactory.create(session, user_id=juan.id, symbol="ZZZZ", added_at=_LATER)

        response = await client.get(_FAVORITES, headers=_bearer(_token_of(juan)))

        assert _symbols(response.json()) == ["ZZZZ"]

    async def test_it_keeps_its_name_and_its_currency(
        self, client: AsyncClient, session: AsyncSession, juan: User
    ) -> None:
        """RF-03 holds for it too: the row is complete, not a bare symbol."""
        await StockFactory.create(
            session,
            symbol="ZZZZ",
            name="Zombie Holdings",
            currency="EUR",
            delisted_at=datetime(2026, 8, 1, tzinfo=UTC),
        )
        await UserStockFactory.create(session, user_id=juan.id, symbol="ZZZZ", added_at=_LATER)

        response = await client.get(_FAVORITES, headers=_bearer(_token_of(juan)))

        assert response.json() == [{"symbol": "ZZZZ", "name": "Zombie Holdings", "currency": "EUR"}]
