"""
What authenticating decides. Nothing of the transport reaches this layer.

This module owns the *numbers* of the attempt policy and `app.ratelimit` owns the counting, so
the kernel never learns what is being counted: it is handed two keys and a limit.

The order of the steps inside `authenticate` is part of the contract. The limit is consulted
before the user is looked up and before anything is verified, because Argon2 is expensive by
design and a limit paid with a hash computation protects the wrong resource -- the CPU it spends
is what a brute-force attempt is trying to burn.
"""

import secrets
from datetime import timedelta

import structlog
from pydantic import BaseModel, ConfigDict
from sqlalchemy.ext.asyncio import AsyncSession

from app.errors import AuthenticationError, RateLimitedError
from app.modules.auth.repository import find_by_username
from app.observability import LOGIN_ATTEMPTS
from app.ratelimit import SlidingWindowLimiter
from app.security import hash_password, verify_password

# Generous for somebody typing badly, short for somebody guessing.
LOGIN_MAX_ATTEMPTS = 10
LOGIN_WINDOW = timedelta(minutes=5)

# One counter per process, in memory: lost on restart and not shared between replicas. Compose
# runs a single backend, and with two the effective ceiling would double -- it degrades, it does
# not break.
_login_limiter = SlidingWindowLimiter(limit=LOGIN_MAX_ATTEMPTS, window=LOGIN_WINDOW)

# The decoy. When the typed username matches no row, the password is verified against this hash
# anyway: returning early would answer in a fraction of the time, and timing enumerates users
# just as well as a message does. It is built from a random value nobody can type, so it cannot
# accidentally be the hash of anything.
_ABSENT_USER_HASH = hash_password(secrets.token_urlsafe(32))

_log = structlog.get_logger()


class AuthenticatedUser(BaseModel):
    """Whoever just proved they know the password.

    Deliberately not `CurrentUser`: this is the result of authenticating and it does not leave
    the module, while `CurrentUser` is the identity that comes out of a token and the whole
    system sees. The ORM row stays behind -- a model that reached the HTTP edge would bring the
    session and the table layout with it.
    """

    model_config = ConfigDict(frozen=True)

    id: int
    full_name: str


async def authenticate(
    session: AsyncSession, username: str, password: str, client_ip: str
) -> AuthenticatedUser:
    """Check a credential and say who it belongs to.

    Raises `RateLimitedError` when either window is full, and `AuthenticationError` -- the very
    same one -- whether the user does not exist or the password is wrong.

    The username is folded to lower case and the password is not: relaxing the first is a
    convenience for whoever types it, and relaxing the second would remove entropy from the only
    secret involved.
    """
    typed = username.lower()
    # Counted on both at once, and the username as typed whether or not it exists: counting only
    # real users would enumerate them by behaviour.
    keys = (f"login:ip:{client_ip}", f"login:user:{typed}")

    waits = [_login_limiter.retry_after(key) for key in keys if _login_limiter.is_exceeded(key)]
    if waits:
        LOGIN_ATTEMPTS.labels(outcome="rate_limited").inc()
        _log.warning("login_rate_limited", username=typed, client_ip=client_ip)
        raise RateLimitedError(retry_after_seconds=max(waits))

    user = await find_by_username(session, typed)
    stored = user.password_hash if user is not None else _ABSENT_USER_HASH
    # Always verified, even with no row: see `_ABSENT_USER_HASH`.
    matched = verify_password(password, stored)

    if user is None or not matched:
        for key in keys:
            _login_limiter.hit(key)
        LOGIN_ATTEMPTS.labels(outcome="failed").inc()
        # The username and the address, and nothing else. Never the password, not even its
        # length: a line in a log defeats the hashing of the column that stores it.
        _log.info("login_failed", username=typed, client_ip=client_ip)
        raise AuthenticationError

    # Whoever proved they know the password is not the guesser being counted.
    for key in keys:
        _login_limiter.reset(key)
    LOGIN_ATTEMPTS.labels(outcome="succeeded").inc()
    _log.info("login_succeeded", username=typed, client_ip=client_ip)

    return AuthenticatedUser(id=user.id, full_name=user.full_name)
