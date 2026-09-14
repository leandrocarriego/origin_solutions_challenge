"""POST /api/auth/login, against the real table (RF-03, RF-04, RF-06, RF-11, RF-14, RF-15).

The unit tests of the service fix the decision; this file fixes the answer: the status, the body,
the headers, and that `username` really is matched case-insensitively in SQL and not only in the
service that lowercases it.

Two of these are security assertions and not shape assertions:

- **The unknown user and the wrong password produce the same response**, down to the headers
  (RF-06). Comparing bodies is not enough: a `WWW-Authenticate` on one and not the other tells
  the caller which username exists.
- **Nothing on the way out carries the clave** (RF-11): not the body, not the token's payload,
  not a log line. This is the one feature of the project that handles key material.
"""

import base64
import json
from collections.abc import AsyncIterator, Iterator
from typing import Any

import pytest
from httpx import ASGITransport, AsyncClient, Headers
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_session
from app.main import app
from app.modules.auth.models import User
from app.modules.auth.service import LOGIN_MAX_ATTEMPTS, LOGIN_WINDOW
from app.ratelimit import SlidingWindowLimiter
from app.security import ACCESS_TOKEN_TTL
from app.settings import get_settings
from tests.factories.user_factory import PASSWORD, UserFactory

_LOGIN = "/api/auth/login"
_SECRET = "a-signing-secret-of-at-least-32-chars"

# Headers that differ between two identical responses for reasons nobody decided. The request id
# is one per request by definition (ADR-009), and it says nothing about the credential.
_INCIDENTAL_HEADERS = frozenset({"date", "server", "x-request-id"})


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
async def juan(session: AsyncSession) -> User:
    """The demo user of the README, the one whose name the header shows."""
    return await UserFactory.create(session, username="juan", full_name="Juan Perez")


def _comparable(headers: Headers) -> dict[str, str]:
    """The headers of a response, minus the ones nobody chose."""
    return {
        name: value for name, value in headers.items() if name.lower() not in _INCIDENTAL_HEADERS
    }


def _payload_of(token: str) -> dict[str, Any]:
    """The claims of a token, read without verifying: this is about what was put inside."""
    segment = token.split(".")[1]
    padded = segment + "=" * (-len(segment) % 4)
    claims: dict[str, Any] = json.loads(base64.urlsafe_b64decode(padded))

    return claims


class TestACredentialThatIsGood:
    """RF-03: what the screen needs to store a session and paint the header."""

    async def test_it_answers_200(self, client: AsyncClient, juan: User) -> None:
        """The credentials of the seed get in, which is what the README promises."""
        response = await client.post(_LOGIN, json={"username": "juan", "password": PASSWORD})

        assert response.status_code == 200

    async def test_it_answers_a_bearer_token(self, client: AsyncClient, juan: User) -> None:
        """`token_type` is what the client puts in front of the token on every later request."""
        response = await client.post(_LOGIN, json={"username": "juan", "password": PASSWORD})

        body = response.json()
        assert body["token_type"] == "bearer"
        assert body["access_token"]

    async def test_the_token_is_issued_for_the_user_that_logged_in(
        self, client: AsyncClient, juan: User
    ) -> None:
        """The `sub` is the identity every protected route will read (Article III)."""
        response = await client.post(_LOGIN, json={"username": "juan", "password": PASSWORD})

        claims = _payload_of(response.json()["access_token"])
        assert claims["sub"] == str(juan.id)

    async def test_it_says_when_the_session_expires(self, client: AsyncClient, juan: User) -> None:
        """`expires_in` is derived from the constant, so the frontend holds no copy of it."""
        response = await client.post(_LOGIN, json={"username": "juan", "password": PASSWORD})

        assert response.json()["expires_in"] == int(ACCESS_TOKEN_TTL.total_seconds())

    async def test_it_answers_the_full_name_and_not_the_username(
        self, client: AsyncClient, juan: User
    ) -> None:
        """RF-08: the header reads `Usuario: Juan Perez`, never `Usuario: juan`."""
        response = await client.post(_LOGIN, json={"username": "juan", "password": PASSWORD})

        assert response.json()["full_name"] == "Juan Perez"

    @pytest.mark.parametrize("typed", ["juan", "Juan", "JUAN", "jUaN"])
    async def test_the_username_is_matched_whatever_the_case(
        self, client: AsyncClient, juan: User, typed: str
    ) -> None:
        """RF-14 in SQL: the column is not case-insensitive, so the query has to be."""
        response = await client.post(_LOGIN, json={"username": typed, "password": PASSWORD})

        assert response.status_code == 200


