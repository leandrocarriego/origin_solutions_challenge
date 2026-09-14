"""DELETE /api/favorites/{symbol}: taking a stock out of my list (RF-24, RF-27).

Written before the route exists, so everything here answers 404 or 405 until task 17 mounts it.
That is the intended red: absence of implementation, not a broken import -- nothing in this file
names a function that has yet to be written, because the whole contract of the removal is visible
over HTTP.

Three claims, one class each:

- **204 always, and the removal is idempotent.** Removing something that is not in the list is
  not a mistake to report: whoever deletes twice wants the same thing both times, and a 404 would
  be the one answer that tells an attacker whether a symbol is in somebody's list. The second
  delete of the same symbol answers exactly like the first (RF-24).
- **It is persisted, not remembered.** The backend half of the F5 that RF-24 asks for on screen:
  a *second* session of the same user -- signed in again through `POST /api/auth/login`, the way
  somebody who closed the tab gets one -- still does not see the action that was removed. Asking
  again on the same client would only prove that the endpoint answers twice.
- **The catalogue is not touched** (RF-27). `user_stocks` is the only table this route writes:
  the symbol stays in `stocks` and the very next search suggests it again, which is what makes
  "I removed it by accident" a recoverable mistake instead of a permanent one.

What is *not* here is the isolation between users: the delete of a symbol that **is** in somebody
else's list lives in `test_user_isolation.py`, next to the read and the write of the same rule,
because it is Article III and deserves to be read in one place.
"""

from collections.abc import AsyncIterator, Iterator
from datetime import UTC, datetime

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_session
from app.main import app
from app.modules.auth.models import User
from app.modules.favorites.models import UserStock
from app.modules.stocks.models import Stock
from app.security import create_access_token
from app.settings import get_settings
from tests.factories.user_factory import PASSWORD, UserFactory
from tests.factories.user_stock_factory import UserStockFactory

_FAVORITES = "/api/favorites"
_LOGIN = "/api/auth/login"
_STOCKS = "/api/stocks"
_SECRET = "a-signing-secret-of-at-least-32-chars"

_ADDED_AT = datetime(2026, 9, 13, 11, 0, tzinfo=UTC)

# Netflix is the symbol the copy itself uses for the confirmation
# (`¿Quitar NFLX de tus acciones?`), so the tests of the two ends talk about the same action.
_NETFLIX = "NFLX"
_APPLE = "AAPL"


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
    """The demo user of the README."""
    return await UserFactory.create(session, username="juan", full_name="Juan Perez")


@pytest.fixture
async def the_list_of_juan(session: AsyncSession, juan: User) -> User:
    """Two favourites, so that removing one can be told apart from emptying the list."""
    await UserStockFactory.create(
        session, user_id=juan.id, symbol=_NETFLIX, added_at=_ADDED_AT, name="Netflix Inc"
    )
    await UserStockFactory.create(
        session, user_id=juan.id, symbol=_APPLE, added_at=_ADDED_AT, name="Apple Inc"
    )

    return juan


def _bearer(token: str) -> dict[str, str]:
    """The `Authorization` header a session token travels in."""
    return {"Authorization": f"Bearer {token}"}


def _token_of(user: User) -> str:
    """A session token for that user, signed the way the login signs one."""
    return create_access_token(user_id=user.id, full_name=user.full_name)


def _symbols(payload: list[dict[str, str]]) -> list[str]:
    """The symbols a grid answer carried, in the order it carried them."""
    return [row["symbol"] for row in payload]


async def _rows_of(session: AsyncSession, user_id: int, symbol: str) -> int:
    """How many favourites that user has for that symbol: 1 before the delete, 0 after it."""
    counted = await session.scalar(
        select(func.count())
        .select_from(UserStock)
        .where(UserStock.user_id == user_id, UserStock.symbol == symbol)
    )

    return counted or 0


class TestRemovingAFavouriteThatIsThere:
    """RF-24: the action leaves the list, and the answer carries no body to read."""

    async def test_it_answers_204(self, client: AsyncClient, the_list_of_juan: User) -> None:
        """No content, because there is nothing to say: the list is what changed."""
        response = await client.delete(
            f"{_FAVORITES}/{_NETFLIX}", headers=_bearer(_token_of(the_list_of_juan))
        )

        assert response.status_code == 204

    async def test_the_row_is_gone(
        self, client: AsyncClient, session: AsyncSession, the_list_of_juan: User
    ) -> None:
        """The answer is not the point: `user_stocks` has to have lost that row."""
        await client.delete(
            f"{_FAVORITES}/{_NETFLIX}", headers=_bearer(_token_of(the_list_of_juan))
        )

        assert await _rows_of(session, the_list_of_juan.id, _NETFLIX) == 0

    async def test_the_rest_of_the_list_is_untouched(
        self, client: AsyncClient, the_list_of_juan: User
    ) -> None:
        """One row leaves, the other stays: a `WHERE` without the symbol would empty the grid."""
        headers = _bearer(_token_of(the_list_of_juan))
        await client.delete(f"{_FAVORITES}/{_NETFLIX}", headers=headers)

        grid = await client.get(_FAVORITES, headers=headers)

        assert _symbols(grid.json()) == [_APPLE]

    async def test_a_lower_case_symbol_removes_the_same_row(
        self, client: AsyncClient, session: AsyncSession, the_list_of_juan: User
    ) -> None:
        """The service upper-cases before touching the table, as it does for the add.

        Normalising in the service and not in the schema is what makes one rule serve both
        routes (`plan.md` -> *Contratos*), and this is the test that keeps it from moving.
        """
        response = await client.delete(
            f"{_FAVORITES}/{_NETFLIX.lower()}", headers=_bearer(_token_of(the_list_of_juan))
        )

        assert response.status_code == 204
        assert await _rows_of(session, the_list_of_juan.id, _NETFLIX) == 0

    async def test_an_anonymous_call_is_refused(self, client: AsyncClient) -> None:
        """PY-08: the route is protected, and it is not in `PUBLIC_ROUTES`."""
        response = await client.delete(f"{_FAVORITES}/{_NETFLIX}")

        assert response.status_code == 401


