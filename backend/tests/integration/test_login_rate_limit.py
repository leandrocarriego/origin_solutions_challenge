"""The attempt limit, over HTTP (RF-21 to RF-26).

The limit is counted on two keys at once -- the address the request came from and the username
that was typed -- and telling the two apart is most of the work of this file. Ten failures from
one address with ten different usernames fill only the address's count; ten failures for one
username from ten different addresses fill only the username's. A test that used the same address
*and* the same username would pass with either key implemented and neither.

Three things here are the ones that decide whether the control is real:

- **While the limit holds, nothing is verified** (RF-24): not the wrong password, not the right
  one. The point of the limit is to stop spending Argon2, which is the resource an attack burns.
- **A successful login clears both counts** (RF-25, RF-26), because whoever proved they know the
  password is not the guesser being counted.
- **The caller does not get to choose its own address.** `X-Forwarded-For` is written by whoever
  sends the request, so a limit keyed on it is a limit anybody opts out of with a header. The
  address comes from the transport, and these two tests are what keep it that way.

Time moves by hand, never with a `sleep`: a five-minute window would otherwise cost five minutes.
"""

from collections.abc import AsyncIterator, Iterator

import pytest
from httpx import ASGITransport, AsyncClient, Response
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_session
from app.main import app
from app.modules.auth.models import User
from app.modules.auth.service import LOGIN_MAX_ATTEMPTS, LOGIN_WINDOW
from app.ratelimit import SlidingWindowLimiter
from app.security import verify_password
from app.settings import get_settings
from tests.factories.user_factory import PASSWORD, UserFactory

_LOGIN = "/api/auth/login"
_SECRET = "a-signing-secret-of-at-least-32-chars"
_WINDOW_SECONDS = int(LOGIN_WINDOW.total_seconds())

_AN_ADDRESS = "203.0.113.7"
_ANOTHER_ADDRESS = "203.0.113.8"


class _Clock:
    """A hand-cranked replacement for the clock the limiter reads."""

    def __init__(self) -> None:
        """Start at zero; the assertions are about elapsed time."""
        self.seconds = 0.0

    def __call__(self) -> float:
        """Read the clock, the way `time.monotonic()` would."""
        return self.seconds

    def advance(self, seconds: float) -> None:
        """Move time forward, which is what nobody should be waiting for."""
        self.seconds += seconds


class _PasswordCheck:
    """The real `verify_password`, counting how many times the service reached for it."""

    def __init__(self) -> None:
        """Start at zero: what matters is the delta around one attempt."""
        self.calls = 0

    def __call__(self, password: str, stored: str) -> bool:
        """Verify for real, so the behaviour under test stays the behaviour."""
        self.calls += 1

        return verify_password(password, stored)


@pytest.fixture(autouse=True)
def signing_secret(monkeypatch: pytest.MonkeyPatch) -> Iterator[str]:
    """A usable `JWT_SECRET`: the successful attempts of this file have to issue a token."""
    get_settings.cache_clear()
    monkeypatch.setenv("JWT_SECRET", _SECRET)

    yield _SECRET

    get_settings.cache_clear()


@pytest.fixture(autouse=True)
def a_fresh_limiter(monkeypatch: pytest.MonkeyPatch) -> Iterator[SlidingWindowLimiter]:
    """Give each test its own counter, so one test's eleventh attempt is not the next one's."""
    limiter = SlidingWindowLimiter(limit=LOGIN_MAX_ATTEMPTS, window=LOGIN_WINDOW)
    monkeypatch.setattr("app.modules.auth.service._login_limiter", limiter)

    yield limiter


@pytest.fixture(autouse=True)
async def the_database_is_this_transaction(session: AsyncSession) -> AsyncIterator[None]:
    """Every request of the test runs inside the transaction that gets rolled back."""
    app.dependency_overrides[get_session] = lambda: session

    yield

    app.dependency_overrides.pop(get_session, None)


@pytest.fixture
async def juan(session: AsyncSession) -> User:
    """The demo user, so that "the right password" means something."""
    return await UserFactory.create(session, username="juan", full_name="Juan Perez")


