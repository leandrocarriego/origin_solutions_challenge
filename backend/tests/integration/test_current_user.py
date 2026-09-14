"""GET /api/auth/me: who the token says is calling.

The endpoint that lets a reloaded page find out it still has a session without asking for the
credential again. It is the first protected route of the project, so this file is also where the
shape of every later refusal gets fixed: one 401, one body, one `WWW-Authenticate`, whichever of
the four ways the credential failed.

Two assertions here are about what the endpoint must *not* do, and they are the reason it exists
as its own file instead of a couple of cases inside `test_login.py`:

- **It does not read the database.** The claims are the source (`plan.md`), so a token issued for
  a user that is not in `users` still answers 200. The stronger version of the same statement is
  the client whose session dependency raises: if anything asks for a session, the test says so by
  name. A `/me` that queried `users` on every navigation would turn the cheapest call of the
  application into a round trip per screen.
- **It answers two fields and not the row.** A response that grew `username` or, worse,
  `password_hash` would be API3:2023 (BOPLA) added by convenience.

The expired token is built with an `exp` in the past. Waiting an hour is not a test (the TTL, whose
sixty minutes are fixed in `tests/unit/test_access_token.py`).
"""

from collections.abc import AsyncIterator, Iterator
from datetime import UTC, datetime, timedelta
from typing import Any

import jwt
import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_session
from app.main import app
from app.modules.auth.models import User
from app.modules.auth.service import LOGIN_MAX_ATTEMPTS, LOGIN_WINDOW
from app.ratelimit import SlidingWindowLimiter
from app.security import ACCESS_TOKEN_TTL, create_access_token
from app.settings import get_settings
from tests.factories.user_factory import PASSWORD, UserFactory

_ME = "/api/auth/me"
_LOGIN = "/api/auth/login"
_SECRET = "a-signing-secret-of-at-least-32-chars"

# An id no row of the test database can have: the fixture truncates `users` with RESTART IDENTITY,
# so the sequence starts at 1 and nothing here inserts nine hundred thousand users.
_ID_OF_NOBODY = 900_001


@pytest.fixture(autouse=True)
def signing_secret(monkeypatch: pytest.MonkeyPatch) -> Iterator[str]:
    """A usable `JWT_SECRET`, read at call time the way a request reads it."""
    get_settings.cache_clear()
    monkeypatch.setenv("JWT_SECRET", _SECRET)

    yield _SECRET

    get_settings.cache_clear()


@pytest.fixture(autouse=True)
def a_fresh_limiter(monkeypatch: pytest.MonkeyPatch) -> Iterator[SlidingWindowLimiter]:
    """Give each test its own attempt counter: the service keeps one per process."""
    limiter = SlidingWindowLimiter(limit=LOGIN_MAX_ATTEMPTS, window=LOGIN_WINDOW)
    monkeypatch.setattr("app.modules.auth.service._login_limiter", limiter)

    yield limiter


@pytest.fixture
async def client(session: AsyncSession) -> AsyncIterator[AsyncClient]:
    """A client whose requests run inside the test's transaction, so nothing is left behind."""
    app.dependency_overrides[get_session] = lambda: session
    transport = ASGITransport(app=app)

    async with AsyncClient(transport=transport, base_url="http://test") as opened:
        yield opened

    app.dependency_overrides.pop(get_session, None)


@pytest.fixture
async def client_with_no_database() -> AsyncIterator[AsyncClient]:
    """A client that fails by name the moment anything asks it for a database session.

    The point is not to save the test a connection: it is that "`/me` answers the claims and does
    not touch the base" stops being a sentence in the plan and becomes something a run can tell
    apart from an implementation that queries `users` and happens to find the row.
    """

    def _refuse_to_open_a_session() -> AsyncSession:
        """Stand in for `get_session`, and report the read instead of serving it."""
        raise AssertionError(f"GET {_ME} asked for a database session; its source is the token")

    app.dependency_overrides[get_session] = _refuse_to_open_a_session
    transport = ASGITransport(app=app)

    async with AsyncClient(transport=transport, base_url="http://test") as opened:
        yield opened

    app.dependency_overrides.pop(get_session, None)


@pytest.fixture
async def juan(session: AsyncSession) -> User:
    """The demo user of the README, the one whose name the header shows."""
    return await UserFactory.create(session, username="juan", full_name="Juan Perez")


def _bearer(token: str) -> dict[str, str]:
    """The `Authorization` header a client presents a session token in."""
    return {"Authorization": f"Bearer {token}"}


def _expired_token(user_id: int, full_name: str) -> str:
    """A token that was valid and is not any more, signed properly and with `exp` in the past."""
    expired_at = datetime.now(tz=UTC) - timedelta(minutes=5)
    claims: dict[str, Any] = {
        "sub": str(user_id),
        "name": full_name,
        "iat": int((expired_at - ACCESS_TOKEN_TTL).timestamp()),
        "exp": int(expired_at.timestamp()),
    }

    return jwt.encode(claims, _SECRET, algorithm="HS256")


def _tampered(token: str) -> str:
    """The same token with its last character changed, which invalidates the signature."""
    last = token[-1]

    return token[:-1] + ("a" if last != "a" else "b")


