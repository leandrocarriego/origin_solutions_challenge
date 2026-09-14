"""POST /api/favorites: adding a stock to my list (RF-15, RF-17, RF-18, TEST-04).

Written before the route exists, so everything here answers 404 or 405 until task 12 mounts it.

Four claims, one class each, and the first one is the one the screen depends on:

- **Adding twice does not duplicate and does not fail.** The composite key `(user_id, symbol)`
  makes the second row impossible; `ON CONFLICT DO NOTHING` is what turns that guarantee into a
  polite answer. **201 the first time, 200 the second, the same body both times** -- never a
  409, because RF-18 asks for "it is already in your list", not for an error.
- **The double click is the same claim under concurrency.** Two `POST` in flight at once, each
  in its own transaction: one inserts, the other finds the row already there. This is the only
  test in the file that commits, because a race that both halves see needs two transactions.
- **The name and the currency come from the catalogue** (RF-17). `user_stocks` stores neither,
  so a body that carries them proves the cross-module read happened before the write.
- **An unknown symbol and a delisted one are both 404, and neither leaves a row.** The order
  inside `add_favorite` is what makes that true: the catalogue first, the `INSERT` second. The
  other way round, the foreign key would refuse the unknown one with an `IntegrityError` to
  translate, and the delisted one would be written.

The contract of the OpenAPI document is asserted too, because it is the one nobody remembers:
if the 200 is not declared, `schema.d.ts` types half the answer and the screen cannot tell "it
was added" from "it was already there".
"""

import asyncio
from collections.abc import AsyncIterator, Iterator
from datetime import UTC, datetime

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy import func, select, text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.db import get_session
from app.main import app
from app.modules.auth.models import User
from app.modules.favorites.models import UserStock
from app.security import create_access_token
from app.settings import get_settings
from tests.factories.stock_factory import StockFactory
from tests.factories.user_factory import UserFactory
from tests.factories.user_stock_factory import UserStockFactory

_FAVORITES = "/api/favorites"
_SECRET = "a-signing-secret-of-at-least-32-chars"

_ADDED_AT = datetime(2026, 9, 13, 11, 0, tzinfo=UTC)
_DELISTED_AT = datetime(2026, 8, 1, tzinfo=UTC)

_MICROSOFT = {"symbol": "MSFT", "name": "Microsoft Corp", "currency": "USD"}

# The symbol of the race, and it is made up on purpose: that test commits what it writes, so it
# may only delete rows that nobody else could have put there.
_RACED = "ZZRACE"


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
    """The demo user of the README, with an empty list to start with."""
    return await UserFactory.create(session, username="juan", full_name="Juan Perez")


@pytest.fixture
async def catalogue(session: AsyncSession) -> None:
    """One listed symbol to add, and one that stopped trading and may not be added."""
    await StockFactory.create(session, symbol="MSFT", name="Microsoft Corp", currency="USD")
    await StockFactory.create(
        session,
        symbol="ZZZZ",
        name="Zombie Holdings",
        currency="EUR",
        delisted_at=_DELISTED_AT,
    )


def _bearer(user: User) -> dict[str, str]:
    """The header a session token for that user travels in."""
    token = create_access_token(user_id=user.id, full_name=user.full_name)

    return {"Authorization": f"Bearer {token}"}


async def _rows_of(session: AsyncSession, user_id: int, symbol: str) -> int:
    """How many favourites that user has for that symbol: the whole of TEST-04 is this number."""
    counted = await session.scalar(
        select(func.count())
        .select_from(UserStock)
        .where(UserStock.user_id == user_id, UserStock.symbol == symbol)
    )

    return counted or 0


