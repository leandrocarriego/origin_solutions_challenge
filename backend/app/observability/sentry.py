"""Error reporting, and the scrubber that keeps a credential from travelling with the report.

Sending an exception to a third party is sending whatever the exception was carrying. The three
defaults that would ship credentials are turned off here, and `scrub_secrets` is the second line:
it walks the event and blanks out the values this process holds (Article I, `SEC-06`).
"""

import re
from typing import Any

import sentry_sdk
from sentry_sdk.integrations.asyncio import AsyncioIntegration
from sentry_sdk.integrations.fastapi import FastApiIntegration
from sentry_sdk.types import Event, Hint

from app.settings import get_settings

# Matches the credential-carrying query parameters by shape, so an unknown or rotated value is
# caught too. Value-based scrubbing alone only covers what Settings happens to know.
_SECRET_PARAM = re.compile(
    r"(?i)\b(apikey|api_key|token|password|secret|authorization)=([^&\s\"']+)"
)

# The password inside any connection string, whether or not this process configured it: a
# traceback can carry a DSN for a database Settings never heard of.
_DSN_PASSWORD = re.compile(r"(://[^:/@\s]+:)([^@\s]+)(@)")

_REDACTED = "[redacted]"

# Literal values shorter than this are not blanked out. The insecure default password is the
# word "origin", which is also the user and the database name: redacting every occurrence would
# turn a useful event into holes. Real credentials are far longer, and the two patterns above
# catch the short ones by shape anyway.
_MIN_SECRET_LENGTH = 8


def _secret_values() -> tuple[str, ...]:
    """The secrets worth blanking out literally.

    Which values are secret is the settings' business (GEN-08: nothing outside the provider and
    the settings names the provider), and how short is too short is this file's.
    """
    return tuple(
        value for value in get_settings().secret_values() if len(value) >= _MIN_SECRET_LENGTH
    )


def _scrub(value: Any, secrets: tuple[str, ...]) -> Any:
    """Walk any nested structure and blank out every secret it carries."""
    if isinstance(value, str):
        cleaned = _SECRET_PARAM.sub(rf"\1={_REDACTED}", value)
        cleaned = _DSN_PASSWORD.sub(rf"\1{_REDACTED}\3", cleaned)
        for secret in secrets:
            cleaned = cleaned.replace(secret, _REDACTED)
        return cleaned
    if isinstance(value, dict):
        return {key: _scrub(item, secrets) for key, item in value.items()}
    if isinstance(value, list):
        return [_scrub(item, secrets) for item in value]
    if isinstance(value, tuple):
        return tuple(_scrub(item, secrets) for item in value)
    return value


def scrub_secrets(event: Event, hint: Hint) -> Event | None:
    """Remove every credential from a Sentry event before it leaves the process.

    Never raises: an exception inside before_send makes Sentry drop the event silently, so the
    failure that mattered disappears and nobody finds out.
    """
    try:
        cleaned: Event = _scrub(event, _secret_values())
    except Exception:  # noqa: BLE001 -- see the docstring: dropping the event is worse
        # Something still reaches Sentry, so the failure is visible instead of silent, and it
        # carries nothing from the event that could not be cleaned.
        return Event(message="event dropped: scrubbing failed")
    return cleaned


def configure_sentry() -> None:
    """Initialise error reporting with every unsafe default turned off.

    An empty DSN disables it, which is what local development and CI want: no events, no
    network, nothing to clean up afterwards (TEST-03).
    """
    settings = get_settings()
    if not settings.sentry_dsn:
        return

    sentry_sdk.init(
        dsn=settings.sentry_dsn,
        environment=settings.environment,
        release=settings.version,
        integrations=[FastApiIntegration(), AsyncioIntegration()],
        # The three defaults that would ship credentials to a third party. Frame locals hold
        # the DSN and the provider URL; request bodies hold passwords (Article I, SEC-06).
        include_local_variables=False,
        send_default_pii=False,
        max_request_body_size="never",
        before_send=scrub_secrets,
        traces_sample_rate=0.0,
    )
