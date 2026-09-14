"""What the favourites decide, before HTTP and before SQL.

The grid is painted from two sources and neither one is optional: `user_stocks` says *which*
symbols somebody follows, and the catalogue says what each of them is called and in what
currency it trades. The favourites table stores neither of those two on purpose (ADR-001) --
they live in `stocks`, once, where the ingestion keeps them current.

The catalogue is entered through its package and in a single call: the grid of N favourites is
one question and not N (GEN-02).
"""

from dataclasses import dataclass

from sqlalchemy.ext.asyncio import AsyncSession

from app.errors import UnknownSymbolError
from app.modules.favorites.repository import add, follows, remove, symbols_of
from app.modules.stocks import get_stocks


@dataclass(frozen=True, slots=True)
class FavoriteStock:
    """One row of the grid: the three columns of RF-03 and nothing else.

    Whether the symbol still trades does not travel: a favourite is shown either way, so a field
    nobody reads would be surface to keep. That decision is `stocks`' to publish and this
    module's to ignore.
    """

    symbol: str
    name: str
    currency: str


async def list_favorites(session: AsyncSession, user_id: int) -> list[FavoriteStock]:
    """The grid of that user, in the order the repository already decided (RF-01, RF-06).

    The catalogue answers a *set*: `get_stocks` promises a batch lookup and nothing about the
    sequence of what comes back. So the order of the grid is decided here, by walking the
    symbols in the order they were asked for -- forwarding the catalogue's answer would paint
    RF-06 wrong while every test that only checks membership stayed green.
    """
    symbols = await symbols_of(session, user_id)
    described = {info.symbol: info for info in await get_stocks(session, symbols)}

    return [
        FavoriteStock(
            symbol=info.symbol,
            name=info.name,
            currency=info.currency,
        )
        for symbol in symbols
        if (info := described.get(symbol)) is not None
    ]


@dataclass(frozen=True, slots=True)
class FavoriteAddition:
    """What one add did: whether it created the row, and the row itself.

    The boolean is the decision of the business and the status is its translation to the
    transport, which is the router's job (PY-06). A service that answered 201 would already be
    speaking HTTP.
    """

    created: bool
    favorite: FavoriteStock


async def add_favorite(session: AsyncSession, user_id: int, symbol: str) -> FavoriteAddition:
    """Add that symbol to that user's list, or say it cannot be added (RF-15, RF-17, RF-18).

    **The catalogue is asked before anything is written**, and the order matters: the other way
    round, the foreign key would refuse an unknown symbol with an `IntegrityError` that somebody
    has to translate, and a delisted one would be written happily -- it is a perfectly good row
    of `stocks`.

    Normalising lives here, in one place, for the same rule to hold for the add and for the
    delete: `strip().upper()` before looking, because the catalogue stores upper case and
    `get_stocks` does not normalise on purpose.

    Absent and delisted are the same refusal (`UnknownSymbolError`): the person could only have
    chosen from what the autocomplete suggested, so both mean "that is not on offer".
    """
    wanted = symbol.strip().upper()

    described = await get_stocks(session, [wanted])
    offered = next((info for info in described if info.is_listed), None)
    if offered is None:
        raise UnknownSymbolError

    created = await add(session, user_id, wanted)

    return FavoriteAddition(
        created=created,
        favorite=FavoriteStock(symbol=offered.symbol, name=offered.name, currency=offered.currency),
    )


async def remove_favorite(session: AsyncSession, user_id: int, symbol: str) -> None:
    """Stop following that symbol, whether or not it was on the list (RF-24).

    **It cannot fail**, and that is the decision: somebody who removes twice wants the same thing
    both times, so there is no exception here and no 404 to translate. A refusal would also leak
    something -- it would tell a caller whether a symbol was on *somebody's* list -- and the
    filter by user already covers that.

    The same normalisation as the add, for the same reason it lives here: one rule, one place. The
    catalogue is not consulted at all -- removing is about this user's list, and the symbol stays
    in `stocks` to be suggested again (RF-27).
    """
    await remove(session, user_id, symbol.strip().upper())


async def is_favorite(session: AsyncSession, user_id: int, symbol: str) -> bool:
    """Whether that symbol is on that user's list (RF-35).

    The one thing this module answers to another one, and it answers a boolean: who follows what
    is `favorites`' to know, and a chart is served only for the acciones of whoever is asking.
    Letting `quotes` read `user_stocks` itself would be the boundary Article IV refuses, with the
    filter by user -- which is the whole of Article III here -- written in a module that does not
    own the table.

    The same normalisation as the add and the remove, and for the same reason: one rule in one
    place, so a symbol that could be added cannot fail to be recognised later.
    """
    return await follows(session, user_id, symbol.strip().upper())
