"""
Typed configuration: everything the process reads from its environment.

The provider credential is read here and nowhere else (Article I).
"""

import re
from functools import lru_cache
from typing import Final

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

# Signing HS256 with a short key is offline brute force on any captured token (SEC-05). It lives
# here, where the value is validated, and `app/security.py` imports it: one number, two readers.
MIN_JWT_SECRET_LENGTH: Final = 32


class Settings(BaseSettings):
    """Everything the process reads from its environment."""

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # Identity of the running build. The deploy stamps it; locally it stays "dev".
    version: str = "dev"

    database_url: str = "postgresql+asyncpg://origin:origin@localhost:5432/origin"

    # Article I: this never leaves the backend, and never reaches a VITE_* variable.
    twelvedata_api_key: str = ""

    # ADR-004: what session tokens are signed with. Required and with a floor, so a process
    # without a usable one does not boot instead of breaking at the first login (SEC-05).
    jwt_secret: str = Field(min_length=MIN_JWT_SECRET_LENGTH)

    # Which module under app/providers/ serves market data. It lives here because GEN-08 keeps the
    # provider's name to one file plus this one. Set it to "fake" and nothing reaches the network.
    market_data_provider: str = "twelvedata"

    # Empty disables Sentry, which is what local and CI want: no events, no network.
    sentry_dsn: str = ""
    sentry_environment: str = "local"

    # Narrowed to the frontend origin, never "*" (SEC-08).
    cors_origins: list[str] = Field(default_factory=lambda: ["http://localhost:5173"])

    @field_validator("cors_origins")
    @classmethod
    def _refuse_any_origin(cls, origins: list[str]) -> list[str]:
        """Refuse `"*"`, because Starlette will not."""
        # Asked for every origin, `CORSMiddleware` echoes back whichever origin asked instead of
        # answering `"*"` -- which is what a browser needs to hand over somebody else's session.
        if "*" in origins:
            raise ValueError(
                'CORS_ORIGINS must name the origins it allows, never "*": with credentials '
                "enabled that lets any site make authenticated requests from a visitor's browser"
            )

        return origins

    @property
    def market_data_api_key(self) -> str:
        """The credential of whichever provider is configured, asked for by what it is for."""
        return self.twelvedata_api_key

    def secret_values(self) -> tuple[str, ...]:
        """Every literal secret this process holds, for whoever has to blank them out."""
        # It lives next to the fields and not next to the scrubber, so adding a credential and
        # covering it are the same act. The database password is in there too: it is not a field
        # of its own, it arrives inside the URL, and a SQLAlchemy traceback carries that URL whole.
        password = re.search(r"://[^:/@]+:([^@]+)@", self.database_url)

        return tuple(
            value
            for value in (
                self.twelvedata_api_key,
                self.jwt_secret,
                password.group(1) if password else "",
            )
            if value
        )


@lru_cache
def get_settings() -> Settings:
    """Read the environment once. Cached, so importing it anywhere is free."""
    return Settings()
