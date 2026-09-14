"""Favourite stocks: the grid of My Actions, and adding and removing from it.

What `__all__` declares is the contract, and today it is the router the composition root mounts.
The grid, the decisions behind it and the access to `user_stocks` are interior: no other module
has any business reading somebody's list.
"""

from app.modules.favorites.router import router

__all__ = ["router"]
