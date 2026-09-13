"""What the ingestion keeps, and what it drops before anything reaches the table.

This is not housekeeping: `ADR-001` chose `symbol` as the natural primary key of `stocks`, and
that key is only true because of this filter. It was measured, not assumed -- over the 7.572 rows
of NYSE plus NASDAQ on 2026-09-13 there is exactly one duplicated symbol and it is a warrant, and
exactly one symbol that cannot survive a URL segment.

Two rules, and the reason for each:

  - warrants are derivatives, not stocks, and they are the only thing that duplicates a symbol;
  - the symbol travels in the URL (REQ-11), so a slash in it is not a symbol, it is a route.
"""

import pytest

from app.modules.stocks.service import is_worth_ingesting
from app.providers import StockRecord


def entry(symbol: str, instrument_type: str = "Common Stock") -> StockRecord:
    """A catalogue row with only the two fields the filter looks at."""
    return StockRecord(
        symbol=symbol,
        name="A Company, Inc.",
        currency="USD",
        exchange="NASDAQ",
        mic_code="XNGS",
        country="United States",
        instrument_type=instrument_type,
    )


class TestTheSymbolHasToSurviveAUrl:
    """REQ-11 puts the symbol in the path, so what cannot be a path segment is not a symbol."""

    @pytest.mark.parametrize("symbol", ["TSLA", "AAPL", "NFLX", "A"])
    def test_the_symbols_of_the_wireframe_are_kept(self, symbol: str) -> None:
        """If the filter dropped any of these, the brief's own screen could not be reproduced."""
        assert is_worth_ingesting(entry(symbol))

    @pytest.mark.parametrize("symbol", ["AAC.UN", "ABR-D", "BRK.B"])
    def test_a_dot_and_a_dash_are_kept(self, symbol: str) -> None:
        """Both are legal inside a path segment, and dropping them would lose real companies."""
        assert is_worth_ingesting(entry(symbol))

    def test_a_symbol_with_a_slash_is_dropped(self) -> None:
        """`!otc/FLZH` is a real row of the catalogue and it would become two path segments."""
        assert not is_worth_ingesting(entry("!otc/FLZH"))

    @pytest.mark.parametrize("symbol", ["", "tsla", "TOOLONGSYMBOL", ".AAPL", "-AAPL"])
    def test_anything_that_is_not_a_plain_ticker_is_dropped(self, symbol: str) -> None:
        """Empty, lowercase, too long, or starting with punctuation: none of those is a ticker."""
        assert not is_worth_ingesting(entry(symbol))


class TestOnlyWarrantsAreDroppedByType:
    """Only the derivative goes.

    ADR-001 rejected a Common-Stock-only filter: it threw away 607 rows that collide with
    nothing.
    """

    def test_a_warrant_is_dropped(self) -> None:
        """A derivative is not a stock, and it is the only type that duplicates a symbol."""
        assert not is_worth_ingesting(entry("ACHRWT", "Warrant"))

    @pytest.mark.parametrize(
        "instrument_type",
        ["Common Stock", "REIT", "American Depositary Receipt", "Preferred Stock", "Unit"],
    )
    def test_everything_else_is_kept(self, instrument_type: str) -> None:
        """393 ADRs and 214 REITs are companies someone may search for: the filter is narrow."""
        assert is_worth_ingesting(entry("ABEV", instrument_type))
