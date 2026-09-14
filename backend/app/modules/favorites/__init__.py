"""Favourite stocks: the grid of My Actions, and adding and removing from it.

The contract is the router, and the one question another module may ask: whether a symbol is on
somebody's list. `is_favorite` answers a boolean, so no other module reads a row of one.
"""

from app.modules.favorites.router import router
from app.modules.favorites.service import is_favorite

__all__ = ["is_favorite", "router"]
