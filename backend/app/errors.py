"""
The domain errors any module raises, and the composition root translates.

One handler is registered per type, so the type *is* the status code: two failures that must
answer alike are one exception and not two.
"""


class DomainError(Exception):
    """Something the business rules refuse. Every error below is one of these."""


class AuthenticationError(DomainError):
    """The credential presented does not establish a session.

    One exception for an unknown user and for a wrong password, with the message fixed here so
    the two cannot drift apart.
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
    """The symbol is not one that can be added today: absent from the catalogue, or delisted."""

    def __init__(self) -> None:
        """Carry the one message the 404 handler answers with."""
        super().__init__("unknown symbol")


class QuoteRangeInvalid(DomainError):
    """The window asked for is not a window: `desde` is not before `hasta`."""

    def __init__(self) -> None:
        """Carry the one message the 422 handler answers with."""
        super().__init__("range invalid")


class QuoteRangeTooLong(DomainError):
    """The window is longer than that interval can serve."""

    def __init__(self, interval: str, max_days: int) -> None:
        """Carry what the 422 has to say: which interval, and how many days it allows."""
        super().__init__("range too long")

        self.interval = interval
        self.max_days = max_days
