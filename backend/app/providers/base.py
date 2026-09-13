"""The contract every market data provider implements (ADR-006).

An abstract base class and not a `Protocol`: forgetting a method fails when someone tries to
build the object, and the error exists whether or not anyone runs `mypy`. The cost is that the
implementations import and inherit this, which with two of them is cheap.

The types here are ours. A provider that handed back the JSON it received would push parsing
into the services, and a change of format upstream would then break every test that never talks
about format.
"""

from abc import ABC, abstractmethod
from dataclasses import dataclass
from datetime import datetime
from decimal import Decimal


class ProviderError(Exception):
    """Anything that kept the provider from answering.

    The four subclasses exist because ADR-005 has to tell them apart: running out of quota is
    served from the cache with a notice, an unknown symbol is not, and a rejected credential is
    ours to fix. A single exception would collapse three different screens into one.
    """


class ProviderUnavailable(ProviderError):
    """No answer: the upstream is down, timed out, or replied with something unreadable."""


class ProviderQuotaExceeded(ProviderError):
    """The Article II quota is spent. The cache answers, with a notice on top."""


class ProviderRejectedCredentials(ProviderError):
    """The API key is missing or wrong. This one is a misconfiguration, not an outage."""


class SymbolNotFound(ProviderError):
    """The provider has no data for that symbol, which is about the request and not the service."""


@dataclass(frozen=True, slots=True)
class StockRecord:
    """One entry of a provider's catalogue, in the shape `stocks` stores (ADR-001)."""

    symbol: str
    name: str
    currency: str
    exchange: str
    mic_code: str
    country: str
    instrument_type: str


@dataclass(frozen=True, slots=True)
class QuotePoint:
    """One candle of a series, in the shape `quotes` stores (ADR-001)."""

    ts: datetime
    open: Decimal
    high: Decimal
    low: Decimal
    close: Decimal
    volume: int | None


class MarketDataProvider(ABC):
    """What a service knows about the outside world.

    Two methods, and no search: the autocomplete queries Postgres against the ingested catalogue
    (ADR-002), so searching is not a capability of the provider.
    """

    @abstractmethod
    async def list_stocks(self, exchange: str) -> list[StockRecord]:
        """Every symbol the provider lists for a market, unfiltered.

        Unfiltered on purpose: which rows are worth keeping is the ingestion's decision
        (ADR-001), and a client that drops rows makes that decision invisible.
        """

    @abstractmethod
    async def get_time_series(
        self, symbol: str, interval: str, start: datetime, end: datetime
    ) -> list[QuotePoint]:
        """The candles of a symbol in a window, oldest first."""
