"""Structured logs, request correlation, metrics and error reporting."""

from app.observability.logs import configure_logging
from app.observability.metrics import (
    CATALOGUE_LAST_SUCCESS,
    LOGIN_ATTEMPTS,
    PROVIDER_QUOTA_REMAINING,
    PROVIDER_REQUESTS,
    QUOTE_CACHE_HITS,
    QUOTE_CACHE_MISSES,
)
from app.observability.middleware import RequestContextMiddleware
from app.observability.router import router
from app.observability.sentry import configure_sentry, scrub_secrets

__all__ = [
    "CATALOGUE_LAST_SUCCESS",
    "LOGIN_ATTEMPTS",
    "PROVIDER_QUOTA_REMAINING",
    "PROVIDER_REQUESTS",
    "QUOTE_CACHE_HITS",
    "QUOTE_CACHE_MISSES",
    "RequestContextMiddleware",
    "configure_logging",
    "configure_sentry",
    "router",
    "scrub_secrets",
]
