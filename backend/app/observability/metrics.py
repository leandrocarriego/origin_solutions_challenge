"""The numbers the quota is checked against."""

from prometheus_client import Counter, Gauge, Histogram

# The daily allowance of the provider's free plan. Lives here and not in Settings because it is
# a fact about the plan, not something an operator gets to configure away.
DAILY_QUOTA = 800


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

# Without it a brute-force attempt is indistinguishable from silence: the request counter below
# sees ten 401s and cannot say whether somebody is guessing. The label is the outcome and nothing
# else -- a metric label becomes a time series that is kept for weeks.
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
