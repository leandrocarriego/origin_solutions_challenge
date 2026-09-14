"""The catalogue: ingestion, search and everything that describes a symbol.

The contract is the background refresh the composition root starts, the router it mounts, and
the batch lookup `favorites` paints its grid with. Everything else is interior: `search_stocks`
in particular is not exported, because only this module's own router consumes it.
"""

from app.modules.stocks.router import router
from app.modules.stocks.service import StockInfo, get_stocks, keep_the_catalogue_fresh

__all__ = ["StockInfo", "get_stocks", "keep_the_catalogue_fresh", "router"]