class TestATokenThatIsGood:
    """The session is recognised, and nobody is asked for a credential again."""

    async def test_it_answers_200(self, client: AsyncClient, juan: User) -> None:
        """The call a reloaded page makes before deciding which screen to show."""
        token = create_access_token(user_id=juan.id, full_name=juan.full_name)

        response = await client.get(_ME, headers=_bearer(token))

        assert response.status_code == 200

    async def test_it_answers_the_identity_of_the_token(
        self, client: AsyncClient, juan: User
    ) -> None:
        """The `sub` of the token and nothing else decides whose data this is."""
        token = create_access_token(user_id=juan.id, full_name=juan.full_name)

        response = await client.get(_ME, headers=_bearer(token))

        assert response.json()["id"] == juan.id

    async def test_it_answers_the_full_name_and_not_the_username(
        self, client: AsyncClient, juan: User
    ) -> None:
        """The header reads `Usuario: Juan Perez`, never `Usuario: juan`."""
        token = create_access_token(user_id=juan.id, full_name=juan.full_name)

        response = await client.get(_ME, headers=_bearer(token))

        assert juan.username == "juan", "the two have to differ, or the assertion proves nothing"
        assert response.json()["full_name"] == "Juan Perez"

    async def test_it_answers_those_two_fields_and_nothing_else(
        self, client: AsyncClient, juan: User
    ) -> None:
        """A field added for convenience is API3:2023 (BOPLA): the hash is one paste away."""
        token = create_access_token(user_id=juan.id, full_name=juan.full_name)

        response = await client.get(_ME, headers=_bearer(token))

        assert set(response.json()) == {"id", "full_name"}

    async def test_the_token_the_login_just_handed_out_opens_it(
        self, client: AsyncClient, juan: User
    ) -> None:
        """End to end: what the login answers is what the next screen travels with."""
        logged_in = await client.post(_LOGIN, json={"username": "juan", "password": PASSWORD})

        response = await client.get(_ME, headers=_bearer(logged_in.json()["access_token"]))

        assert response.status_code == 200
        assert response.json()["full_name"] == logged_in.json()["full_name"]


class TestItAnswersTheClaimsAndNotTheTable:
    """The whole reason the endpoint is cheap: it reads a string it already has."""

    async def test_a_token_of_a_user_that_is_not_in_the_base_still_answers_200(
        self, client: AsyncClient
    ) -> None:
        """The claims are the source: a lookup here would be a query per navigation."""
        token = create_access_token(user_id=_ID_OF_NOBODY, full_name="Fantasma Sin Fila")

        response = await client.get(_ME, headers=_bearer(token))

        assert response.status_code == 200
        assert response.json() == {"id": _ID_OF_NOBODY, "full_name": "Fantasma Sin Fila"}

    async def test_it_answers_without_ever_asking_for_a_session(
        self, client_with_no_database: AsyncClient
    ) -> None:
        """Same statement, said so that an implementation that queried `users` cannot pass."""
        token = create_access_token(user_id=_ID_OF_NOBODY, full_name="Fantasma Sin Fila")

        response = await client_with_no_database.get(_ME, headers=_bearer(token))

        assert response.status_code == 200


class TestATokenThatIsNot:
    """Absent, altered, malformed or expired: four failures and one answer."""

    async def test_no_authorization_header_is_refused(self, client: AsyncClient) -> None:
        """Anonymous is a 401 and not a 403: nothing was presented to reject."""
        response = await client.get(_ME)

        assert response.status_code == 401

    async def test_a_tampered_token_is_refused(self, client: AsyncClient, juan: User) -> None:
        """Editing the claims and keeping the signature is the first thing anybody tries."""
        token = create_access_token(user_id=juan.id, full_name=juan.full_name)

        response = await client.get(_ME, headers=_bearer(_tampered(token)))

        assert response.status_code == 401

    async def test_a_string_that_is_not_a_token_is_refused(self, client: AsyncClient) -> None:
        """Garbage in the header is a 401, never a traceback that reaches the client as a 500."""
        response = await client.get(_ME, headers=_bearer("not-a-token"))

        assert response.status_code == 401

    async def test_an_expired_token_is_refused(self, client: AsyncClient, juan: User) -> None:
        """From the other side, and the case the frontend turns into its expiry notice."""
        response = await client.get(_ME, headers=_bearer(_expired_token(juan.id, juan.full_name)))

        assert response.status_code == 401

    @pytest.mark.parametrize(
        "header",
        [
            pytest.param({}, id="absent"),
            pytest.param({"Authorization": "Bearer not-a-token"}, id="malformed"),
            pytest.param({"Authorization": "not-even-a-scheme"}, id="no-scheme"),
        ],
    )
    async def test_every_refusal_carries_the_bearer_challenge(
        self, client: AsyncClient, header: dict[str, str]
    ) -> None:
        """The four failures answer alike, which is what the frontend's interceptor keys on."""
        response = await client.get(_ME, headers=header)

        assert response.status_code == 401
        assert response.headers["www-authenticate"] == "Bearer"

    async def test_the_refusals_say_the_same_thing(self, client: AsyncClient, juan: User) -> None:
        """Telling the four apart tells a caller which half of an attack worked."""
        token = create_access_token(user_id=juan.id, full_name=juan.full_name)

        absent = await client.get(_ME)
        tampered = await client.get(_ME, headers=_bearer(_tampered(token)))
        malformed = await client.get(_ME, headers=_bearer("not-a-token"))
        expired = await client.get(_ME, headers=_bearer(_expired_token(juan.id, juan.full_name)))

        bodies = [answer.json() for answer in (absent, tampered, malformed, expired)]
        assert bodies == [{"detail": "not authenticated"}] * 4

    async def test_a_refused_call_answers_nothing_about_the_user(
        self, client: AsyncClient, juan: User
    ) -> None:
        """An expired token carries a name in its payload; the refusal must not echo it back."""
        response = await client.get(_ME, headers=_bearer(_expired_token(juan.id, juan.full_name)))

        assert response.status_code == 401
        assert "Juan Perez" not in response.text
