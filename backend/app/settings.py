"""Typed configuration. The provider credential is read here and nowhere else (Article I)."""

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


@lru_cache
def get_settings() -> Settings:
    """Read the environment once. Cached, so importing it anywhere is free."""
    return Settings()
