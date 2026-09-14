"""
This package is the only one that interacts with an HTTP client.

It outputs types—such as `MarketDataProvider`, rather than the
raw JSON sent by the provider—and the name of the provider in use
appears in a single file within the package; consequently,
dependency configuration resolves it using that name.
"""

from app.providers.base import MarketDataProvider
from app.providers.errors import (
    ProviderError,
    ProviderQuotaExceeded,
    ProviderRejectedCredentials,
    ProviderUnavailable,
    SymbolNotFound,
)
from app.providers.fake import FakeProvider
from app.providers.registry import (
    UnknownProvider,
    build_upstream_provider,
    get_market_data_provider,
)
from app.providers.schemas import QuotePoint, StockRecord

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
