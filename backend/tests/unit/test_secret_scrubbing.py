"""Nothing that carries a credential reaches Sentry (ADR-009, Article I, SEC-06).

This is the highest-stakes test in the observability layer. Sentry captures the local variables
of every frame by default, and in this backend those frames hold the Postgres DSN and the
provider URL with its `apikey` in the query string. Without scrubbing, one 500 ships both to a
third party.

The scrubber is a pure function on purpose: no SDK, no network, no init. It can be exercised
with a synthetic event, which is what makes this cheap enough to run on every commit.
"""

from typing import Any

from sentry_sdk.types import Event

from app.observability import scrub_secrets

SENTINEL_API_KEY = "sentinel-api-key-do-not-log"
SENTINEL_DB_PASSWORD = "sentinel-db-password"


def _event_with(payload: Any) -> Event:
    """A Sentry event shaped like the real thing, with the payload buried where it hurts."""
    event: Event = {
        "message": "provider call failed",
        "exception": {
            "values": [
                {
                    "type": "HTTPStatusError",
                    "value": str(payload),
                    "stacktrace": {"frames": [{"vars": {"url": payload}}]},
                }
            ]
        },
        "extra": {"nested": {"deep": payload}},
    }
    return event


class TestScrubsKnownSecrets:
    """Values the process knows about never reach the event."""

    def test_redacts_the_api_key_wherever_it_appears(self) -> None:
        """The key is removed from every corner of the payload, however deep."""
        event = _event_with(f"https://api.twelvedata.com/time_series?apikey={SENTINEL_API_KEY}")

        scrubbed = scrub_secrets(event, {})

        assert SENTINEL_API_KEY not in str(scrubbed)

    def test_redacts_the_database_password(self) -> None:
        """The DSN carries the password, so the DSN is a secret too."""
        dsn = f"postgresql+asyncpg://origin:{SENTINEL_DB_PASSWORD}@db:5432/origin"
        event = _event_with(dsn)

        scrubbed = scrub_secrets(event, {})

        assert SENTINEL_DB_PASSWORD not in str(scrubbed)


class TestScrubsByShapeNotOnlyByValue:
    """Not knowing a value is never the reason a credential escapes."""

    def test_strips_an_apikey_parameter_whose_value_it_does_not_know(self) -> None:
        """A rotated or unknown key is caught by the shape of the parameter."""
        # The value-based pass only catches what Settings knows. A rotated key, a second
        # provider, or a key read from somewhere else would sail through. The query string
        # is scrubbed by shape so that "we did not know that value" is never the reason a
        # credential leaves the process.
        event = _event_with("https://api.twelvedata.com/quote?symbol=TSLA&apikey=an-unknown-value")

        scrubbed = scrub_secrets(event, {})

        assert "an-unknown-value" not in str(scrubbed)
        # The symbol is diagnostic, not secret: it has to survive or the event is useless.
        assert "TSLA" in str(scrubbed)


class TestDoesNotOverScrub:
    """An event scrubbed into uselessness is as bad as no event."""

    def test_keeps_everything_that_is_not_a_secret(self) -> None:
        """Diagnostic fields survive untouched."""
        event: Event = {
            "message": "quote cache miss",
            "extra": {"symbol": "AAPL", "interval": "1min", "cache_hit": False},
        }

        scrubbed = scrub_secrets(event, {})

        assert scrubbed is not None
        assert scrubbed["extra"] == {"symbol": "AAPL", "interval": "1min", "cache_hit": False}

    def test_an_event_with_no_secrets_comes_back_unchanged(self) -> None:
        """The clean case is a no-op, with nothing rewritten."""
        event: Event = {"message": "market closed", "extra": {"symbol": "NFLX"}}

        assert scrub_secrets(event, {}) == event


class TestSurvivesAwkwardEvents:
    """The scrubber never becomes the reason an event is lost."""

    def test_handles_values_that_are_not_strings(self) -> None:
        """Ints, floats, None and nested lists do not crash before_send."""
        # Sentry events carry ints, floats, None, lists and nested dicts. A scrubber that
        # assumes strings crashes inside before_send, and a crash there drops the event
        # silently: the exception that mattered is lost and nobody finds out.
        event: Event = {
            "message": "mixed",
            "extra": {"count": 3, "ratio": 0.5, "missing": None, "items": [1, "two", {"k": "v"}]},
        }

        assert scrub_secrets(event, {}) is not None


class TestSentryIsConfiguredSafely:
    """The scrubber is useless if the SDK is initialised with the unsafe defaults."""

    def test_local_variables_are_not_captured(self, sentry_configured: Any) -> None:
        """Frame locals hold the DSN and the provider URL, so they must never be sent."""
        assert sentry_configured.options["include_local_variables"] is False

    def test_personal_data_is_not_captured(self, sentry_configured: Any) -> None:
        """No IPs, cookies or request bodies: the body of a login carries a password."""
        assert sentry_configured.options["send_default_pii"] is False

    def test_the_scrubber_is_wired_in(self, sentry_configured: Any) -> None:
        """A scrubber nobody calls is a scrubber that does nothing."""
        assert sentry_configured.options["before_send"] is scrub_secrets

    def test_request_bodies_are_never_attached(self, sentry_configured: Any) -> None:
        """Sentry attaches request bodies by default, and a login body is a credential."""
        assert sentry_configured.options["max_request_body_size"] == "never"
