"""The contract every market data provider implements."""

from abc import ABC, abstractmethod
from datetime import datetime

from app.providers.schemas import QuotePoint, StockRecord


class MarketDataProvider(ABC):
    """What a service knows about the outside world."""

    @abstractmethod
    async def list_stocks(self, exchange: str) -> list[StockRecord]:
        """Every symbol the provider lists for a market, unfiltered."""

    @abstractmethod
    async def get_time_series(
        self, symbol: str, interval: str, start: datetime, end: datetime
    ) -> list[QuotePoint]:
        """The candles of a symbol in a window, oldest first."""
