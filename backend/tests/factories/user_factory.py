"""Factory of `users` rows, which is the only table `auth` owns.

The password is hashed once for the whole suite and reused. Argon2id is deliberately expensive
, so a factory that hashed per row would charge that cost to every test that needs a
user -- and the tests of the attempt limit need eleven attempts each.
"""

from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.auth.models import User
from app.security import hash_password

# The password every factory-made user answers to. The tests that assert a wrong password use
# something else; the ones that assert case sensitivity use this in upper case.
PASSWORD = "una-clave-de-demo"

_PASSWORD_HASH = hash_password(PASSWORD)


class UserFactory:
    """Rows of `users` whose stored hash actually verifies against `PASSWORD`."""

    @staticmethod
    async def create(session: AsyncSession, **kwargs: object) -> User:
        """Insert one user, defaulting to the demo row the README hands the evaluator."""
        defaults: dict[str, object] = {
            "username": "juan",
            "full_name": "Juan Perez",
            "password_hash": _PASSWORD_HASH,
        }
        defaults.update(kwargs)

        user = User(**defaults)
        session.add(user)
        await session.flush()

        return user
