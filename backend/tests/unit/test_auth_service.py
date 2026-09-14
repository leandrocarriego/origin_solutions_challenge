"""What authenticating decides, before HTTP is involved (RF-06, RF-14, RF-15, RF-24).

The repository is stubbed here on purpose: what is under test is the decision, not the SQL. That
the lookup is case-insensitive *in the database* is a different claim, and it is asserted against
a real table in `tests/integration/test_login.py`. What this file fixes is that the service hands
the repository a normalised username, verifies the password as typed, and tells the two failures
apart from nobody.

Three properties are the ones a well-meaning refactor breaks:

- **An unknown user and a wrong password are the same event** (RF-06). Same exception, same
  message. Saying "no such user" confirms which usernames are real.
- **The unknown user is still checked against a hash.** Returning early would answer in a
  fraction of the time, and timing enumerates users just as well as a message does.
- **The attempt limit is consulted before anything is verified** (RF-24). Argon2 is expensive by
  design, so a limit paid with a hash computation protects the wrong resource.
"""

from collections.abc import Iterator
from datetime import timedelta
from typing import cast

import pytest
from sqlalchemy.ext.asyncio import AsyncSession

from app.errors import AuthenticationError, DomainError, RateLimitedError
from app.modules.auth.models import User
from app.modules.auth.schemas import AuthenticatedUser
from app.modules.auth.service import (
    LOGIN_MAX_ATTEMPTS,
    LOGIN_WINDOW,
    authenticate,
)
from app.ratelimit import SlidingWindowLimiter
from app.security import hash_password, verify_password

PASSWORD = "una-clave-de-demo"
_PASSWORD_HASH = hash_password(PASSWORD)

_CLIENT_IP = "203.0.113.7"

# The repository is replaced in every test, so the session is never touched. It is passed anyway
# because the signature takes one: the service is the layer that has no business opening it.
_UNUSED_SESSION = cast(AsyncSession, object())


class _Repository:
    """Stand-in for `find_by_username`, which remembers what it was asked for."""

    def __init__(self, user: User | None) -> None:
        """Answer every lookup with the same row, or with nothing at all."""
        self.user = user
        self.asked_for: list[str] = []

    async def find_by_username(self, session: AsyncSession, username: str) -> User | None:
        """Record the username the service normalised, then answer with the fixed row."""
        self.asked_for.append(username)

        return self.user


class _PasswordCheck:
    """The real `verify_password`, counting how many times the service reached for it."""

    def __init__(self) -> None:
        """Start at zero: what matters is the delta around one attempt."""
        self.calls = 0

    def __call__(self, password: str, stored: str) -> bool:
        """Verify for real, so the behaviour under test stays the behaviour."""
        self.calls += 1

        return verify_password(password, stored)


def _juan() -> User:
    """The demo user, built in memory: no session is open in a unit test."""
    return User(id=1, username="juan", full_name="Juan Perez", password_hash=_PASSWORD_HASH)


@pytest.fixture(autouse=True)
def a_fresh_limiter(monkeypatch: pytest.MonkeyPatch) -> Iterator[SlidingWindowLimiter]:
    """Give each test its own counter.

    The service keeps one per process and it remembers, so without this the eleventh attempt of
    one test is the first refusal of the next -- and the order the tests run in would decide
    whether they pass.
    """
    limiter = SlidingWindowLimiter(limit=LOGIN_MAX_ATTEMPTS, window=LOGIN_WINDOW)
    monkeypatch.setattr("app.modules.auth.service._login_limiter", limiter)

    yield limiter


@pytest.fixture
def repository(monkeypatch: pytest.MonkeyPatch) -> _Repository:
    """A repository that finds the demo user, wired where the service consumes it."""
    stub = _Repository(user=_juan())
    monkeypatch.setattr("app.modules.auth.service.find_by_username", stub.find_by_username)

    return stub


@pytest.fixture
def no_such_user(monkeypatch: pytest.MonkeyPatch) -> _Repository:
    """A repository that finds nothing, for the half of RF-06 that has no row."""
    stub = _Repository(user=None)
    monkeypatch.setattr("app.modules.auth.service.find_by_username", stub.find_by_username)

    return stub


