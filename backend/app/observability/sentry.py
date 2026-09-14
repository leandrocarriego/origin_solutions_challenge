"""Error reporting: what gets sent, and the scrubbing it goes through first."""

import sentry_sdk
from sentry_sdk.integrations.asyncio import AsyncioIntegration
from sentry_sdk.integrations.fastapi import FastApiIntegration
from sentry_sdk.types import Event, Hint

from app.observability.scrubbing import scrub
from app.settings import get_settings

# Literal values shorter than this are not blanked out.
_MIN_SECRET_LENGTH = 8


def _secret_values() -> tuple[str, ...]:
    """The secrets worth blanking out literally.

    Which values are secret is the settings' business; how short is too short is this file's.
    """
    return tuple(
        value for value in get_settings().secret_values() if len(value) >= _MIN_SECRET_LENGTH
    )


def scrub_secrets(event: Event, hint: Hint) -> Event | None:
    """Remove every credential from a Sentry event before it leaves the process."""
    try:
        cleaned: Event = scrub(event, _secret_values())

    except Exception:  # noqa: BLE001 -- see the docstring: dropping the event is worse
        # Something still reaches Sentry, so the failure is visible instead of silent, and it
        # carries nothing from the event that could not be cleaned.
        return Event(message="event dropped: scrubbing failed")

    return cleaned


def configure_sentry() -> None:
    """Initialise error reporting with every unsafe default turned off.

    An empty DSN disables it, which is what local development and CI want: no events and no
    network.
    """
    settings = get_settings()
    if not settings.sentry_dsn:
        return

    sentry_sdk.init(
        dsn=settings.sentry_dsn,
        environment=settings.environment,
        release=settings.version,
        integrations=[FastApiIntegration(), AsyncioIntegration()],
        # The three defaults that would ship credentials to a third party: frame locals hold the
        # DSN and the provider URL, and request bodies hold passwords.
        include_local_variables=False,
        send_default_pii=False,
        max_request_body_size="never",
        before_send=scrub_secrets,
        traces_sample_rate=0.0,
    )
