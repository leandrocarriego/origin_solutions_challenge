"""Typed configuration. The provider credential is read here and nowhere else (Article I)."""

import re
from functools import lru_cache
from typing import Final

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict

# Signing HS256 with a short key is offline brute force on any captured token, so below this
# length the process refuses to start (SEC-05). It lives here and not in `app/security.py`
# because this is where the value is validated; that file imports it to say the same thing when
# it signs, which is one number with two readers rather than two numbers.
MIN_JWT_SECRET_LENGTH: Final = 32


class Settings(BaseSettings):
    """Everything the process reads from its environment."""

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # Identity of the running build. The deploy stamps it; locally it stays "dev".
    version: str = "dev"

    database_url: str = "postgresql+asyncpg://origin:origin@localhost:5432/origin"

    # Article I: this never leaves the backend, and never reaches a VITE_* variable.
    twelvedata_api_key: str = ""

    # ADR-004: what session tokens are signed with. **Required, and with a floor**: there is no
    # default because a development secret committed to a repository is production's secret the
    # day somebody forgets the variable (SEC-05), and no short value because that is a signature
    # anybody can forge offline.
    #
    # The consequence is deliberate and worth stating: a process that was started without it does
    # not boot at all. It cannot answer health in green and break at the first login, which is the
    # failure this replaces. Whatever only *imports* the application without serving it -- the
    # OpenAPI export of `make types`, the test suite -- hands it a throwaway value, and those are
    # the only two places that do.
    jwt_secret: str = Field(min_length=MIN_JWT_SECRET_LENGTH)

    # Which module under app/providers/ serves market data. It lives here because GEN-08 keeps
    # the provider's name to one file plus this one: a composition root that imported the class
    # to wire it would have written the name in a third. Set it to "fake" and nothing reaches
    # the network.
    market_data_provider: str = "twelvedata"

    # Empty disables Sentry, which is what local and CI want: no events, no network.
    sentry_dsn: str = ""
    sentry_environment: str = "local"

    # Narrowed to the frontend origin, never "*": the API answers with credentials.
    cors_origins: list[str] = Field(default_factory=lambda: ["http://localhost:5173"])

    @property
    def market_data_api_key(self) -> str:
        """The credential of whichever provider is configured.

        The provider's name may not appear outside this file (GEN-08), so the wiring asks for
        the credential by what it is for and not by who issued it.
        """
        return self.twelvedata_api_key

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
