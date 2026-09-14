"""What the favourites decide, before HTTP and before SQL."""

from collections.abc import Awaitable, Callable
from typing import Protocol

from sqlalchemy.ext.asyncio import AsyncSession

from app.db import SessionDep
from app.errors import UnknownSymbolError
from app.modules.favorites.repository import FavoritesRepository
from app.modules.favorites.schemas import FavoriteAddition, FavoriteStock
from app.modules.stocks import StockInfo, get_stocks


class FavoritesStore(Protocol):
    """What this module needs from whatever holds a list of favourites.

    Declared here and not next to the implementation on purpose: the abstraction belongs to
    whoever depends on it, so the service names what it needs and the repository is one way of
    answering it. A test passes another, and patches nothing.
    """

    async def symbols_of(self, user_id: int) -> list[str]:
        """The symbols that user follows, most recently added first."""
        ...

    async def add(self, user_id: int, symbol: str) -> bool:
        """Make that user follow that symbol, and say whether the row was created."""
        ...

    async def remove(self, user_id: int, symbol: str) -> None:
        """Stop that user following that symbol, if they were."""
        ...

    async def follows(self, user_id: int, symbol: str) -> bool:
        """Whether that user follows that symbol."""
        ...


# The one question this module asks the catalogue, with the session already bound so nothing
# below the router has to carry one.
Catalogue = Callable[[list[str]], Awaitable[list[StockInfo]]]


def favorites_store(session: SessionDep) -> FavoritesStore:
    """The store a route is served with."""
    return FavoritesRepository(session)


def catalogue(session: SessionDep) -> Catalogue:
    """The catalogue lookup a route is served with, bound to its session."""

    async def look_up(symbols: list[str]) -> list[StockInfo]:
        return await get_stocks(session, symbols)

    return look_up


async def list_favorites(
    store: FavoritesStore, described_by: Catalogue, user_id: int
) -> list[FavoriteStock]:
    """List the symbols that user follows, with their name and currency."""
    symbols = await store.symbols_of(user_id)
    described = {info.symbol: info for info in await described_by(symbols)}

    return [
        FavoriteStock(
            symbol=info.symbol,
            name=info.name,
            currency=info.currency,
        )
        for symbol in symbols
        if (info := described.get(symbol)) is not None
    ]


async def add_favorite(
    store: FavoritesStore, described_by: Catalogue, user_id: int, symbol: str
) -> FavoriteAddition:
    """Add that symbol to that user's list, or say it cannot be added."""
    wanted = symbol.strip().upper()

    described = await described_by([wanted])

    offered = next((info for info in described if info.is_listed), None)

    if offered is None:
        raise UnknownSymbolError

    created = await store.add(user_id, wanted)

    return FavoriteAddition(
        created=created,
        favorite=FavoriteStock(symbol=offered.symbol, name=offered.name, currency=offered.currency),
    )


async def remove_favorite(store: FavoritesStore, user_id: int, symbol: str) -> None:
    """Stop following that symbol, whether or not it was on the list."""
    await store.remove(user_id, symbol.strip().upper())


async def is_favorite(session: AsyncSession, user_id: int, symbol: str) -> bool:
    """Whether that symbol is on that user's list.

    The one entry another module uses, so it takes a session and builds its own store: what holds
    a favourite is this module's business and nobody else's.
    """
    return await FavoritesRepository(session).follows(user_id, symbol.strip().upper())