@pytest.fixture
def clock(monkeypatch: pytest.MonkeyPatch) -> Iterator[_Clock]:
    """Replace `app.ratelimit._now`, so the window can pass inside a test."""
    hand_cranked = _Clock()
    monkeypatch.setattr("app.ratelimit._now", hand_cranked)

    yield hand_cranked


@pytest.fixture
def password_check(monkeypatch: pytest.MonkeyPatch) -> _PasswordCheck:
    """Count what reaching Argon2 costs, which is what RF-24 is protecting."""
    counted = _PasswordCheck()
    monkeypatch.setattr("app.modules.auth.service.verify_password", counted)

    return counted


async def _attempt(
    username: str,
    password: str,
    address: str = _AN_ADDRESS,
    headers: dict[str, str] | None = None,
) -> Response:
    """One login attempt, arriving from `address` the way the proxy presents it.

    A client per attempt, because the address is a property of the connection: it is the only
    way to say "the same user from another computer" without asking the caller to declare it.
    """
    transport = ASGITransport(app=app, client=(address, 51234))

    async with AsyncClient(transport=transport, base_url="http://test") as client:
        return await client.post(
            _LOGIN, json={"username": username, "password": password}, headers=headers
        )


class TestTheLimitOnOneAddress:
    """RF-21: ten failures from one place, and the next one is not answered."""

    async def test_the_eleventh_attempt_is_refused(self, juan: User) -> None:
        """Each failure uses a different username, so the count that fills is the address's."""
        for attempt in range(LOGIN_MAX_ATTEMPTS):
            await _attempt(f"nadie{attempt}", "otra-clave")

        refused = await _attempt("otro-mas", "otra-clave")

        assert refused.status_code == 429
        assert refused.json() == {"detail": "too many attempts"}

    async def test_the_refusal_says_how_long_to_wait(self, juan: User) -> None:
        """`Retry-After` is what tells the caller this is a wait and not a wall."""
        for attempt in range(LOGIN_MAX_ATTEMPTS):
            await _attempt(f"nadie{attempt}", "otra-clave")

        refused = await _attempt("otro-mas", "otra-clave")

        assert 0 < int(refused.headers["retry-after"]) <= _WINDOW_SECONDS

    async def test_another_address_is_not_affected(self, juan: User) -> None:
        """The limit is per address: one guesser must not lock everybody else out."""
        for attempt in range(LOGIN_MAX_ATTEMPTS):
            await _attempt(f"nadie{attempt}", "otra-clave")

        from_elsewhere = await _attempt("juan", PASSWORD, address=_ANOTHER_ADDRESS)

        assert from_elsewhere.status_code == 200


class TestTheLimitOnOneUserName:
    """RF-22: the same username guessed from everywhere is still the same target."""

    async def test_the_eleventh_attempt_for_that_user_is_refused(self, juan: User) -> None:
        """Each failure arrives from a different address, so only the username's count fills."""
        for attempt in range(LOGIN_MAX_ATTEMPTS):
            await _attempt("juan", "otra-clave", address=f"198.51.100.{attempt}")

        refused = await _attempt("juan", "otra-clave", address="198.51.100.200")

        assert refused.status_code == 429

    async def test_another_user_from_a_fresh_address_still_gets_in(self, juan: User) -> None:
        """The cost of this control is a targeted nuisance, and it stops there."""
        for attempt in range(LOGIN_MAX_ATTEMPTS):
            await _attempt("ana", "otra-clave", address=f"198.51.100.{attempt}")

        response = await _attempt("juan", PASSWORD, address="198.51.100.200")

        assert response.status_code == 200


