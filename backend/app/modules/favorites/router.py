"""HTTP for `favorites`: it translates between transport and service, and decides nothing."""

from typing import Annotated

from fastapi import APIRouter, Depends, Path, Response, status

from app.db import SessionDep
from app.modules.favorites.io import AddFavoriteRequest, FavoriteItem
from app.modules.favorites.service import add_favorite, list_favorites, remove_favorite
from app.security import CurrentUser, get_current_user

router = APIRouter(prefix="/api/favorites", tags=["favorites"])


@router.get("", summary="The favourite stocks of whoever is asking")
async def read_favorites(
    session: SessionDep,
    current_user: Annotated[CurrentUser, Depends(get_current_user)],
) -> list[FavoriteItem]:
    """Answer the grid of the token's user, empty list included (RF-01, RF-07).

    The identity comes from `get_current_user` and from nowhere else: this route takes no id, so
    there is none to substitute (Article III). An empty list is a result and not a 404 -- the
    text the screen writes in place of the rows is its business, not this one's.
    """
    favorites = await list_favorites(session, current_user.id)

    return [
        FavoriteItem(symbol=favorite.symbol, name=favorite.name, currency=favorite.currency)
        for favorite in favorites
    ]


@router.post(
    "",
    status_code=status.HTTP_201_CREATED,
    # Without this the OpenAPI document carries only the 201, and `schema.d.ts` is generated
    # from that document: the screen would have no typed way of telling an addition that
    # created a row from one that found it already there (RF-19).
    responses={status.HTTP_200_OK: {"model": FavoriteItem}},
    summary="Add a stock to the favourites of whoever is asking",
)
async def add_to_favorites(
    body: AddFavoriteRequest,
    session: SessionDep,
    current_user: Annotated[CurrentUser, Depends(get_current_user)],
    response: Response,
) -> FavoriteItem:
    """Answer 201 when the favourite was created and 200 when it already was there (RF-18).

    Never a 409: adding the same action twice is not an error, it is an operation that was
    already done -- and TEST-04 asks for exactly that, no duplicate **and** no failure. The
    difference travels in the status because the protocol already has it; a field in the body
    saying the same thing would be a second source of truth.

    The 200 is written onto the `Response` rather than declared, because a route has one
    `status_code` and this one has two answers. It is the same mechanism `/api/health` uses.

    The symbol is the object and the identity is the token: `user_id` is not a parameter of this
    route, so there is none to substitute (Article III).
    """
    addition = await add_favorite(session, current_user.id, body.symbol)

    if not addition.created:
        response.status_code = status.HTTP_200_OK

    return FavoriteItem(
        symbol=addition.favorite.symbol,
        name=addition.favorite.name,
        currency=addition.favorite.currency,
    )


@router.delete(
    "/{symbol}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Remove a stock from the favourites of whoever is asking",
)
async def remove_from_favorites(
    session: SessionDep,
    current_user: Annotated[CurrentUser, Depends(get_current_user)],
    symbol: Annotated[str, Path(max_length=12, pattern=r"^[A-Za-z0-9.\-]{1,12}$")],
) -> None:
    """Answer 204, and answer it whether or not the favourite was there (RF-24).

    The symbol travels in the path and **that is not an identity**: it is the object. What scopes
    it to the list of whoever is asking is the `WHERE user_id = <the token's>` of the repository,
    which is also why RF-28 holds without a single extra check (Article III).

    Validated with the same pattern as the add, because it is the same value seen twice: what
    cannot be a segment of a path was never a symbol.
    """
    await remove_favorite(session, current_user.id, symbol)