@pytest.fixture
def password_check(monkeypatch: pytest.MonkeyPatch) -> _PasswordCheck:
    """Count the calls to `verify_password`, which is the expensive step (RF-24)."""
    counted = _PasswordCheck()
    monkeypatch.setattr("app.modules.auth.service.verify_password", counted)

    return counted


async def _attempt(
    username: str = "juan", password: str = PASSWORD, client_ip: str = _CLIENT_IP
) -> AuthenticatedUser:
    """One authentication attempt, from the same address unless the test says otherwise."""
    return await authenticate(
        _UNUSED_SESSION, username=username, password=password, client_ip=client_ip
    )


class TestACredentialThatIsGood:
    """What the router gets back, and nothing more than that."""

    async def test_it_returns_the_identity_the_screen_needs(self, repository: _Repository) -> None:
        """The id for the token's `sub` and the full name for the header (RF-08)."""
        authenticated = await _attempt()

        assert authenticated == AuthenticatedUser(id=1, full_name="Juan Perez")

    async def test_it_returns_no_trace_of_the_password(self, repository: _Repository) -> None:
        """RF-11 at the layer that is the only one in the project holding key material."""
        authenticated = await _attempt()

        assert PASSWORD not in repr(authenticated)
        assert _PASSWORD_HASH not in repr(authenticated)


class TestWhatTheUserNameMeans:
    """Case folds on the username and never on the password (RF-14, RF-15)."""

    @pytest.mark.parametrize("typed", ["juan", "Juan", "JUAN", "jUaN"])
    async def test_the_username_reaches_the_repository_in_lower_case(
        self, repository: _Repository, typed: str
    ) -> None:
        """A phone capitalises the first letter on its own, and that is not a bad credential."""
        await _attempt(username=typed)

        assert repository.asked_for == ["juan"]

    @pytest.mark.parametrize("typed", ["juan", "Juan", "JUAN", "jUaN"])
    async def test_any_case_of_the_username_gets_in(
        self, repository: _Repository, typed: str
    ) -> None:
        """The four spellings are the same person (RF-14)."""
        authenticated = await _attempt(username=typed)

        assert authenticated.id == 1

    async def test_the_password_is_case_sensitive(self, repository: _Repository) -> None:
        """Relaxing the username is a convenience; relaxing the password removes entropy."""
        with pytest.raises(AuthenticationError):
            await _attempt(password=PASSWORD.upper())

    async def test_a_password_that_is_merely_close_does_not_get_in(
        self, repository: _Repository
    ) -> None:
        """Stating the obvious, because it is what everything else here rests on."""
        with pytest.raises(AuthenticationError):
            await _attempt(password=PASSWORD[:-1])


