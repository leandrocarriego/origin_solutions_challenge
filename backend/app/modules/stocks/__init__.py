"""The catalogue: ingestion, search and everything that describes a symbol.

What `__all__` declares is the contract: the background refresh the composition root starts, the
router it mounts, and the batch lookup `favorites` paints its grid with. Everything else of the
package -- service, repository, models, schemas -- is interior, visible to its siblings and
invisible to the rest of the system. `search_stocks` in particular is not exported: only this
module's own router consumes it.
"""

from app.modules.stocks.router import router
from app.modules.stocks.service import StockInfo, get_stocks, keep_the_catalogue_fresh

__all__ = ["StockInfo", "get_stocks", "keep_the_catalogue_fresh", "router"]
