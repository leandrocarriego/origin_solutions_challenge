"""Favourite stocks: the grid of My Actions, and adding and removing from it.

What `__all__` declares is the contract: the router the composition root mounts, and the one
question another module may ask -- whether a symbol is on somebody's list (RF-35). The grid, the
decisions behind it and the access to `user_stocks` stay interior: `is_favorite` answers a
boolean, so no other module reads a row of somebody's list.
"""

from app.modules.favorites.router import router
from app.modules.favorites.service import is_favorite

__all__ = ["is_favorite", "router"]
