"""The catalogue: ingestion, search and everything that describes a symbol.

What it exports today is the background refresh, which the composition root starts. The rest of
the module -- `get_stocks(symbols) -> list[StockInfo]`, the router -- arrives with
`002-favorite-stocks`.
"""

from app.modules.stocks.service import keep_the_catalogue_fresh

__all__ = ["keep_the_catalogue_fresh"]
