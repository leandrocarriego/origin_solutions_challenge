"""The session token: what it claims, and what it refuses (ADR-004, RF-16).

A token is the whole authentication of this system in one string, so most of this file is about
refusals. The one that matters most is the algorithm: a decode that does not pin `HS256` accepts
a token whose header says `alg: none`, and at that point the signature is decoration and anybody
can mint an identity. The same goes for a token signed with another HMAC size, which is the
version of the trick that looks legitimate.

The expired token is built with an `exp` in the past rather than by waiting an hour. Sixty
minutes of test run is not a test.

And the secret: an empty one, or one short enough to brute-force offline, is not a configuration
mistake the process can work around -- it is a refusal (`RuntimeError`), never a token signed
with `""`.
"""

import base64
import json
from collections.abc import Iterator
from datetime import UTC, datetime, timedelta
from typing import Any

import jwt
import pytest
from fastapi import HTTPException
from fastapi.security import HTTPAuthorizationCredentials

from app.security import ACCESS_TOKEN_TTL, CurrentUser, create_access_token, get_current_user
from app.settings import Settings, get_settings

# Long enough to be a signing key and recognisable enough that a leak reads as a leak.
_SECRET = "a-signing-secret-of-at-least-32-chars"
_USER_ID = 7
_FULL_NAME = "Juan Perez"


@pytest.fixture(autouse=True)
def _settings_are_read_fresh() -> Iterator[None]:
    """Drop the settings cache around every test, so one test's secret is not the next one's."""
    get_settings.cache_clear()

    yield

    get_settings.cache_clear()


def _use_secret(monkeypatch: pytest.MonkeyPatch, secret: str) -> None:
    """Point the process at one signing secret, read the way a request would read it."""
    monkeypatch.setenv("JWT_SECRET", secret)
    get_settings.cache_clear()


@pytest.fixture
def signing_secret(monkeypatch: pytest.MonkeyPatch) -> str:
    """A usable signing secret, which is the precondition of everything that is not a refusal."""
    _use_secret(monkeypatch, _SECRET)

    return _SECRET


def _presented(token: str) -> HTTPAuthorizationCredentials:
    """What FastAPI hands the dependency for an `Authorization: Bearer <token>` header."""
    return HTTPAuthorizationCredentials(scheme="Bearer", credentials=token)


def _claims_of(token: str) -> dict[str, Any]:
    """Read the payload without verifying anything, to assert on what was put in it."""
    payload = token.split(".")[1]
    padded = payload + "=" * (-len(payload) % 4)
    decoded: dict[str, Any] = json.loads(base64.urlsafe_b64decode(padded))

    return decoded


def _segment(payload: dict[str, Any]) -> str:
    """One base64url segment of a token, unpadded, the way JWT writes them."""
    raw = json.dumps(payload, separators=(",", ":")).encode()

    return base64.urlsafe_b64encode(raw).decode().rstrip("=")


def _unsigned_token(claims: dict[str, Any]) -> str:
    """A token whose header says `alg: none` and whose signature is empty.

    Hand-built instead of asked of the library, because a library that refuses to produce one
    would hide the case: what has to be tested is that *our* decode refuses to accept it.
    """
    return f"{_segment({'alg': 'none', 'typ': 'JWT'})}.{_segment(claims)}."


def _live_claims() -> dict[str, Any]:
    """Claims that are valid in every respect, for tests that break exactly one thing."""
    issued = datetime.now(tz=UTC)

    return {
        "sub": str(_USER_ID),
        "name": _FULL_NAME,
        "iat": int(issued.timestamp()),
        "exp": int((issued + ACCESS_TOKEN_TTL).timestamp()),
    }


class TestWhatTheTokenSays:
    """The claims the rest of the system reads off it."""

    def test_it_is_signed_with_hs256(self, signing_secret: str) -> None:
        """The algorithm is fixed, and the header is where a mismatch shows first."""
        token = create_access_token(user_id=_USER_ID, full_name=_FULL_NAME)

        header = jwt.get_unverified_header(token)

        assert header["alg"] == "HS256"

    def test_the_identity_is_the_user_id_in_sub(self, signing_secret: str) -> None:
        """`sub` is the only source of identity in the system (Article III)."""
        token = create_access_token(user_id=_USER_ID, full_name=_FULL_NAME)

        claims = _claims_of(token)

        assert claims["sub"] == str(_USER_ID)

    def test_it_carries_the_full_name_the_header_shows(self, signing_secret: str) -> None:
        """RF-08 is painted from the token, so the name travels with it and costs no request."""
        token = create_access_token(user_id=_USER_ID, full_name=_FULL_NAME)

        claims = _claims_of(token)

        assert claims["name"] == _FULL_NAME

    def test_a_session_lasts_sixty_minutes(self) -> None:
        """RF-16, as a constant: it is a security decision and not an operator's setting."""
        assert ACCESS_TOKEN_TTL == timedelta(minutes=60)

    def test_the_expiry_is_the_ttl_after_the_issue_time(self, signing_secret: str) -> None:
        """`exp` derived from `iat` and the constant, so the two cannot drift apart."""
        token = create_access_token(user_id=_USER_ID, full_name=_FULL_NAME)

        claims = _claims_of(token)

        assert claims["exp"] - claims["iat"] == int(ACCESS_TOKEN_TTL.total_seconds())


