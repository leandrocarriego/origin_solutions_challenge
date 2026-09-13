"""Observability: structured logs, request correlation, metrics and error reporting (ADR-009).

Kernel file: imports no module (GEN-03).

The four counters at the bottom are the point of all this. Article II claims that provider
consumption scales with distinct symbols observed and not with clients connected; without them
that claim is a sentence in a README that nobody can check. ERR-07 asks for the same thing in
prose: being able to answer where the 800 daily requests went.
"""

import logging
import re
import sys
import time
import uuid
from collections.abc import Awaitable, Callable
from typing import Any, TextIO

import sentry_sdk
import structlog
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Gauge, Histogram, generate_latest
from sentry_sdk.integrations.asyncio import AsyncioIntegration
from sentry_sdk.integrations.fastapi import FastApiIntegration
from sentry_sdk.types import Event, Hint
from starlette.requests import Request
from starlette.responses import PlainTextResponse, Response
from starlette.types import ASGIApp

from app.settings import get_settings

__all__ = [
    "PROVIDER_QUOTA_REMAINING",
    "PROVIDER_REQUESTS",
    "QUOTE_CACHE_HITS",
    "QUOTE_CACHE_MISSES",
    "RequestContextMiddleware",
    "configure_logging",
    "configure_sentry",
    "metrics_endpoint",
    "scrub_secrets",
]

REQUEST_ID_HEADER = "X-Request-ID"

# The daily allowance of the provider's free plan. Lives here and not in Settings because it is
# a fact about the plan, not something an operator gets to configure away.
DAILY_QUOTA = 800


# --- Metrics -----------------------------------------------------------------------------------
# Article II made countable.

PROVIDER_REQUESTS = Counter(
    "provider_requests_total",
    "Calls that actually left for the provider, by symbol, interval and outcome.",
    ["symbol", "interval", "outcome"],
)

QUOTE_CACHE_HITS = Counter(
    "quote_cache_hits_total",
    "Quote requests served from the database without touching the provider.",
)

QUOTE_CACHE_MISSES = Counter(
    "quote_cache_misses_total",
    "Quote requests that found a gap and had to spend quota.",
)

PROVIDER_QUOTA_REMAINING = Gauge(
    "provider_quota_remaining",
    "Requests left in today's provider allowance.",
)

HTTP_REQUESTS = Counter(
    "http_requests_total",
    "HTTP requests served, by method, route and status.",
    ["method", "route", "status"],
)

HTTP_DURATION = Histogram(
    "http_request_duration_seconds",
    "How long each request took, by method and route.",
    ["method", "route"],
)

PROVIDER_QUOTA_REMAINING.set(DAILY_QUOTA)


# --- Logging -----------------------------------------------------------------------------------


def configure_logging(stream: TextIO | Any | None = None) -> None:
    """Emit one JSON object per line, with the request id already merged in."""
    structlog.configure(
        processors=[
            structlog.contextvars.merge_contextvars,
            structlog.processors.add_log_level,
            structlog.processors.TimeStamper(fmt="iso", utc=True),
            structlog.processors.StackInfoRenderer(),
            structlog.processors.format_exc_info,
            structlog.processors.JSONRenderer(),
        ],
        logger_factory=structlog.PrintLoggerFactory(file=stream or sys.stdout),
        cache_logger_on_first_use=False,
    )
    # Everything that logs through the standard library --uvicorn, sqlalchemy-- goes to the same
    # stream, so a request never spans two formats.
    logging.basicConfig(format="%(message)s", stream=stream or sys.stdout, level=logging.INFO)


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


async def metrics_endpoint(request: Request) -> Response:
    """Expose the registry in Prometheus text format."""
    return PlainTextResponse(generate_latest(), media_type=CONTENT_TYPE_LATEST)


# --- Error reporting ---------------------------------------------------------------------------

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
    """Collect the literal secrets this process knows about."""
    settings = get_settings()
    values = [settings.twelvedata_api_key]

    # The DSN's password, which is what a SQLAlchemy traceback carries.
    match = re.search(r"://[^:/@]+:([^@]+)@", settings.database_url)
    if match:
        values.append(match.group(1))

    return tuple(value for value in values if len(value) >= _MIN_SECRET_LENGTH)


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
        environment=settings.sentry_environment,
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


def bind_request_id(request_id: str) -> None:
    """Attach an id to everything logged from here on in this context."""
    structlog.contextvars.bind_contextvars(request_id=request_id)


def get_logger(name: str | None = None) -> Any:
    """Return the structured logger every module should use instead of print (ERR-03)."""
    return structlog.get_logger(name)


Middleware = Callable[..., Awaitable[None]]