class TestWhileTheLimitHoldsNothingIsChecked:
    """RF-24: the answer is the same whatever was typed, and Argon2 is never reached."""

    async def test_the_right_password_does_not_get_in_either(self, juan: User) -> None:
        """Somebody with the correct clave has to be told to wait, not let through."""
        for attempt in range(LOGIN_MAX_ATTEMPTS):
            await _attempt(f"nadie{attempt}", "otra-clave")

        refused = await _attempt("juan", PASSWORD)

        assert refused.status_code == 429

    async def test_the_answer_does_not_say_which_credential_was_wrong(self, juan: User) -> None:
        """Naming the failure would hand back exactly what the limit is withholding."""
        for attempt in range(LOGIN_MAX_ATTEMPTS):
            await _attempt(f"nadie{attempt}", "otra-clave")

        refused = await _attempt("juan", PASSWORD)

        assert refused.json()["detail"] != "invalid credentials"

    async def test_the_password_is_not_even_verified(
        self, juan: User, password_check: _PasswordCheck
    ) -> None:
        """The check is what an attack makes expensive, so the limit has to come first."""
        for attempt in range(LOGIN_MAX_ATTEMPTS):
            await _attempt(f"nadie{attempt}", "otra-clave")
        spent_so_far = password_check.calls

        await _attempt("juan", PASSWORD)

        assert password_check.calls == spent_so_far


class TestASuccessClearsWhatWasCounted:
    """RF-25 and RF-26: getting in resets both keys, and the count starts over."""

    async def test_nine_failures_for_a_user_then_a_success_and_nine_more(self, juan: User) -> None:
        """RF-25, isolated on the username: every attempt comes from a different address."""
        for attempt in range(LOGIN_MAX_ATTEMPTS - 1):
            await _attempt("juan", "otra-clave", address=f"198.51.100.{attempt}")

        entered = await _attempt("juan", PASSWORD, address="198.51.100.100")
        assert entered.status_code == 200

        for attempt in range(LOGIN_MAX_ATTEMPTS - 1):
            await _attempt("juan", "otra-clave", address=f"198.51.100.1{attempt}")
        after = await _attempt("juan", "otra-clave", address="198.51.100.200")

        assert after.status_code == 401

    async def test_nine_failures_from_an_address_then_a_success_and_nine_more(
        self, juan: User
    ) -> None:
        """RF-26, isolated on the address: the usernames all differ, only the address repeats."""
        for attempt in range(LOGIN_MAX_ATTEMPTS - 1):
            await _attempt(f"nadie{attempt}", "otra-clave")

        entered = await _attempt("juan", PASSWORD)
        assert entered.status_code == 200

        for attempt in range(LOGIN_MAX_ATTEMPTS - 1):
            await _attempt(f"otro{attempt}", "otra-clave")
        after = await _attempt("nadie-mas", "otra-clave")

        assert after.status_code == 401


class TestTheWaitLiftsItself:
    """The window slides shut on its own: no account is ever left needing to be unblocked."""

    async def test_once_the_window_has_passed_the_right_password_gets_in(
        self, juan: User, clock: _Clock
    ) -> None:
        """RF-21's other half, and the reason this is a wait and not a blocked account."""
        for attempt in range(LOGIN_MAX_ATTEMPTS):
            await _attempt(f"nadie{attempt}", "otra-clave")
        assert (await _attempt("juan", PASSWORD)).status_code == 429

        clock.advance(_WINDOW_SECONDS + 1)

        assert (await _attempt("juan", PASSWORD)).status_code == 200


class TestTheAddressIsNotTheCallersToChoose:
    """The half of the hardening that has to be a test, or it gets refactored away."""

    async def test_a_forged_forwarded_header_does_not_buy_a_fresh_count(self, juan: User) -> None:
        """Reading `X-Forwarded-For` in the application is opting out of the limit by header."""
        for attempt in range(LOGIN_MAX_ATTEMPTS):
            await _attempt(f"nadie{attempt}", "otra-clave")

        refused = await _attempt("juan", PASSWORD, headers={"X-Forwarded-For": "9.9.9.9"})

        assert refused.status_code == 429

    async def test_a_forged_forwarded_header_does_not_scatter_the_count(self, juan: User) -> None:
        """A different forged address per attempt must still add up to one count."""
        for attempt in range(LOGIN_MAX_ATTEMPTS):
            await _attempt(
                f"nadie{attempt}",
                "otra-clave",
                headers={"X-Forwarded-For": f"9.9.9.{attempt}"},
            )

        refused = await _attempt("juan", PASSWORD)

        assert refused.status_code == 429
