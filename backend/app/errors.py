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
