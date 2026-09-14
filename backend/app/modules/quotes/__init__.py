"""Quotes: the series a chart is drawn from, the cache that pays for it and its failure modes.

What `__all__` declares is the contract, and it is the router the composition root mounts.
Everything else -- the freshness rule, the gate, the four states and the access to `quotes` --
is interior: no other module needs a series of prices, and a name exported for nobody is
surface to keep.
"""

from app.modules.quotes.router import router

__all__ = ["router"]