class TestAddingAStockThatIsNotThereYet:
    r"""RF-15 and RF-17: it is created, and it is described by the catalogue.

    **Corrected on 2026-09-14, by a human decision.** As first signed, the normalisation test
    posted `{"symbol": "  msft "}` and expected a 201 with `MSFT`. That could never pass: the
    `plan.md` of `002-favorite-stocks` (*Contratos* -> `POST /api/favorites`) gives the body's
    symbol the pattern `^[A-Za-z0-9.\-]{1,12}$`, which rejects the spaces with a 422 before any
    service runs, while the same plan puts the upper-casing in the service "and not in the
    schema". No implementation satisfies both.

    Faced with the contradiction the human of the project (Leandro Carriego) decided that **the
    plan wins**. So the test keeps the half that is still true -- upper-casing lives in the
    service -- and the half the plan decided got a test of its own, right below it: spaces
    around the symbol are a 422.
    """

    async def test_it_answers_201(self, client: AsyncClient, juan: User, catalogue: None) -> None:
        """Created, and the status says so: the screen tells the two answers apart by it."""
        response = await client.post(_FAVORITES, json={"symbol": "MSFT"}, headers=_bearer(juan))

        assert response.status_code == 201

    async def test_the_body_is_the_row_of_the_grid(
        self, client: AsyncClient, juan: User, catalogue: None
    ) -> None:
        """RF-17: the name and the currency are read from `stocks`, which is where they live."""
        response = await client.post(_FAVORITES, json={"symbol": "MSFT"}, headers=_bearer(juan))

        assert response.json() == _MICROSOFT

    async def test_the_row_is_written(
        self, client: AsyncClient, session: AsyncSession, juan: User, catalogue: None
    ) -> None:
        """The answer is not the point: the favourite has to be in `user_stocks`."""
        await client.post(_FAVORITES, json={"symbol": "MSFT"}, headers=_bearer(juan))

        assert await _rows_of(session, juan.id, "MSFT") == 1

    async def test_the_symbol_is_normalised_before_anything_else(
        self, client: AsyncClient, session: AsyncSession, juan: User, catalogue: None
    ) -> None:
        """`add_favorite` upper-cases, so `"msft"` is the symbol `MSFT` and is written once.

        Normalising in the service and not in the schema is what makes the same rule hold for
        the add and for the delete, and this is the test that keeps it from moving.
        """
        response = await client.post(_FAVORITES, json={"symbol": "msft"}, headers=_bearer(juan))

        assert response.status_code == 201
        assert response.json()["symbol"] == "MSFT"
        assert await _rows_of(session, juan.id, "MSFT") == 1

    async def test_a_symbol_with_spaces_around_it_never_reaches_the_service(
        self, client: AsyncClient, session: AsyncSession, juan: User, catalogue: None
    ) -> None:
        r"""`" msft "` is a **422**, and that is a decision, not an oversight.

        The body's symbol carries the pattern `^[A-Za-z0-9.\-]{1,12}$` because a symbol is an
        identifier, not free text: this same value travels in the URL of the delete, and what
        cannot be a segment of a path cannot be a symbol. A space is not in that set, so the
        schema refuses it before any service exists to trim it.

        It does not contradict the test above. Upper-casing is the service's job and stays
        there; surrounding whitespace is simply never a symbol to begin with, and the two rules
        do not overlap.
        """
        response = await client.post(_FAVORITES, json={"symbol": " msft "}, headers=_bearer(juan))

        assert response.status_code == 422
        assert await _rows_of(session, juan.id, "MSFT") == 0

    async def test_an_anonymous_call_is_refused(self, client: AsyncClient) -> None:
        """PY-08: the route is protected, and it is not in `PUBLIC_ROUTES`."""
        response = await client.post(_FAVORITES, json={"symbol": "MSFT"})

        assert response.status_code == 401


class TestAddingAStockThatIsAlreadyThere:
    """RF-18 and TEST-04: the second time is not an error, and it is not a second row."""

    async def test_the_second_add_answers_200(
        self, client: AsyncClient, juan: User, catalogue: None
    ) -> None:
        """Never a 409: somebody who double-clicks wants the same thing twice."""
        first = await client.post(_FAVORITES, json={"symbol": "MSFT"}, headers=_bearer(juan))
        second = await client.post(_FAVORITES, json={"symbol": "MSFT"}, headers=_bearer(juan))

        assert first.status_code == 201
        assert second.status_code == 200

    async def test_both_answers_carry_the_same_body(
        self, client: AsyncClient, juan: User, catalogue: None
    ) -> None:
        """The screen paints the row either way, so the body cannot depend on the status."""
        first = await client.post(_FAVORITES, json={"symbol": "MSFT"}, headers=_bearer(juan))
        second = await client.post(_FAVORITES, json={"symbol": "MSFT"}, headers=_bearer(juan))

        assert second.json() == first.json() == _MICROSOFT

    async def test_there_is_still_exactly_one_row(
        self, client: AsyncClient, session: AsyncSession, juan: User, catalogue: None
    ) -> None:
        """The composite key makes it impossible; this is what says the code agrees."""
        await client.post(_FAVORITES, json={"symbol": "MSFT"}, headers=_bearer(juan))
        await client.post(_FAVORITES, json={"symbol": "MSFT"}, headers=_bearer(juan))

        assert await _rows_of(session, juan.id, "MSFT") == 1

    async def test_a_favourite_added_before_this_session_answers_200_too(
        self, client: AsyncClient, session: AsyncSession, juan: User, catalogue: None
    ) -> None:
        """It was already in the list, whoever put it there and whenever."""
        await UserStockFactory.create(
            session, user_id=juan.id, symbol="MSFT", added_at=_ADDED_AT, name="Microsoft Corp"
        )

        response = await client.post(_FAVORITES, json={"symbol": "MSFT"}, headers=_bearer(juan))

        assert response.status_code == 200
        assert await _rows_of(session, juan.id, "MSFT") == 1


