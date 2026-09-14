"""The HTTP contract of `auth`: what comes in and what goes out.

Internal to the module. What travels to other modules is what the `__init__` declares, and that
is the router and nothing else.
"""

from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class LoginRequest(BaseModel):
    """The credential a caller presents.

    `extra="forbid"`: a body that carries fields nobody declared is a body that will eventually
    carry one somebody forgot to ignore.

    The maximum lengths keep a password of a megabyte from reaching Argon2, which is deliberately
    expensive, and they are refused by the schema before the route runs.
    """

    model_config = ConfigDict(extra="forbid")

    username: str = Field(min_length=1, max_length=50)
    password: str = Field(min_length=1, max_length=128)


class LoginResponse(BaseModel):
    """The session a good credential buys.

    `full_name` travels here so the header can be painted without a second request; it is the
    same value as the token's `name` claim, not a second source of truth. And `expires_in` is
    derived from `ACCESS_TOKEN_TTL`, so the frontend holds no copy of the number.
    """

    access_token: str
    # The scheme the client writes in front of the token on every later request. The only value
    # it can hold, so the generated frontend types get the literal and not a free string.
    token_type: Literal["bearer"] = "bearer"  # noqa: S105 -- a scheme name, not a credential
    expires_in: int
    full_name: str


class CurrentUserResponse(BaseModel):
    """Who the presented token says is calling.

    Two fields, because this answers a token and not a row. Adding `username` -- or anything else
    `users` happens to hold -- would turn a claim the caller already carries into a read of their
    record, and answering the whole row because it was already loaded is the habit that leaks.
    Nothing here is loaded.
    """

    id: int
    full_name: str
