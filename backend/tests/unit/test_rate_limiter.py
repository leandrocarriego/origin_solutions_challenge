"""The counter behind the attempt limit (RF-21, RF-22).

It counts events per key over a sliding window and knows nothing else: not what a login is, not
what a username is. That is the whole contract, and it is why the same class can later give
`002` and `003` a ceiling of their own.

Two properties are worth more than the rest. The window **slides**: it is the last five minutes
and not a bucket that empties at once, so insisting does not shorten the wait. And the number of
keys has a **ceiling**: a counter that grows with every distinct key is a memory exhaustion
anybody can ask for -- ten thousand invented addresses -- which is the same class of failure the
limiter exists to stop (OWASP API4).

Time is moved by hand. A window that can only be observed by waiting for it is a window nobody
tests, so `app.ratelimit` reads the clock through a module-level `_now()` and this suite cranks
it. There is no `sleep` here, and there must never be one.
"""

from collections.abc import Iterator
from datetime import timedelta

import pytest

from app.ratelimit import SlidingWindowLimiter

_WINDOW = timedelta(minutes=5)
_WINDOW_SECONDS = int(_WINDOW.total_seconds())
_KEY = "login:ip:203.0.113.7"
_OTHER_KEY = "login:user:juan"


class _Clock:
    """A hand-cranked replacement for the monotonic clock the limiter reads."""

    def __init__(self) -> None:
        """Start at zero: every assertion here is about elapsed time, not wall time."""
        self.seconds = 0.0

    def __call__(self) -> float:
        """Read the clock, the way `time.monotonic()` would."""
        return self.seconds

    def advance(self, seconds: float) -> None:
        """Move time forward, which is the one thing a real clock will not do on request."""
        self.seconds += seconds


@pytest.fixture
def clock(monkeypatch: pytest.MonkeyPatch) -> Iterator[_Clock]:
    """Replace `app.ratelimit._now`, so five minutes cost no five minutes."""
    hand_cranked = _Clock()
    monkeypatch.setattr("app.ratelimit._now", hand_cranked)

    yield hand_cranked


def _limiter(limit: int = 10, max_keys: int = 10_000) -> SlidingWindowLimiter:
    """A limiter with this project's window and whatever limit the test is about."""
    return SlidingWindowLimiter(limit=limit, window=_WINDOW, max_keys=max_keys)


class TestTheWindowFills:
    """Up to the limit nothing happens; at the limit the key is spent."""

    def test_a_key_nobody_touched_is_not_exceeded(self, clock: _Clock) -> None:
        """The default answer is "go ahead": the limiter is a brake, not a gate."""
        limiter = _limiter()

        exceeded = limiter.is_exceeded(_KEY)

        assert exceeded is False

    def test_one_hit_short_of_the_limit_is_still_allowed(self, clock: _Clock) -> None:
        """Nine bad attempts are a person typing badly, and they still get a tenth."""
        limiter = _limiter(limit=10)

        for _ in range(9):
            limiter.hit(_KEY)

        assert limiter.is_exceeded(_KEY) is False

    def test_the_limit_itself_is_exceeded(self, clock: _Clock) -> None:
        """Ten in the window is the line: what comes after it is refused (RF-21)."""
        limiter = _limiter(limit=10)

        for _ in range(10):
            limiter.hit(_KEY)

        assert limiter.is_exceeded(_KEY) is True

    def test_each_key_is_counted_on_its_own(self, clock: _Clock) -> None:
        """The address and the username are two counters, not one (RF-21, RF-22)."""
        limiter = _limiter(limit=2)

        limiter.hit(_KEY)
        limiter.hit(_KEY)

        assert limiter.is_exceeded(_KEY) is True
        assert limiter.is_exceeded(_OTHER_KEY) is False


