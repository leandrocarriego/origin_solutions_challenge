"""Health endpoint: what the deploy and the reverse proxy ask the API about itself."""

from typing import Any

import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app


async def _get_health() -> tuple[int, dict[str, Any]]:
    """Call GET /api/health against the ASGI app, with no network involved."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/api/health")
    return response.status_code, response.json()


class TestHealthReportsLiveness:
    """Health answers 200 while the process can serve."""

    async def test_responds_200_when_the_database_answers(
        self, database_is_reachable: None
    ) -> None:
        """The happy path, and the shape of the body."""
        status_code, body = await _get_health()

        assert status_code == 200
        assert body["status"] == "ok"
        assert body["database"] == "ok"

    async def test_reports_the_running_version(self, database_is_reachable: None) -> None:
        """The deploy can be identified without opening an SSH session."""
        _, body = await _get_health()

        # The deploy has to be able to answer "what is running there?" without an SSH session.
        assert body["version"], "health has to say which version is deployed"


class TestHealthReportsDegradation:
    """Health tells the truth when a dependency is down."""

    async def test_responds_503_when_the_database_is_unreachable(
        self, database_is_unreachable: None
    ) -> None:
        """A degraded process says so, so the proxy stops sending it traffic."""
        # Answering 200 with the database down is worse than having no health at all: the
        # reverse proxy would keep sending traffic to an instance that can serve nothing.
        status_code, body = await _get_health()

        assert status_code == 503
        assert body["status"] == "degraded"
        assert body["database"] == "unavailable"

    async def test_never_leaks_the_connection_string(self, database_is_unreachable: None) -> None:
        """The failure path is where a credential would surface first."""
        # Article I: the credential does not leave, not even inside an error. The DSN carries
        # the password, so the degraded answer is where a leak would show up first.
        _, body = await _get_health()

        serialized = str(body)
        assert "postgres://" not in serialized
        assert "postgresql" not in serialized
        assert "password" not in serialized.lower()


class TestHealthIsPublic:
    """The proxy polls health without carrying a token."""

    async def test_does_not_require_authentication(self, database_is_reachable: None) -> None:
        """Health stays reachable for callers that cannot authenticate."""
        # This is the route the proxy polls, and the proxy carries no token. It belongs in
        # PUBLIC_ROUTES with its reason written down (PY-08).
        status_code, _ = await _get_health()

        assert status_code != 401
        assert status_code != 403


@pytest.mark.parametrize("method", ["post", "put", "patch", "delete"])
class TestHealthIsReadOnly:
    """Health reports state and never changes it."""

    async def test_rejects_write_methods(self, method: str, database_is_reachable: None) -> None:
        """Write verbs are refused, not silently ignored."""
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            response = await getattr(client, method)("/api/health")

        assert response.status_code == 405
