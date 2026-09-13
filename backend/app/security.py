"""Security primitives shared by every module (GEN-03).

Argon2id and nothing else. `md5`, `sha1` and `sha256` are designed to be fast, which is exactly
what you do not want the day somebody walks off with the `users` table; Argon2id is OWASP's first
recommendation for stored passwords and the only algorithm this project allows (SEC-06).

This lives in the kernel rather than in `auth/` because the routers of every module consume what
grows here -- `get_current_user` arrives with `001-authentication` -- so it belongs to no module
in particular (ADR-004).
"""

from argon2 import PasswordHasher
from argon2.exceptions import Argon2Error

# The library's defaults, which track OWASP's current parameters. Tuning them by hand is how a
# project ends up with a cost factor that was reasonable in 2019.
_hasher = PasswordHasher()


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