class TestATokenThatIsGood:
    """The happy path, which is the one line of the file that is not a refusal."""

    async def test_it_identifies_the_user_it_was_issued_for(self, signing_secret: str) -> None:
        """What every protected route receives, and the only place identity comes from."""
        token = create_access_token(user_id=_USER_ID, full_name=_FULL_NAME)

        identified = await get_current_user(_presented(token))

        assert identified == CurrentUser(id=_USER_ID, full_name=_FULL_NAME)


class TestATokenThatIsNot:
    """Absent, altered, malformed or expired: four failures and one answer."""

    async def test_no_credentials_at_all_is_refused(self, signing_secret: str) -> None:
        """Anonymous is a 401 and not a 403: nothing was presented to reject."""
        with pytest.raises(HTTPException) as refused:
            await get_current_user(None)

        assert refused.value.status_code == 401

    async def test_a_tampered_signature_is_refused(self, signing_secret: str) -> None:
        """Editing the claims and keeping the signature is the first thing anybody tries."""
        token = create_access_token(user_id=_USER_ID, full_name=_FULL_NAME)
        last = token[-1]
        tampered = token[:-1] + ("a" if last != "a" else "b")

        with pytest.raises(HTTPException) as refused:
            await get_current_user(_presented(tampered))

        assert refused.value.status_code == 401

    async def test_a_string_that_is_not_a_token_is_refused(self, signing_secret: str) -> None:
        """Garbage in the header is a 401, never a traceback the client gets as a 500."""
        with pytest.raises(HTTPException) as refused:
            await get_current_user(_presented("not-a-token"))

        assert refused.value.status_code == 401

    async def test_an_expired_token_is_refused(self, signing_secret: str) -> None:
        """RF-16 from the other side: after sixty minutes the token stops working."""
        expired_at = datetime.now(tz=UTC) - timedelta(minutes=5)
        claims = {
            "sub": str(_USER_ID),
            "name": _FULL_NAME,
            "iat": int((expired_at - ACCESS_TOKEN_TTL).timestamp()),
            "exp": int(expired_at.timestamp()),
        }
        token = jwt.encode(claims, _SECRET, algorithm="HS256")

        with pytest.raises(HTTPException) as refused:
            await get_current_user(_presented(token))

        assert refused.value.status_code == 401

    async def test_every_refusal_carries_the_bearer_challenge(self, signing_secret: str) -> None:
        """The four failures answer alike, which is what the frontend's interceptor keys on."""
        with pytest.raises(HTTPException) as refused:
            await get_current_user(_presented("not-a-token"))

        assert (refused.value.headers or {})["WWW-Authenticate"] == "Bearer"


class TestTheAlgorithmIsPinned:
    """The classic JWT hole, and the reason `algorithms=["HS256"]` is written explicitly."""

    async def test_a_token_that_claims_to_need_no_signature_is_refused(
        self, signing_secret: str
    ) -> None:
        """`alg: none` accepted once is an identity anybody can mint for anybody."""
        token = _unsigned_token(_live_claims())

        with pytest.raises(HTTPException) as refused:
            await get_current_user(_presented(token))

        assert refused.value.status_code == 401

    async def test_a_token_signed_with_another_algorithm_is_refused(
        self, signing_secret: str
    ) -> None:
        """Same secret, different algorithm: valid HMAC, and still not our token."""
        token = jwt.encode(_live_claims(), _SECRET, algorithm="HS512")

        with pytest.raises(HTTPException) as refused:
            await get_current_user(_presented(token))

        assert refused.value.status_code == 401

    async def test_a_token_without_an_expiry_is_refused(self, signing_secret: str) -> None:
        """A session that never ends cannot be accepted by omission: `exp` is required."""
        claims = {"sub": str(_USER_ID), "name": _FULL_NAME}
        token = jwt.encode(claims, _SECRET, algorithm="HS256")

        with pytest.raises(HTTPException) as refused:
            await get_current_user(_presented(token))

        assert refused.value.status_code == 401


class TestTheSecretIsNotOptional:
    """An unusable signing secret is a refusal, never a token signed with something weaker."""

    def test_there_is_no_default_secret_to_ship_with(self) -> None:
        """SEC-05: a committed development secret is production's secret the day it is forgotten."""
        assert Settings.model_fields["jwt_secret"].default == ""

    def test_signing_with_no_secret_refuses(self, monkeypatch: pytest.MonkeyPatch) -> None:
        """A deployment that forgot the variable must break loudly, not sign with `""`."""
        _use_secret(monkeypatch, "")

        with pytest.raises(RuntimeError):
            create_access_token(user_id=_USER_ID, full_name=_FULL_NAME)

    def test_signing_with_a_short_secret_refuses(self, monkeypatch: pytest.MonkeyPatch) -> None:
        """HS256 signed with a guessable key is offline brute force on any captured token."""
        _use_secret(monkeypatch, "x" * 31)

        with pytest.raises(RuntimeError):
            create_access_token(user_id=_USER_ID, full_name=_FULL_NAME)

    def test_thirty_two_characters_are_enough(self, monkeypatch: pytest.MonkeyPatch) -> None:
        """The boundary is stated, so the rule cannot quietly become "any non-empty string"."""
        _use_secret(monkeypatch, "x" * 32)

        assert create_access_token(user_id=_USER_ID, full_name=_FULL_NAME)

    async def test_verifying_with_no_secret_refuses_instead_of_rejecting(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """A broken deployment is not a bad token, and answering 401 would hide which it is."""
        _use_secret(monkeypatch, _SECRET)
        token = create_access_token(user_id=_USER_ID, full_name=_FULL_NAME)
        _use_secret(monkeypatch, "")

        with pytest.raises(RuntimeError):
            await get_current_user(_presented(token))
