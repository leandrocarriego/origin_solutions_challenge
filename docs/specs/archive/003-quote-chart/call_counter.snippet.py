
class _CallCounter(MarketDataProvider):
    """A provider that answers nothing and remembers every time it was asked."""

    def __init__(self) -> None:
        """Start with no calls recorded: what is under test is that there are none."""
        self.calls: list[tuple[str, str]] = []

    async def list_stocks(self, exchange: str) -> list[StockRecord]:
        """Not what the chart asks for."""
        return []

    async def get_time_series(
        self, symbol: str, interval: str, start: datetime, end: datetime
    ) -> list[QuotePoint]:
        """Record the call, then answer with nothing: reaching here is already the failure."""
        self.calls.append((symbol, interval))

        return []
