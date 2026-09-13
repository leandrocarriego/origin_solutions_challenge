"""Typed configuration. The provider credential is read here and nowhere else (Article I)."""

import re
from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Everything the process reads from its environment."""

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # Identity of the running build. The deploy stamps it; locally it stays "dev".
    version: str = "dev"

    database_url: str = "postgresql+asyncpg://origin:origin@localhost:5432/origin"

    # Article I: this never leaves the backend, and never reaches a VITE_* variable.
    twelvedata_api_key: str = ""

    # Empty disables Sentry, which is what local and CI want: no events, no network.
    sentry_dsn: str = ""
    sentry_environment: str = "local"

    # Narrowed to the frontend origin, never "*": the API answers with credentials.
    cors_origins: list[str] = Field(default_factory=lambda: ["http://localhost:5173"])

    def secret_values(self) -> tuple[str, ...]:
        """Every literal secret this process holds, for whoever has to blank them out.

        It lives here, next to the fields, and not next to the scrubber that uses it. That way
        adding a credential to this class and covering it are the same act: a secret the
        scrubber was never told about is a secret it prints.

        The database password is included because it is not a field of its own -- it arrives
        inside the URL, and a SQLAlchemy traceback carries that URL whole.
        """
        password = re.search(r"://[^:/@]+:([^@]+)@", self.database_url)

        return tuple(
            value
            for value in (self.twelvedata_api_key, password.group(1) if password else "")
            if value
        )


@lru_cache
def get_settings() -> Settings:
    """Read the environment once. Cached, so importing it anywhere is free."""
    return Settings()
