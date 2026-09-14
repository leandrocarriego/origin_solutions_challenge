"""Security primitives shared by every module."""

from datetime import UTC, datetime, timedelta
from typing import Annotated, Final

import jwt
from argon2 import PasswordHasher
from argon2.exceptions import Argon2Error
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel, ConfigDict, Field, ValidationError

from app.settings import MIN_JWT_SECRET_LENGTH, get_settings

ACCESS_TOKEN_TTL: Final = timedelta(minutes=60)

_ALGORITHM = "HS256"

_REQUIRED_CLAIMS = ("exp", "iat", "sub")

_bearer = HTTPBearer(auto_error=False)

# The library's defaults, which track OWASP's current parameters.
_hasher = PasswordHasher()


class _TokenClaims(BaseModel):
    """What a session token carries, and the only shape a decoded one is accepted in."""

    model_config = ConfigDict(frozen=True)

    sub: str = Field(pattern=r"^[1-9][0-9]*$")
    name: str
    iat: int
    exp: int


class CurrentUser(BaseModel):
    """Who a token says is calling, and the only identity a protected route ever sees."""

    model_config = ConfigDict(frozen=True)

    id: int
    full_name: str


def hash_password(password: str) -> str:
    """Generates a password hash using Argon2id, including a salt.

    Two calls with the same password return different strings.
    """
    return _hasher.hash(password)


def verify_password(password: str, stored: str) -> bool:
    """Whether the password matches what was stored."""
    try:
        return _hasher.verify(stored, password)

    except (Argon2Error, ValueError):
        return False


def create_access_token(user_id: int, full_name: str) -> str:
    """Sign a session token for that user."""
    issued = datetime.now(tz=UTC)

    claims = _TokenClaims(
        sub=str(user_id),
        name=full_name,
        iat=int(issued.timestamp()),
        exp=int((issued + ACCESS_TOKEN_TTL).timestamp()),
    )

    return jwt.encode(claims.model_dump(), _signing_secret(), algorithm=_ALGORITHM)


async def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(_bearer)],
) -> CurrentUser:
    """The user the presented token identifies, or a 401."""
    if credentials is None:
        raise _not_authenticated()

    try:
        claims = _TokenClaims.model_validate(
            jwt.decode(
                credentials.credentials,
                _signing_secret(),
                algorithms=[_ALGORITHM],
                options={"require": list(_REQUIRED_CLAIMS)},
            )
        )

    except (jwt.InvalidTokenError, ValidationError):
        raise _not_authenticated() from None

    return CurrentUser(id=int(claims.sub), full_name=claims.name)


def _signing_secret() -> str:
    """The secret to sign and verify with, refusing the values that are not secrets."""
    secret = get_settings().jwt_secret.get_secret_value()

    if len(secret) < MIN_JWT_SECRET_LENGTH:
        raise RuntimeError(
            "JWT_SECRET is missing or shorter than "
            f"{MIN_JWT_SECRET_LENGTH} characters; refusing to sign or verify a session token"
        )

    return secret


def _not_authenticated() -> HTTPException:
    """The single refusal every failed verification answers with."""
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="not authenticated",
        headers={"WWW-Authenticate": "Bearer"},
    )
