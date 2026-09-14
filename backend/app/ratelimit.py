"""A sliding-window counter of events per key. Kernel file: it imports no module (GEN-03).

It counts events and knows nothing else -- not what they mean, not what the keys stand for. The
keys are strings whoever sets the policy composes, and the numbers are that caller's too. That is
what lets the same class give another module a ceiling of its own later without having to teach it
a second vocabulary first.

Two properties are the ones that make it a control and not a decoration.

The window **slides**. Each key keeps the instants of its own events and the ones that left the
window are discarded on read, so it is the last `window` and not a bucket that empties on a
schedule -- insisting does not shorten the wait.

The number of keys has a **ceiling**. A counter that grows with every distinct key is a memory
exhaustion anybody can ask for -- ten thousand invented addresses -- which is the same class of
failure the counter exists to stop (OWASP API4).

The clock is read through `_now()` instead of inline, because a window that can only be observed
by waiting five minutes for it is a window nobody tests.
"""

import math
import time
from collections import OrderedDict, deque
from datetime import timedelta


def _now() -> float:
    """Read the clock the windows are measured against.

    Monotonic and not wall time: a window measured against a clock that can move backwards
    reopens itself the moment NTP corrects the host.
    """
    return time.monotonic()


class SlidingWindowLimiter:
    """How many events a key saw in the last `window`, and whether that is already too many."""

    def __init__(self, limit: int, window: timedelta, max_keys: int = 10_000) -> None:
        """Count up to `limit` events per key over `window`, across at most `max_keys` keys."""
        self._limit = limit
        self._window = window.total_seconds()
        self._max_keys = max_keys
        # Ordered by when each key was last hit, which is what makes eviction pick the coldest.
        self._events: OrderedDict[str, deque[float]] = OrderedDict()

    def hit(self, key: str) -> None:
        """Record one event for this key, now.

        It records and judges nothing: whether an event is worth recording at all is the policy
        of whoever calls, and a caller that asks `is_exceeded` first records none while the key
        is spent. That is what holds the wait still -- `retry_after` counts down to the moment
        the oldest event still inside the window leaves it, so once a key is spent the countdown
        runs from the event that spent it, and nothing afterwards shortens it or pushes it back.
        """
        self._make_room_for(key)
        self._events.setdefault(key, deque()).append(_now())
        self._events.move_to_end(key)

    def is_exceeded(self, key: str) -> bool:
        """Whether this key has already used up its window.

        The default answer is no: this is a brake and not a gate, so a key nobody touched
        passes.
        """
        return len(self._inside_the_window(key)) >= self._limit

    def retry_after(self, key: str) -> int:
        """Seconds until the oldest event still counted leaves the window.

        Which is when there is room for one more, and therefore what a `Retry-After` header can
        honestly promise. Rounded up, so it is never a wait of zero that is not over yet.
        """
        events = self._inside_the_window(key)
        if not events:
            return 0

        return max(0, math.ceil(self._window - (_now() - events[0])))

    def reset(self, key: str) -> None:
        """Forget this key entirely, and say nothing about any other."""
        self._events.pop(key, None)

    def _inside_the_window(self, key: str) -> deque[float]:
        """This key's events, having dropped the ones the window has moved past."""
        events = self._events.get(key)
        if events is None:
            return deque()

        horizon = _now() - self._window
        while events and events[0] <= horizon:
            events.popleft()

        return events

    def _make_room_for(self, key: str) -> None:
        """Keep the number of keys under the ceiling before one more is added.

        Expired keys go first, because dropping those costs nothing; only if that is not enough
        does a live key get evicted, and then it is the one hit longest ago. The walk over every
        key is paid only while the ceiling is reached, never on a normal hit.
        """
        if key in self._events or len(self._events) < self._max_keys:
            return

        for known in list(self._events):
            if not self._inside_the_window(known):
                del self._events[known]

        while len(self._events) >= self._max_keys:
            self._events.popitem(last=False)
