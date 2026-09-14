"""Favourite stocks: the grid of My Actions, and adding and removing from it."""

from app.modules.favorites.router import router
from app.modules.favorites.service import is_favorite

__all__ = ["is_favorite", "router"]
