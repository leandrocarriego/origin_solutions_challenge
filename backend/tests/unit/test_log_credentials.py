"""The provider's credential never reaches the log stream.

Sentry has its scrubber (`test_secret_scrubbing.py`); the log stream has nothing of the sort,
because nothing we write puts a URL in a line. The leak came from a library: httpx logs every
request at INFO with the full URL, and the provider's URL carries `apikey=` in its query string.
One courtesy line, and the credential is in stdout, in Loki and in whatever Grafana shows the
person looking at the logs -- which is the failure Article I describes word for word.

The test is on the configuration and not on a captured line on purpose: the level is the thing
that keeps it out, and a level is cheap to assert and impossible to satisfy by accident.
"""

import logging

from app.observability import configure_logging


class TestTheHttpClientDoesNotLogItsRequests:
    """httpx's request log carries the provider URL, and the URL carries the key."""

    def test_the_httpx_logger_is_above_info(self) -> None:
        """INFO is the level at which httpx prints `GET https://...?apikey=...`."""
        configure_logging()

        assert logging.getLogger("httpx").getEffectiveLevel() > logging.INFO

    def test_a_request_line_would_not_be_emitted(self) -> None:
        """The same thing from the caller's side: the record never makes it out."""
        configure_logging()

        assert not logging.getLogger("httpx").isEnabledFor(logging.INFO)

    def test_nothing_else_was_silenced_along_with_it(self) -> None:
        """Silencing one library is not turning the lights off."""
        configure_logging()

        assert logging.getLogger("uvicorn").level < logging.WARNING