class TestTwoAddsAtOnce:
    """The double click, with both halves in flight: two transactions, one row.

    This is the only test of the file that commits, and it has to. The rest run inside the
    rolled-back transaction of `session`, and a race that two requests must both see cannot
    happen inside one: the second one would simply read the first one's uncommitted row through
    the same session, which proves nothing about `ON CONFLICT DO NOTHING`.

    So it opens its own engine, seeds a committed world, and deletes it afterwards -- whatever
    the assertions did.
    """

    @pytest.fixture
    async def committed_world(self) -> AsyncIterator[tuple[int, async_sessionmaker[AsyncSession]]]:
        """A user and a catalogue row that exist for every connection, not just for one.

        The symbol is invented rather than borrowed: what this fixture commits it also deletes,
        and deleting `MSFT` would take away a row the developer's own catalogue may hold. The
        same goes for the user, whose name belongs to nobody else.
        """
        engine = create_async_engine(get_settings().database_url)
        factory = async_sessionmaker(engine, expire_on_commit=False)

        async with factory() as setting_up:
            user = await UserFactory.create(setting_up, username="juan-de-la-carrera")
            await StockFactory.create(
                setting_up, symbol=_RACED, name="Zz Race Corp", currency="USD"
            )
            await setting_up.commit()
            user_id = user.id

        yield user_id, factory

        async with factory() as cleaning_up:
            await cleaning_up.execute(
                text("DELETE FROM user_stocks WHERE user_id = :user_id"), {"user_id": user_id}
            )
            await cleaning_up.execute(
                text("DELETE FROM users WHERE id = :user_id"), {"user_id": user_id}
            )
            await cleaning_up.execute(
                text("DELETE FROM stocks WHERE symbol = :symbol"), {"symbol": _RACED}
            )
            await cleaning_up.commit()

        await engine.dispose()

    async def test_two_simultaneous_adds_leave_one_row_and_do_not_raise(
        self, committed_world: tuple[int, async_sessionmaker[AsyncSession]]
    ) -> None:
        """One 201 and one 200, in whichever order the database serialises them."""
        user_id, factory = committed_world

        async def _fresh_session() -> AsyncIterator[AsyncSession]:
            """A session of its own per request: that is what makes this a race."""
            async with factory() as opened:
                yield opened

        app.dependency_overrides[get_session] = _fresh_session
        transport = ASGITransport(app=app)
        headers = {"Authorization": f"Bearer {create_access_token(user_id=user_id, full_name='x')}"}

        async with AsyncClient(transport=transport, base_url="http://test") as first:
            async with AsyncClient(transport=transport, base_url="http://test") as second:
                answers = await asyncio.gather(
                    first.post(_FAVORITES, json={"symbol": _RACED}, headers=headers),
                    second.post(_FAVORITES, json={"symbol": _RACED}, headers=headers),
                )

        app.dependency_overrides.pop(get_session, None)

        async with factory() as reading:
            rows = await _rows_of(reading, user_id, _RACED)

        assert sorted(answer.status_code for answer in answers) == [200, 201]
        assert rows == 1


class TestASymbolThatCannotBeAdded:
    """404 for the one that does not exist and for the one that stopped trading."""

    async def test_an_unknown_symbol_is_a_404(
        self, client: AsyncClient, juan: User, catalogue: None
    ) -> None:
        """The catalogue is asked before anything is written, so this never reaches the key."""
        response = await client.post(_FAVORITES, json={"symbol": "NOPE"}, headers=_bearer(juan))

        assert response.status_code == 404
        assert response.json() == {"detail": "unknown symbol"}

    async def test_an_unknown_symbol_leaves_no_row(
        self, client: AsyncClient, session: AsyncSession, juan: User, catalogue: None
    ) -> None:
        """A 404 with a row written would be the worst of both answers."""
        response = await client.post(_FAVORITES, json={"symbol": "NOPE"}, headers=_bearer(juan))

        assert response.status_code == 404
        assert await _rows_of(session, juan.id, "NOPE") == 0

    async def test_a_delisted_symbol_is_a_404_as_well(
        self, client: AsyncClient, juan: User, catalogue: None
    ) -> None:
        """RF-12's counterpart: what the autocomplete does not offer cannot be added by hand.

        The same message as the unknown one, on purpose: from outside, a symbol that stopped
        trading and one that never existed are the same answer.
        """
        response = await client.post(_FAVORITES, json={"symbol": "ZZZZ"}, headers=_bearer(juan))

        assert response.status_code == 404
        assert response.json() == {"detail": "unknown symbol"}

    async def test_a_delisted_symbol_leaves_no_row(
        self, client: AsyncClient, session: AsyncSession, juan: User, catalogue: None
    ) -> None:
        """The row exists in `stocks`, so only checking the catalogue first prevents this."""
        response = await client.post(_FAVORITES, json={"symbol": "ZZZZ"}, headers=_bearer(juan))

        assert response.status_code == 404
        assert await _rows_of(session, juan.id, "ZZZZ") == 0


class TestWhatTheOpenApiDocumentSays:
    """The test that gets forgotten: `schema.d.ts` is generated from this document.

    FastAPI documents the `status_code` of the route and nothing else, so the 200 of the
    idempotent add is invisible unless the route declares it. The screen then has no typed way
    of telling `Esa acción ya está en tu lista.` from a row that was just created.
    """

    def test_both_the_201_and_the_200_are_declared(self) -> None:
        """Two responses, and the same model behind both."""
        responses = app.openapi()["paths"][_FAVORITES]["post"]["responses"]

        assert "201" in responses
        assert "200" in responses
