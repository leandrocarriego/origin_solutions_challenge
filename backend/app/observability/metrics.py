"""The numbers Article II is checked against, and the endpoint Prometheus reads them from.

The counters are the point of the whole package. Article II claims that provider consumption
scales with distinct symbols observed and not with clients connected; without these that claim is
a sentence in a README that nobody can check. `ERR-07` asks for the same thing in prose: being
able to answer where the 800 daily requests went.

They are defined at import and never rebuilt: a Prometheus collector is registered once per
process, and a second registration of the same name raises.
"""

from prometheus_client import CONTENT_TYPE_LATEST, Counter, Gauge, Histogram, generate_latest
from starlette.requests import Request
from starlette.responses import PlainTextResponse, Response

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

CATALOGUE_LAST_SUCCESS = Gauge(
    "catalogue_last_success_timestamp_seconds",
    "When the catalogue was last reconciled against the provider, as a unix timestamp.",
)

# OWASP A09, and ERR-03 in numbers. Without it a brute-force attempt is indistinguishable from
# silence: the request counter below sees ten 401s on a route and cannot say whether somebody is
# guessing. The label is the outcome and nothing else -- no username, no address, and above all
# no credential, because a metric label becomes a time series that is kept for weeks.
LOGIN_ATTEMPTS = Counter(
    "login_attempts_total",
    "Login attempts, by outcome: succeeded, failed or rate_limited.",
    ["outcome"],
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


async def metrics_endpoint(request: Request) -> Response:
    """Expose the registry in Prometheus text format."""
    return PlainTextResponse(generate_latest(), media_type=CONTENT_TYPE_LATEST)
