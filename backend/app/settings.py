"""Typed configuration: everything the process reads from its environment."""

import re
from functools import lru_cache
from typing import Final

from pydantic import Field, SecretStr, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

MIN_JWT_SECRET_LENGTH: Final = 32


class Settings(BaseSettings):
    """Everything the process reads from its environment."""

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    version: str = "dev"

    database_url: str = "postgresql+asyncpg://origin:origin@localhost:5432/origin"
    market_data_api_key: SecretStr = SecretStr("")
    jwt_secret: SecretStr = Field(min_length=MIN_JWT_SECRET_LENGTH)

    market_data_provider: str = Field(min_length=1)

    # Empty disables Sentry, which is what local and CI want: no events, no network.
    sentry_dsn: str = ""

    # Which deployment this is. Sentry tags its events with it, and `seed.py` refuses
    # to run when it says production.
    environment: str = "local"

    cors_origins: list[str] = Field(default_factory=lambda: ["http://localhost:5173"])

    @field_validator("cors_origins")
    @classmethod
    def _refuse_any_origin(cls, origins: list[str]) -> list[str]:
        """Refuse `"*"`, because Starlette will not."""
        if "*" in origins:
            raise ValueError(
                'CORS_ORIGINS must name the origins it allows, never "*": with credentials '
                "enabled that lets any site make authenticated requests from a visitor's browser"
            )

        return origins

    def secret_values(self) -> tuple[str, ...]:
        """Every literal secret this process holds, for whoever has to blank them out."""
        # `SecretStr` keeps a credential out of a repr; this keeps it out of a message that
        # already holds the value as text -- a URL inside an exception, a DSN inside a traceback
        # -- where it is a substring and no longer a field anybody can hide.
        password = re.search(r"://[^:/@]+:([^@]+)@", self.database_url)

        return tuple(
            value
            for value in (
                self.market_data_api_key.get_secret_value(),
                self.jwt_secret.get_secret_value(),
                password.group(1) if password else "",
            )
            if value
        )


@lru_cache
def get_settings() -> Settings:
    """Read the environment once. Cached, so importing it anywhere is free."""
    return Settings()
