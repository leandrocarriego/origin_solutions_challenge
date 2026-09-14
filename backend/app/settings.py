"""Typed configuration: everything the process reads from its environment."""

import re
from functools import lru_cache
from typing import Final

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

MIN_JWT_SECRET_LENGTH: Final = 32


class Settings(BaseSettings):
    """Everything the process reads from its environment."""

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    version: str = "dev"

    database_url: str = "postgresql+asyncpg://origin:origin@localhost:5432/origin"
    market_data_api_key: str = ""
    jwt_secret: str = Field(min_length=MIN_JWT_SECRET_LENGTH)

    # Which module under app/providers/ serves market data, resolved by name at wiring time. No
    # default, so no environment picks a provider -- and spends its quota -- by forgetting to say
    # which one. Set it to "fake" and nothing reaches the network.
    market_data_provider: str = Field(min_length=1)

    # Empty disables Sentry, which is what local and CI want: no events, no network.
    sentry_dsn: str = ""

    # Which deployment this is. Sentry tags its events with it, and `seed.py` refuses to run when
    # it says production -- a decision that is the environment's, not an observability vendor's.
    environment: str = "local"

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

    def secret_values(self) -> tuple[str, ...]:
        """Every literal secret this process holds, for whoever has to blank them out."""
        # It lives next to the fields and not next to the scrubber, so adding a credential and
        # covering it are the same act. The database password is in there too: it is not a field
        # of its own, it arrives inside the URL, and a SQLAlchemy traceback carries that URL whole.
        password = re.search(r"://[^:/@]+:([^@]+)@", self.database_url)

        return tuple(
            value
            for value in (
                self.market_data_api_key,
                self.jwt_secret,
                password.group(1) if password else "",
            )
            if value
        )


@lru_cache
def get_settings() -> Settings:
    """Read the environment once. Cached, so importing it anywhere is free."""
    return Settings()
