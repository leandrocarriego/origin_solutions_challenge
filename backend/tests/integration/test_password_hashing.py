"""No password is ever stored as itself.

`md5`, `sha1` and `sha256` are designed to be fast, which is exactly what you do not want the
day somebody walks off with the `users` table. Argon2id is OWASP's first recommendation and the
only algorithm this project allows.

It applies to the seed as much as to the login: the seed is the first code of the project and it
runs in phase 0, before any feature has a signed spec. A seed that writes plaintext leaves the
database wrong from minute one, and it is the first thing anyone auditing security opens.
"""

import pytest

from app.security import hash_password, verify_password

PASSWORD = "una-clave-de-demo"


class TestWhatGetsStored:
    """The stored value is a hash, and it says which algorithm made it."""

    def test_the_hash_is_argon2id(self) -> None:
        """Not argon2i, not argon2d: id is the variant OWASP recommends."""
        assert hash_password(PASSWORD).startswith("$argon2id$")

    def test_the_password_does_not_appear_in_the_hash(self) -> None:
        """Stating the obvious, because this is the one property everything else rests on."""
        assert PASSWORD not in hash_password(PASSWORD)

    def test_two_users_with_the_same_password_get_different_hashes(self) -> None:
        """A salt per hash is what stops one crack from opening every account that reused it."""
        assert hash_password(PASSWORD) != hash_password(PASSWORD)


class TestChecking:
    """Verification has to accept the right password and nothing else."""

    def test_the_right_password_verifies(self) -> None:
        """A different salt each time means the check cannot be a comparison of hashes."""
        assert verify_password(PASSWORD, hash_password(PASSWORD))

    @pytest.mark.parametrize("attempt", ["otra-clave", "", "una-clave-de-dem", PASSWORD.upper()])
    def test_anything_else_does_not(self, attempt: str) -> None:
        """Empty, close, and the same word in another case are all the wrong password."""
        assert not verify_password(attempt, hash_password(PASSWORD))

    def test_a_stored_value_that_is_not_a_hash_does_not_verify(self) -> None:
        """A row written by something that ignored the hashing rule must fail closed, not crash."""
        assert not verify_password(PASSWORD, PASSWORD)
