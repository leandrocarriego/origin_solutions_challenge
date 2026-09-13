"""Infrastructure: the way out to the world, behind an interface (GEN-08).

This package is the only place that talks to an HTTP client. What leaves it are the types of
`MarketDataProvider` and never the JSON a provider sent, and the name of the provider in use
appears in exactly one file inside it -- which is why the wiring resolves it by name.
"""

from app.providers.base import (
    MarketDataProvider,
    ProviderError,
    ProviderQuotaExceeded,
    ProviderRejectedCredentials,
    ProviderUnavailable,
    QuotePoint,
    StockRecord,
    SymbolNotFound,
)
from app.providers.fake import FakeProvider
from app.providers.registry import (
    UnknownProvider,
    build_upstream_provider,
    get_market_data_provider,
)

__all__ = [
    "FakeProvider",
    "MarketDataProvider",
    "ProviderError",
    "ProviderQuotaExceeded",
    "ProviderRejectedCredentials",
    "ProviderUnavailable",
    "QuotePoint",
    "StockRecord",
    "SymbolNotFound",
    "UnknownProvider",
    "build_upstream_provider",
    "get_market_data_provider",
]
