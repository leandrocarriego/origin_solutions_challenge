"""The request id, bound for the length of a request and returned in the response.

It is the seam where the three other files meet: it binds what `logs` configured, it fills the
counters of `metrics`, and what it writes is what makes a Sentry event findable afterwards. That
is why it is its own file rather than part of any of them.
"""

import time
import uuid
from typing import Any

import structlog
from starlette.requests import Request
from starlette.types import ASGIApp

from app.observability.metrics import HTTP_DURATION, HTTP_REQUESTS

REQUEST_ID_HEADER = "X-Request-ID"


class RequestContextMiddleware:
    """Give every request an id, put it in the logs, and return it in the response."""

    def __init__(self, app: ASGIApp) -> None:
        """Wrap the ASGI application."""
        self.app = app

    async def __call__(self, scope: Any, receive: Any, send: Any) -> None:
        """Bind the id for the duration of the request and time the response."""
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        request = Request(scope)
        # An id may already exist upstream: Traefik or the client. Generating a second one
        # would break the chain exactly where it matters most, at the proxy boundary.
        request_id = request.headers.get(REQUEST_ID_HEADER) or str(uuid.uuid4())
        route = scope.get("path", "unknown")
        method = scope.get("method", "unknown")

        structlog.contextvars.clear_contextvars()
        structlog.contextvars.bind_contextvars(request_id=request_id)
        logger = structlog.get_logger()
        started = time.perf_counter()
        status_code = 500

        async def _send(message: Any) -> None:
            nonlocal status_code
            if message["type"] == "http.response.start":
                status_code = message["status"]
                headers = message.setdefault("headers", [])
                headers.append((REQUEST_ID_HEADER.lower().encode(), request_id.encode()))
            await send(message)

        try:
            await self.app(scope, receive, _send)
        finally:
            elapsed = time.perf_counter() - started
            # /metrics is excluded from its own counters: a scrape every fifteen seconds would
            # drown the numbers that describe real traffic.
            if route != "/metrics":
                HTTP_REQUESTS.labels(method=method, route=route, status=str(status_code)).inc()
                HTTP_DURATION.labels(method=method, route=route).observe(elapsed)
            logger.info(
                "http_request",
                method=method,
                route=route,
                status=status_code,
                duration_ms=round(elapsed * 1000, 2),
            )
            structlog.contextvars.clear_contextvars()
