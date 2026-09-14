"""Security primitives shared by every module (GEN-03).

Three things live here: Argon2id for stored passwords, the session token, and the dependency
every protected route declares to find out who is calling.

Argon2id and nothing else for the password. `md5`, `sha1` and `sha256` are designed to be fast,
which is exactly what you do not want the day somebody walks off with the `users` table; Argon2id
is OWASP's first recommendation for stored passwords and the only algorithm this project allows
(SEC-06).

This lives in the kernel rather than in `auth/` because the routers of every module consume it:
if `get_current_user` lived in `auth`, `favorites` and `quotes` would have to import a domain
module in order to authorize, and the security primitive of the whole system would become the
property of one module (ADR-004).

`get_current_user` is the one place in the project where something outside a router raises
`HTTPException`, and that is deliberate: it is not a service, it is a FastAPI dependency sitting
on the HTTP edge of the kernel. `PY-06` and `ERR-04` forbid `HTTPException` *inside a module*,
and this file is inside none.
"""

from datetime import UTC, datetime, timedelta
from typing import Annotated, Any, Final

import jwt
from argon2 import PasswordHasher
from argon2.exceptions import Argon2Error
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel, ConfigDict

from app.settings import MIN_JWT_SECRET_LENGTH, get_settings

# The library's defaults, which track OWASP's current parameters. Tuning them by hand is how a
# project ends up with a cost factor that was reasonable in 2019.
_hasher = PasswordHasher()

# RF-16. A constant and not a setting: how long a session lasts is a security decision, not
# something an operator gets to stretch from an environment variable (SEC-04).
ACCESS_TOKEN_TTL: Final = timedelta(minutes=60)

# Written out and always passed explicitly to `jwt.decode`. A decode that does not pin the
# algorithm accepts a token whose header says `alg: none`, and from that moment the signature is
# decoration and anybody can mint any identity.
_ALGORITHM = "HS256"

# Claims a token has to carry to be considered at all. Without `exp` in this list a token with no
# expiry would be accepted by omission, which is a session that never ends.
_REQUIRED_CLAIMS = ("exp", "iat", "sub")

# `auto_error=False` on purpose. Left to itself, `HTTPBearer` answers 403 for an absent header
# and a body we did not choose for a malformed one; with it off, the four ways a credential can
# fail leave through the same 401 with the same challenge, which is what the frontend's
# interceptor and `TestRoutesEnforceAuthorization` both key on.
_bearer = HTTPBearer(auto_error=False)


def hash_password(password: str) -> str:
    """Hash a password with Argon2id, salt included.

    Two calls on the same password return different strings, and that is the point: a salt per
    hash is what stops one crack from opening every account that reused the password.
    """
    return _hasher.hash(password)


def verify_password(password: str, stored: str) -> bool:
    """Whether the password matches what was stored.

    It fails closed. A stored value that is not an Argon2 hash -- a row written by something
    that ignored SEC-06 -- is a verification that fails, never one that raises and never one
    that compares plaintext and says yes.
    """
    try:
        return _hasher.verify(stored, password)
    except (Argon2Error, ValueError):
        return False


class CurrentUser(BaseModel):
    """Who a token says is calling, and the only identity a protected route ever sees.

    Frozen because a route that could edit the identity it was handed is a route that can act as
    somebody else (Article III).
    """

    model_config = ConfigDict(frozen=True)

    id: int
    full_name: str


def create_access_token(user_id: int, full_name: str) -> str:
    """Sign a session token for that user (ADR-004).

    `exp` is derived from `iat` and `ACCESS_TOKEN_TTL`, so the lifetime the response advertises
    and the lifetime the token really has cannot drift apart. The full name travels in it so the
    header can be painted without a second request (RF-08).
    """
    issued = datetime.now(tz=UTC)
    claims = {
        "sub": str(user_id),
        "name": full_name,
        "iat": int(issued.timestamp()),
        "exp": int((issued + ACCESS_TOKEN_TTL).timestamp()),
    }

    return jwt.encode(claims, _signing_secret(), algorithm=_ALGORITHM)


async def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(_bearer)],
) -> CurrentUser:
    """The user the presented token identifies, or a 401.

    Absent, tampered with, malformed, expired or signed with another algorithm: five ways to
    fail and one answer, because telling them apart tells a caller which half of the attack
    worked.
    """
    if credentials is None:
        raise _not_authenticated()

    try:
        claims: dict[str, Any] = jwt.decode(
            credentials.credentials,
            _signing_secret(),
            algorithms=[_ALGORITHM],
            options={"require": list(_REQUIRED_CLAIMS)},
        )
    except jwt.InvalidTokenError:
        raise _not_authenticated() from None

    subject = claims.get("sub")
    full_name = claims.get("name")
    if not isinstance(subject, str) or not subject.isdigit() or not isinstance(full_name, str):
        raise _not_authenticated()

    return CurrentUser(id=int(subject), full_name=full_name)


def _signing_secret() -> str:
    """The secret to sign and verify with, refusing the values that are not secrets.

    `Settings` already refuses a missing or short one when the process reads its environment
    (`SEC-05`), so in a running application this cannot fire: it is the second line, and it is
    here because a `Settings` built by hand -- `model_construct`, which skips validation -- walks
    past the first. The number is imported and never retyped, so the two cannot come to disagree
    about what counts as a secret.
    """
    secret = get_settings().jwt_secret
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
