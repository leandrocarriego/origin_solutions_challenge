"""Observability: structured logs, request correlation, metrics and error reporting (ADR-009).

Kernel package: imports no module (`GEN-03`).

It grew from a file to a directory of the same name, which is the shape `CONVENTIONS.md` gives a
piece that outgrew one screen -- and this `__init__` is why nothing outside it had to change: it
is the contract, and it exports exactly what the file exported.

Four files, and each one answers a different question:

- `metrics.py` -- what Article II is checked against, and the endpoint Prometheus scrapes.
- `logs.py` -- how a line is written, and how anything gets a logger.
- `middleware.py` -- the request id, bound for the length of a request.
- `sentry.py` -- what gets reported, and what is blanked out before it leaves.

What this re-exports is the same list the file exported, name for name. Everything else those
four files hold -- `DAILY_QUOTA`, `REQUEST_ID_HEADER`, `bind_request_id`, `get_logger` -- is
reached by its own path or not at all, which is what it already was: a module attribute nobody
imported.
"""

from app.observability.logs import configure_logging
from app.observability.metrics import (
    CATALOGUE_LAST_SUCCESS,
    LOGIN_ATTEMPTS,
    PROVIDER_QUOTA_REMAINING,
    PROVIDER_REQUESTS,
    QUOTE_CACHE_HITS,
    QUOTE_CACHE_MISSES,
    router,
)
from app.observability.middleware import RequestContextMiddleware
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
