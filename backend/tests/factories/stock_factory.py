"""Factory of `stocks` rows, which is the table the catalogue module owns.

The defaults describe a listed symbol, because that is what almost every test needs. The two
columns of ADR-002 are the ones worth overriding: `delisted_at` is what turns a row into a
symbol that stopped trading, and that single value is the difference between "it is offered by
the autocomplete" and "it only survives in the grid of whoever already had it".
"""

from datetime import UTC, datetime

from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.stocks.models import Stock

# A fixed instant instead of `now()`: two rows created in the same test must be comparable, and
# a test that reads differently depending on the clock is a test that fails at midnight.
SEEN_AT = datetime(2026, 9, 13, 12, 0, tzinfo=UTC)


class StockFactory:
    """Rows of `stocks`, listed unless the test says otherwise."""

    @staticmethod
    async def create(session: AsyncSession, **kwargs: object) -> Stock:
        """Insert one catalogue row, defaulting to the symbol of the brief's own wireframe.

        The name is derived from the symbol unless the test gives one, so a row built for a
        second symbol does not silently carry the first one's name into an assertion.
        """
        symbol = kwargs.get("symbol", "TSLA")
        defaults: dict[str, object] = {
            "symbol": symbol,
            "name": f"{symbol} Inc",
            "currency": "USD",
            "exchange": "NASDAQ",
            "mic_code": "XNGS",
            "country": "United States",
            "instrument_type": "Common Stock",
            "last_seen_at": SEEN_AT,
            "delisted_at": None,
        }
        defaults.update(kwargs)

        stock = Stock(**defaults)
        session.add(stock)
        await session.flush()

        return stock

    @staticmethod
    async def ensure(session: AsyncSession, symbol: str, **kwargs: object) -> Stock:
        """Return the catalogue row for that symbol, creating it if it is not there yet.

        It exists for the favourites factory: `user_stocks.symbol` is a foreign key, so a
        favourite cannot be inserted for a symbol the catalogue does not have. Delegating here
        is what keeps that factory from writing another module's table by hand.
        """
        existing = await session.get(Stock, symbol)
        if existing is not None:
            return existing

        return await StockFactory.create(session, symbol=symbol, **kwargs)
