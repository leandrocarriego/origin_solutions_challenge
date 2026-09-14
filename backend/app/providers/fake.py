"""A provider that answers without a network, so the suite can run without one."""

from datetime import datetime, timedelta
from decimal import Decimal

from app.providers.base import MarketDataProvider
from app.providers.schemas import QuotePoint, StockRecord

# A catalogue small enough to read and large enough to exercise what matters.
_CATALOGUE = (
    ("TSLA", "Tesla, Inc.", "NASDAQ", "XNGS", "Common Stock"),
    ("AAPL", "Apple Inc.", "NASDAQ", "XNGS", "Common Stock"),
    ("NFLX", "Netflix Inc.", "NASDAQ", "XNGS", "Common Stock"),
    ("!otc/FLZH", "Flash Sports & Media, Inc.", "NASDAQ", "XNCM", "Common Stock"),
    ("A", "Agilent Technologies Inc.", "NYSE", "XNYS", "Common Stock"),
    ("ABR-D", "Arbor Realty Trust", "NYSE", "XNYS", "REIT"),
    ("ACHR.WT", "Archer Aviation Inc. Warrant", "NYSE", "XNYS", "Warrant"),
)

_MINUTES = {"1min": 1, "5min": 5, "15min": 15}

# How many candles a window gets at most. Enough to draw a chart, small enough to read a failure.
_POINTS = 30


class FakeProvider(MarketDataProvider):
    """The contract, answered from a table and a formula."""

    async def list_stocks(self, exchange: str) -> list[StockRecord]:
        """The rows of the built-in catalogue for that market."""
        return [
            StockRecord(
                symbol=symbol,
                name=name,
                currency="USD",
                exchange=market,
                mic_code=mic,
                country="United States",
                instrument_type=instrument,
            )
            for symbol, name, market, mic, instrument in _CATALOGUE
            if market == exchange.upper()
        ]

    async def get_time_series(
        self, symbol: str, interval: str, start: datetime, end: datetime
    ) -> list[QuotePoint]:
        """A series derived from the symbol and the window, identical on every call."""
        step = timedelta(minutes=_MINUTES.get(interval, 1))
        base = Decimal(100 + sum(symbol.encode()) % 400)

        points: list[QuotePoint] = []
        instant = start

        while instant <= end and len(points) < _POINTS:
            # A small deterministic wobble, so a chart drawn from this is not a flat line.
            offset = Decimal(len(points) % 7) - Decimal(3)
            close = base + offset
            points.append(
                QuotePoint(
                    ts=instant,
                    open=close - Decimal("0.5"),
                    high=close + Decimal("0.75"),
                    low=close - Decimal("0.75"),
                    close=close,
                    volume=100_000 + len(points) * 137,
                )
            )
            instant += step

        return points


def build(api_key: str, client: object | None = None) -> MarketDataProvider:
    """Build this provider. The credential and the client are ignored: it reaches nothing."""
    return FakeProvider()
