"""Structured logs with a request id, and the metrics that make Article II verifiable (ADR-009).

Article II says provider consumption scales with distinct symbols observed, never with clients
connected. Today that is a sentence in a README. These counters are what turn it into a number
someone can read off a dashboard, which is the whole point of ERR-07.
"""

import json

import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app


async def _call(
    path: str, headers: dict[str, str] | None = None
) -> tuple[int, str, dict[str, str]]:
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get(path, headers=headers or {})
    return response.status_code, response.text, dict(response.headers)


class TestLogsAreStructured:
    """Every line is a machine-readable record, not loose text."""

    async def test_every_line_is_valid_json(
        self, database_is_reachable: None, captured_logs: list[str]
    ) -> None:
        """Logs can be filtered by field instead of grepped."""
        await _call("/api/health")

        assert captured_logs, "a request has to leave a trace"
        for line in captured_logs:
            json.loads(line)  # raises if the line is not JSON


class TestRequestsAreCorrelated:
    """One request leaves one traceable thread through the logs."""

    async def test_all_lines_of_one_request_share_a_request_id(
        self, database_is_reachable: None, captured_logs: list[str]
    ) -> None:
        """Concurrent users stop interleaving into an unreadable stream."""
        # Without this, two concurrent users interleave their lines and no single case can be
        # followed end to end. It is the difference between logs you can read and logs you have.
        await _call("/api/health")

        ids = {json.loads(line).get("request_id") for line in captured_logs}
        assert len(ids) == 1, f"one request, one id — got {ids}"
        assert next(iter(ids)) is not None

    async def test_the_response_carries_the_request_id(self, database_is_reachable: None) -> None:
        """A user can quote the id of a failure and it can be found."""
        # So a user can quote the id from a failure and it can be found in the logs.
        _, _, headers = await _call("/api/health")

        assert headers.get("x-request-id")

    async def test_an_incoming_request_id_is_honoured(self, database_is_reachable: None) -> None:
        """The chain survives the proxy boundary instead of restarting at it."""
        # Traefik or a client may already have assigned one. Generating a second id breaks the
        # chain exactly where it is most needed: across the proxy boundary.
        given = "11111111-2222-3333-4444-555555555555"

        _, _, headers = await _call("/api/health", headers={"X-Request-ID": given})

        assert headers.get("x-request-id") == given

    async def test_two_requests_get_different_ids(self, database_is_reachable: None) -> None:
        """Correlation only works if the id actually distinguishes requests."""
        _, _, first = await _call("/api/health")
        _, _, second = await _call("/api/health")

        assert first["x-request-id"] != second["x-request-id"]


class TestLogsCarryNoCredentials:
    """Article I applied to the log stream."""

    async def test_the_api_key_never_reaches_a_log_line(
        self, database_is_reachable: None, captured_logs: list[str], sentinel_api_key: str
    ) -> None:
        """The provider credential stays out of everything the process writes."""
        # Article I: not in a log, not in a traceback. This is the log half; the Sentry half
        # is in tests/unit/test_secret_scrubbing.py.
        await _call("/api/health")

        assert sentinel_api_key not in "\n".join(captured_logs)


class TestMetricsAreExposed:
    """The numbers that make Article II verifiable from outside."""

    async def test_metrics_endpoint_speaks_prometheus(self, database_is_reachable: None) -> None:
        """Prometheus can scrape the endpoint without a translation layer."""
        status_code, body, headers = await _call("/metrics")

        assert status_code == 200
        assert "text/plain" in headers.get("content-type", "")
        # Prometheus exposition format: a HELP line per family.
        assert "# HELP" in body

    @pytest.mark.parametrize(
        "metric",
        [
            "provider_requests_total",
            "quote_cache_hits_total",
            "quote_cache_misses_total",
            "provider_quota_remaining",
        ],
    )
    async def test_the_quota_metrics_exist(self, metric: str, database_is_reachable: None) -> None:
        """The four counters that answer where the daily quota went."""
        # These four are the ones that make Article II verifiable. The generic per-route
        # metrics matter less: any framework gives those away.
        _, body, _ = await _call("/metrics")

        assert metric in body

    async def test_http_requests_are_counted_by_route(self, database_is_reachable: None) -> None:
        """Rate, errors and duration per route, the baseline of any service."""
        await _call("/api/health")

        _, body, _ = await _call("/metrics")

        assert "http_requests_total" in body