class TestACredentialThatIsNot:
    """RF-04, RF-05, RF-06: one answer, whatever went wrong."""

    async def test_a_wrong_password_answers_401(self, client: AsyncClient, juan: User) -> None:
        """The screen turns this into `usuario o clave invalida`; the API stays in English."""
        response = await client.post(_LOGIN, json={"username": "juan", "password": "otra-clave"})

        assert response.status_code == 401
        assert response.json() == {"detail": "invalid credentials"}

    async def test_the_refusal_carries_the_bearer_challenge(
        self, client: AsyncClient, juan: User
    ) -> None:
        """The same header every other 401 of the API answers with."""
        response = await client.post(_LOGIN, json={"username": "juan", "password": "otra-clave"})

        assert response.headers["www-authenticate"] == "Bearer"

    async def test_the_password_is_case_sensitive(self, client: AsyncClient, juan: User) -> None:
        """RF-15: the username folds case, the clave does not."""
        response = await client.post(
            _LOGIN, json={"username": "juan", "password": PASSWORD.upper()}
        )

        assert response.status_code == 401

    async def test_an_unknown_user_answers_exactly_like_a_wrong_password(
        self, client: AsyncClient, juan: User
    ) -> None:
        """RF-06: status, body and headers identical, or the difference enumerates usernames."""
        unknown = await client.post(_LOGIN, json={"username": "nadie", "password": PASSWORD})
        wrong = await client.post(_LOGIN, json={"username": "juan", "password": "otra-clave"})

        assert unknown.status_code == wrong.status_code
        assert unknown.json() == wrong.json()
        assert _comparable(unknown.headers) == _comparable(wrong.headers)


class TestNothingOnTheWayOutCarriesTheClave:
    """RF-11, at the only endpoint of the project that is handed a password."""

    async def test_the_successful_answer_does_not_contain_it(
        self, client: AsyncClient, juan: User
    ) -> None:
        """Not in a field, not in an echo of the request."""
        response = await client.post(_LOGIN, json={"username": "juan", "password": PASSWORD})

        assert PASSWORD not in response.text

    async def test_the_token_does_not_carry_it(self, client: AsyncClient, juan: User) -> None:
        """A JWT payload is base64, not encryption: whatever is in it is readable."""
        response = await client.post(_LOGIN, json={"username": "juan", "password": PASSWORD})

        assert PASSWORD not in json.dumps(_payload_of(response.json()["access_token"]))

    async def test_the_answer_never_carries_the_stored_hash_either(
        self, client: AsyncClient, juan: User
    ) -> None:
        """A hash in a response is still the material of an offline attack (API3, BOPLA)."""
        response = await client.post(_LOGIN, json={"username": "juan", "password": PASSWORD})

        assert "argon2" not in response.text

    async def test_a_rejected_attempt_does_not_echo_it(
        self, client: AsyncClient, juan: User
    ) -> None:
        """The failure path is where a helpful error message would repeat what was typed."""
        response = await client.post(
            _LOGIN, json={"username": "juan", "password": "clave-mal-tipeada"}
        )

        assert "clave-mal-tipeada" not in response.text

    async def test_the_logs_of_a_rejected_attempt_do_not_carry_it(
        self, client: AsyncClient, juan: User, captured_logs: list[str]
    ) -> None:
        """A clave in a log defeats the hashing of the column that stores it (RF-10)."""
        await client.post(_LOGIN, json={"username": "juan", "password": "clave-mal-tipeada"})

        assert "clave-mal-tipeada" not in "\n".join(captured_logs)


class TestABodyThatIsNotOne:
    """422 is the backstop: the screen validates the empty fields before asking (RF-13)."""

    @pytest.mark.parametrize(
        "payload",
        [
            pytest.param({"password": PASSWORD}, id="no-username"),
            pytest.param({"username": "juan"}, id="no-password"),
            pytest.param({"username": "", "password": PASSWORD}, id="empty-username"),
            pytest.param({"username": "juan", "password": ""}, id="empty-password"),
            pytest.param({"username": "j" * 51, "password": PASSWORD}, id="username-too-long"),
            pytest.param({"username": "juan", "password": "p" * 129}, id="password-too-long"),
            pytest.param(
                {"username": "juan", "password": PASSWORD, "remember": True}, id="extra-field"
            ),
        ],
    )
    async def test_it_is_refused_before_anything_is_verified(
        self, client: AsyncClient, juan: User, payload: dict[str, Any]
    ) -> None:
        """A body of a megabyte must not reach Argon2, and an extra field is API3 (BOPLA)."""
        response = await client.post(_LOGIN, json=payload)

        assert response.status_code == 422


class TestTheRouteIsPublic:
    """Requiring a credential to ask for one does not close."""

    async def test_it_answers_without_an_authorization_header(
        self, client: AsyncClient, juan: User
    ) -> None:
        """The answer is about the credential in the body, never about a missing token."""
        response = await client.post(_LOGIN, json={"username": "juan", "password": PASSWORD})

        assert response.status_code == 200

    async def test_a_bad_credential_is_not_reported_as_a_missing_session(
        self, client: AsyncClient, juan: User
    ) -> None:
        """The frontend tells the two 401s apart by the body: the form, or the session."""
        response = await client.post(_LOGIN, json={"username": "juan", "password": "otra-clave"})

        assert response.json()["detail"] != "not authenticated"