class TestTheWindowSlides:
    """It is the last five minutes, not a bucket that empties on a schedule."""

    def test_once_the_window_has_passed_the_key_is_clean(self, clock: _Clock) -> None:
        """The wait lifts itself: nobody has to unblock anybody (spec, business rules)."""
        limiter = _limiter(limit=2)
        limiter.hit(_KEY)
        limiter.hit(_KEY)

        clock.advance(_WINDOW_SECONDS + 1)

        assert limiter.is_exceeded(_KEY) is False

    def test_only_the_hits_that_left_the_window_are_forgotten(self, clock: _Clock) -> None:
        """Sliding, not resetting: the hits still inside the window keep counting."""
        limiter = _limiter(limit=3)
        limiter.hit(_KEY)
        clock.advance(100)
        limiter.hit(_KEY)
        clock.advance(100)
        limiter.hit(_KEY)
        assert limiter.is_exceeded(_KEY) is True

        # The first hit is now older than the window; the other two are not.
        clock.advance(_WINDOW_SECONDS - 199)

        assert limiter.is_exceeded(_KEY) is False
        limiter.hit(_KEY)
        assert limiter.is_exceeded(_KEY) is True

    def test_retry_after_is_the_wait_until_the_oldest_hit_falls_out(self, clock: _Clock) -> None:
        """It is what the 429 puts in `Retry-After`, so it has to be the real wait (RF-21)."""
        limiter = _limiter(limit=3)
        limiter.hit(_KEY)
        clock.advance(10)
        limiter.hit(_KEY)
        clock.advance(10)
        limiter.hit(_KEY)

        wait = limiter.retry_after(_KEY)

        # The oldest hit happened 20 seconds ago and leaves the window 300 seconds after that.
        assert wait == _WINDOW_SECONDS - 20

    def test_insisting_does_not_shorten_the_wait(self, clock: _Clock) -> None:
        """Hits made while the key is spent count too: keep guessing, stay out."""
        limiter = _limiter(limit=2)
        limiter.hit(_KEY)
        clock.advance(1)
        limiter.hit(_KEY)

        # Two more attempts just before the first two leave the window.
        clock.advance(_WINDOW_SECONDS - 2)
        limiter.hit(_KEY)
        clock.advance(1)
        limiter.hit(_KEY)
        clock.advance(2)

        assert limiter.is_exceeded(_KEY) is True


class TestResetting:
    """What a successful login does to the count it had accumulated (RF-25, RF-26)."""

    def test_reset_empties_the_key(self, clock: _Clock) -> None:
        """Whoever proved they know the password is not the attacker being counted."""
        limiter = _limiter(limit=2)
        limiter.hit(_KEY)
        limiter.hit(_KEY)

        limiter.reset(_KEY)

        assert limiter.is_exceeded(_KEY) is False

    def test_reset_leaves_the_other_keys_alone(self, clock: _Clock) -> None:
        """One user getting in does not clear the count of the address that guessed at another."""
        limiter = _limiter(limit=1)
        limiter.hit(_KEY)
        limiter.hit(_OTHER_KEY)

        limiter.reset(_KEY)

        assert limiter.is_exceeded(_OTHER_KEY) is True

    def test_resetting_a_key_that_was_never_hit_is_not_an_error(self, clock: _Clock) -> None:
        """The first login of the day resets two keys that do not exist yet."""
        limiter = _limiter()

        limiter.reset(_KEY)

        assert limiter.is_exceeded(_KEY) is False


class TestTheNumberOfKeysHasACeiling:
    """`max_keys` is not an implementation detail: without it the limiter is the vulnerability."""

    def test_past_the_ceiling_the_oldest_key_is_dropped(self, clock: _Clock) -> None:
        """Ten thousand invented addresses must cost bounded memory, not unbounded."""
        limiter = _limiter(limit=1, max_keys=3)
        limiter.hit("login:ip:first")
        assert limiter.is_exceeded("login:ip:first") is True

        for key in ("login:ip:second", "login:ip:third", "login:ip:fourth"):
            clock.advance(1)
            limiter.hit(key)

        assert limiter.is_exceeded("login:ip:first") is False

    def test_the_keys_that_survive_are_the_recent_ones(self, clock: _Clock) -> None:
        """Evicting is the price of the ceiling; evicting what is in use would break the limit."""
        limiter = _limiter(limit=1, max_keys=3)

        for key in ("login:ip:first", "login:ip:second", "login:ip:third", "login:ip:fourth"):
            clock.advance(1)
            limiter.hit(key)

        assert limiter.is_exceeded("login:ip:fourth") is True
        assert limiter.is_exceeded("login:ip:third") is True

    def test_an_expired_key_is_dropped_before_a_live_one(self, clock: _Clock) -> None:
        """Making room starts with the keys whose window is already over."""
        limiter = _limiter(limit=1, max_keys=2)
        limiter.hit("login:ip:stale")

        clock.advance(_WINDOW_SECONDS + 1)
        limiter.hit("login:ip:live")
        limiter.hit("login:ip:newest")

        assert limiter.is_exceeded("login:ip:live") is True
        assert limiter.is_exceeded("login:ip:newest") is True
