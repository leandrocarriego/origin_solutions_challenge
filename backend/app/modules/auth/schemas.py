"""The schemas of `auth`."""

from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class LoginRequest(BaseModel):
    """The credential a caller presents."""

    model_config = ConfigDict(extra="forbid")

    username: str = Field(min_length=1, max_length=50)
    # The maximum lengths keep a password of a megabyte from reaching Argon2, which is deliberately
    # expensive, and they are refused by the schema before the route runs.
    password: str = Field(min_length=1, max_length=128)


class LoginResponse(BaseModel):
    """The session a good credential buys."""

    access_token: str
    token_type: Literal["bearer"] = "bearer"  # noqa: S105 -- a scheme name, not a credential
    expires_in: int
    full_name: str


class CurrentUserResponse(BaseModel):
    """Who the presented token says is calling."""

    id: int
    full_name: str


class AuthenticatedUser(BaseModel):
    """Whoever just proved they know the password."""

    model_config = ConfigDict(frozen=True)

    id: int
    full_name: str
