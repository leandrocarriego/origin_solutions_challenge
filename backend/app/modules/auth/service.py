"""This module owns the *numbers* of the attempt policy and `app.ratelimit` owns the counting."""

import secrets
from datetime import timedelta
from typing import Protocol

import structlog

from app.db import SessionDep
from app.errors import AuthenticationError, RateLimitedError
from app.modules.auth.models import User
from app.modules.auth.repository import UserRepository
from app.modules.auth.schemas import AuthenticatedUser
from app.observability import LOGIN_ATTEMPTS
from app.ratelimit import SlidingWindowLimiter
from app.security import hash_password, verify_password

# Generous for somebody typing badly, short for somebody guessing.
LOGIN_MAX_ATTEMPTS = 10
LOGIN_WINDOW = timedelta(minutes=5)

# One counter per process, in memory: lost on restart and not shared between replicas.
_login_limiter = SlidingWindowLimiter(limit=LOGIN_MAX_ATTEMPTS, window=LOGIN_WINDOW)

# The decoy. When the typed username matches no row, the password is verified against this hash
# anyway: returning early would answer in a fraction of the time, and timing enumerates users
# just as well as a message does. It is built from a random value nobody can type, so it cannot
# accidentally be the hash of anything.
_ABSENT_USER_HASH = hash_password(secrets.token_urlsafe(32))

_log = structlog.get_logger()


class UserStore(Protocol):
    """What this module needs from whatever holds the users it checks a credential against."""

    async def find_by_username(self, username: str) -> User | None:
        """The user who answers to that name, matched without regard to case."""
        ...


def user_store(session: SessionDep) -> UserStore:
    """The store a route is served with."""
    return UserRepository(session)


async def authenticate(
    store: UserStore, username: str, password: str, client_ip: str
) -> AuthenticatedUser:
    """Check a credential and say who it belongs to."""
    typed = username.lower()

    # Counted on both at once, and the username as typed whether or not it exists: counting only
    # real users would enumerate them by behaviour.
    keys = (f"login:ip:{client_ip}", f"login:user:{typed}")

    waits = [_login_limiter.retry_after(key) for key in keys if _login_limiter.is_exceeded(key)]

    if waits:
        LOGIN_ATTEMPTS.labels(outcome="rate_limited").inc()
        _log.warning("login_rate_limited", username=typed, client_ip=client_ip)

        raise RateLimitedError(retry_after_seconds=max(waits))

    user = await store.find_by_username(typed)
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
