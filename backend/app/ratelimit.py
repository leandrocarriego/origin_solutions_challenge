"""A sliding-window counter of events per key."""

import math
import time
from collections import OrderedDict, deque
from datetime import timedelta


def _now() -> float:
    """Read the clock the windows are measured against."""
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
        """Record one event for this key, now."""
        self._make_room_for(key)

        self._events.setdefault(key, deque()).append(_now())
        self._events.move_to_end(key)

    def is_exceeded(self, key: str) -> bool:
        """Whether this key has already used up its window."""
        return len(self._inside_the_window(key)) >= self._limit

    def retry_after(self, key: str) -> int:
        """Seconds until the oldest event still counted leaves the window."""
        events = self._inside_the_window(key)

        if not events:
            return 0

        # Rounded up, so it is never a wait of zero that is not over yet.
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
        """Keep the number of keys under the ceiling before one more is added."""
        if key in self._events or len(self._events) < self._max_keys:
            return

        # Drop expired keys first, because that costs nothing.
        for known in list(self._events):
            if not self._inside_the_window(known):
                del self._events[known]

        while len(self._events) >= self._max_keys:
            self._events.popitem(last=False)