class TestTheTwoFailuresAreOneFailure:
    """RF-06: an unknown user and a wrong password are indistinguishable from outside."""

    async def test_an_unknown_user_raises_the_authentication_error(
        self, no_such_user: _Repository
    ) -> None:
        """No row is not a different outcome, it is the same one."""
        with pytest.raises(AuthenticationError):
            await _attempt(username="nadie")

    async def test_both_failures_raise_the_very_same_thing(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """Same type and same message: a subclass or an extra word is the leak."""
        unknown = _Repository(user=None)
        monkeypatch.setattr("app.modules.auth.service.find_by_username", unknown.find_by_username)
        with pytest.raises(AuthenticationError) as no_row:
            await _attempt(username="nadie")

        known = _Repository(user=_juan())
        monkeypatch.setattr("app.modules.auth.service.find_by_username", known.find_by_username)
        with pytest.raises(AuthenticationError) as bad_password:
            await _attempt(password="otra-clave")

        assert type(no_row.value) is type(bad_password.value)
        assert str(no_row.value) == str(bad_password.value)
        assert no_row.value.args == bad_password.value.args

    async def test_an_unknown_user_is_still_checked_against_a_hash(
        self, no_such_user: _Repository, password_check: _PasswordCheck
    ) -> None:
        """The decoy hash: answering in a fraction of the time enumerates users by timing."""
        with pytest.raises(AuthenticationError):
            await _attempt(username="nadie")

        assert password_check.calls == 1

    def test_the_failure_is_a_domain_error(self) -> None:
        """`main.py` registers the handler on the family, so membership is the contract."""
        assert issubclass(AuthenticationError, DomainError)
        assert issubclass(RateLimitedError, DomainError)


class TestNothingWrittenDownCarriesThePassword:
    """RF-10 and RF-11 where the only key material of the project passes through."""

    async def test_a_failed_attempt_logs_the_attempt_and_not_the_password(
        self, repository: _Repository, captured_logs: list[str]
    ) -> None:
        """A log line with the clave defeats the hashing of the column that stores it."""
        with pytest.raises(AuthenticationError):
            await _attempt(password="otra-clave-mal-tipeada")

        written = "\n".join(captured_logs)
        assert "otra-clave-mal-tipeada" not in written

    async def test_a_successful_attempt_logs_no_password_either(
        self, repository: _Repository, captured_logs: list[str]
    ) -> None:
        """The happy path is the one nobody reviews, and it holds the right password."""
        await _attempt()

        assert PASSWORD not in "\n".join(captured_logs)


class TestTheAttemptLimit:
    """RF-21 to RF-26, at the layer that owns the numbers."""

    def test_the_policy_is_ten_attempts_in_five_minutes(self) -> None:
        """The numbers belong to the module; the counting belongs to the kernel (SEC-04)."""
        assert LOGIN_MAX_ATTEMPTS == 10
        assert LOGIN_WINDOW == timedelta(minutes=5)

    async def test_the_attempt_after_the_limit_is_refused(self, repository: _Repository) -> None:
        """Ten failures spend the window; the eleventh attempt is not a credential check."""
        for _ in range(LOGIN_MAX_ATTEMPTS):
            with pytest.raises(AuthenticationError):
                await _attempt(password="otra-clave")

        with pytest.raises(RateLimitedError):
            await _attempt(password="otra-clave")

    async def test_even_the_right_password_is_refused(self, repository: _Repository) -> None:
        """RF-24: while the limit holds, what was typed does not matter."""
        for _ in range(LOGIN_MAX_ATTEMPTS):
            with pytest.raises(AuthenticationError):
                await _attempt(password="otra-clave")

        with pytest.raises(RateLimitedError):
            await _attempt(password=PASSWORD)

    async def test_the_right_password_is_not_even_verified(
        self, repository: _Repository, password_check: _PasswordCheck
    ) -> None:
        """The limit exists to stop spending Argon2, which is the resource an attack burns."""
        for _ in range(LOGIN_MAX_ATTEMPTS):
            with pytest.raises(AuthenticationError):
                await _attempt(password="otra-clave")
        spent_so_far = password_check.calls

        with pytest.raises(RateLimitedError):
            await _attempt(password=PASSWORD)

        assert password_check.calls == spent_so_far

    async def test_the_refusal_says_how_long_to_wait(self, repository: _Repository) -> None:
        """`retry_after_seconds` is all the 429 handler needs to write `Retry-After`."""
        for _ in range(LOGIN_MAX_ATTEMPTS):
            with pytest.raises(AuthenticationError):
                await _attempt(password="otra-clave")

        with pytest.raises(RateLimitedError) as refused:
            await _attempt(password=PASSWORD)

        assert 0 < refused.value.retry_after_seconds <= LOGIN_WINDOW.total_seconds()

    async def test_a_username_that_does_not_exist_is_counted_too(
        self, no_such_user: _Repository
    ) -> None:
        """Counting only real users would enumerate them by behaviour, which is RF-06 again.

        Each attempt comes from a different address, so the count that fills is the one keyed on
        the username and not the one keyed on the address (RF-22).
        """
        for attempt in range(LOGIN_MAX_ATTEMPTS):
            with pytest.raises(AuthenticationError):
                await _attempt(username="nadie", client_ip=f"198.51.100.{attempt}")

        with pytest.raises(RateLimitedError):
            await _attempt(username="nadie", client_ip="198.51.100.200")