class TestRemovingSomethingThatIsNotInTheList:
    """RF-24: the removal has no failure mode, which is a decision and not an oversight."""

    async def test_a_symbol_that_was_never_there_answers_204_too(
        self, client: AsyncClient, the_list_of_juan: User
    ) -> None:
        """Never a 404: the list ends up without that symbol, which is what was asked for.

        A 404 would also answer a question nobody may ask -- whether that symbol is in the list
        of whoever holds this token -- and the answer to that is the filter by user, not a
        status code.
        """
        response = await client.delete(
            f"{_FAVORITES}/MSFT", headers=_bearer(_token_of(the_list_of_juan))
        )

        assert response.status_code == 204

    async def test_it_writes_nothing_at_all(
        self, client: AsyncClient, the_list_of_juan: User
    ) -> None:
        """A polite answer that emptied the grid would be worse than a 404.

        The status is asserted here too, and not only in the test above: without it this passes
        while the route does not exist at all -- a 404 leaves the grid untouched as well, and a
        test that is green before the code is written says nothing about the code.
        """
        headers = _bearer(_token_of(the_list_of_juan))
        removed = await client.delete(f"{_FAVORITES}/MSFT", headers=headers)

        grid = await client.get(_FAVORITES, headers=headers)

        assert removed.status_code == 204
        assert sorted(_symbols(grid.json())) == [_APPLE, _NETFLIX]

    async def test_removing_the_same_symbol_twice_answers_the_same_both_times(
        self, client: AsyncClient, session: AsyncSession, the_list_of_juan: User
    ) -> None:
        """TEST-04 seen from the other side: the second delete is the same request, repeated.

        Somebody who double-clicks `Eliminar`, or whose first request was retried by the
        network, must not be told that something went wrong the second time.
        """
        headers = _bearer(_token_of(the_list_of_juan))

        first = await client.delete(f"{_FAVORITES}/{_NETFLIX}", headers=headers)
        second = await client.delete(f"{_FAVORITES}/{_NETFLIX}", headers=headers)

        assert first.status_code == second.status_code == 204
        assert await _rows_of(session, the_list_of_juan.id, _NETFLIX) == 0


class TestTheRemovalSurvivesTheSession:
    """RF-24, backend half: the list lives in Postgres, so it is gone for the next session too."""

    async def test_a_second_session_of_the_same_user_does_not_see_it_again(
        self, session: AsyncSession, the_list_of_juan: User
    ) -> None:
        """Two sessions, two clients, one list -- and one action fewer in it.

        The second token is obtained by signing in again through `POST /api/auth/login`, which
        is what somebody who closed the tab does. Re-requesting on the same client would only
        prove that the endpoint answers twice.
        """
        app.dependency_overrides[get_session] = lambda: session
        transport = ASGITransport(app=app)

        async with AsyncClient(transport=transport, base_url="http://test") as first_session:
            removed = await first_session.delete(
                f"{_FAVORITES}/{_NETFLIX}", headers=_bearer(_token_of(the_list_of_juan))
            )

        async with AsyncClient(transport=transport, base_url="http://test") as second_session:
            signed_in = await second_session.post(
                _LOGIN, json={"username": "juan", "password": PASSWORD}
            )
            after = await second_session.get(
                _FAVORITES, headers=_bearer(signed_in.json()["access_token"])
            )

        app.dependency_overrides.pop(get_session, None)

        assert removed.status_code == 204
        assert after.status_code == 200
        assert _symbols(after.json()) == [_APPLE]


class TestTheCatalogueIsNotTouched:
    """RF-27: what leaves is the favourite, never the stock.

    The removal writes `user_stocks` and nothing else. If it ever reached `stocks`, taking an
    action out of one list would take it out of everybody's autocomplete -- and out of the lists
    of whoever else follows it, through the foreign key.
    """

    async def test_the_stock_stays_in_the_catalogue(
        self, client: AsyncClient, session: AsyncSession, the_list_of_juan: User
    ) -> None:
        """Read from the table, which is where the damage would be.

        The 204 is asserted alongside it for the same reason as above: a route that does not
        exist yet also leaves `stocks` alone.
        """
        removed = await client.delete(
            f"{_FAVORITES}/{_NETFLIX}", headers=_bearer(_token_of(the_list_of_juan))
        )

        assert removed.status_code == 204
        assert await session.get(Stock, _NETFLIX) is not None

    async def test_the_next_search_suggests_it_again(
        self, client: AsyncClient, the_list_of_juan: User
    ) -> None:
        """The recoverable mistake: removed by accident, offered again by the autocomplete.

        Asked through the search endpoint and not through the table, because that is the door
        the screen knocks on: a row that survived in `stocks` but stopped being suggested would
        leave RF-27 false for the person even though the data is still there.
        """
        headers = _bearer(_token_of(the_list_of_juan))
        removed = await client.delete(f"{_FAVORITES}/{_NETFLIX}", headers=headers)

        suggestions = await client.get(_STOCKS, params={"q": _NETFLIX}, headers=headers)

        assert removed.status_code == 204
        assert suggestions.status_code == 200
        assert _NETFLIX in _symbols(suggestions.json())
