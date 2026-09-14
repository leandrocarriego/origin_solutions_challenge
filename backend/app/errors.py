"""The domain errors any module raises, and the composition root translates (ERR-04).

Kernel file: it imports no module (GEN-03) and it imports nothing of the web framework. That
second half is the point of the file existing at all -- a domain error that dragged the transport
in with it could not be raised from a service, which is the only place it is meant to come from.

`main.py` registers one handler per type, so the type *is* the status code. Two failures that
must answer alike are therefore one exception and not two.
"""


class DomainError(Exception):
    """Something the business rules refuse. Every error below is one of these."""


class AuthenticationError(DomainError):
    """The credential presented does not establish a session.

    One exception for an unknown user and for a wrong password (RF-06), with the message fixed
    here so the two cannot drift apart: two messages are two responses, and the difference
    between them is what tells a caller which usernames are real.
    """

    def __init__(self) -> None:
        """Carry the one message both failures answer with."""
        super().__init__("invalid credentials")


class RateLimitedError(DomainError):
    """Too many attempts inside the window, so this one is not answered at all."""

    def __init__(self, retry_after_seconds: int) -> None:
        """Carry the wait, which is all the 429 handler needs to write `Retry-After`."""
        super().__init__("too many attempts")
        self.retry_after_seconds = retry_after_seconds


class UnknownSymbolError(DomainError):
    """The symbol is not one that can be added today: absent from the catalogue, or delisted.

    One exception for the two, and that is deliberate. A caller can only choose from what the
    autocomplete suggested, so both mean the same thing to the only screen that asks -- "that
    cannot be added" -- and two exceptions would be two answers for a decision nobody makes.

    It lives here rather than inside `favorites` for the same reason `AuthenticationError` does:
    `main.py` has to import it to register the handler, and an exception exported through a
    module's `__all__` would be public contract for a consumer that is not a module.
    """

    def __init__(self) -> None:
        """Carry the one message the 404 handler answers with."""
        super().__init__("unknown symbol")


class QuoteRangeInvalid(DomainError):
    """The window asked for is not a window: `desde` is not before `hasta` (RF-41).

    Equal and inverted are the same refusal, and half a range -- one of the two written and the
    other missing -- is the same one again: read as `Tiempo Real` it would quietly chart today
    instead of what was asked for, which looks like a bug in the chart and is a bug in the
    contract.
    """

    def __init__(self) -> None:
        """Carry the one message the 422 handler answers with."""
        super().__init__("range invalid")


class QuoteRangeTooLong(DomainError):
    """The window is longer than that interval can serve (RF-42 to RF-44).

    It carries the interval and its cap because the text the person reads names both (RF-45),
    and the caps live in the service and nowhere else: a browser with its own copy would be one
    business rule written twice, and one of the two would go stale without anybody noticing.
    """

    def __init__(self, interval: str, max_days: int) -> None:
        """Carry what the 422 has to say: which interval, and how many days it allows."""
        super().__init__("range too long")
        self.interval = interval
        self.max_days = max_days
