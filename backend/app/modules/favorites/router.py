"""HTTP for `favorites`: it translates between transport and service."""

from typing import Annotated

from fastapi import APIRouter, Depends, Path, Response, status

from app.modules.favorites.schemas import AddFavoriteRequest, FavoriteStock
from app.modules.favorites.service import (
    Catalogue,
    FavoritesStore,
    add_favorite,
    catalogue,
    favorites_store,
    list_favorites,
    remove_favorite,
)
from app.security import CurrentUser, get_current_user

router = APIRouter(prefix="/api/favorites", tags=["favorites"])


@router.get("", summary="The favourite stocks of whoever is asking")
async def read_favorites(
    store: Annotated[FavoritesStore, Depends(favorites_store)],
    described_by: Annotated[Catalogue, Depends(catalogue)],
    current_user: Annotated[CurrentUser, Depends(get_current_user)],
) -> list[FavoriteStock]:
    """Answer the grid of the token's user, empty list included."""
    return await list_favorites(store, described_by, current_user.id)


@router.post(
    "",
    status_code=status.HTTP_201_CREATED,
    # Without this the OpenAPI document carries only the 201, and the frontend types are
    # generated from that document: the screen would have no typed way of telling an addition
    # that created a row from one that found it already there.
    responses={status.HTTP_200_OK: {"model": FavoriteStock}},
    summary="Add a stock to the favourites of whoever is asking",
)
async def add_to_favorites(
    body: AddFavoriteRequest,
    store: Annotated[FavoritesStore, Depends(favorites_store)],
    described_by: Annotated[Catalogue, Depends(catalogue)],
    current_user: Annotated[CurrentUser, Depends(get_current_user)],
    response: Response,
) -> FavoriteStock:
    """Add stock to favourites."""
    addition = await add_favorite(store, described_by, current_user.id, body.symbol)

    if not addition.created:
        response.status_code = status.HTTP_200_OK

    return addition.favorite


@router.delete(
    "/{symbol}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Remove a stock from the favourites of whoever is asking",
)
async def remove_from_favorites(
    store: Annotated[FavoritesStore, Depends(favorites_store)],
    current_user: Annotated[CurrentUser, Depends(get_current_user)],
    symbol: Annotated[str, Path(max_length=12, pattern=r"^[A-Za-z0-9.\-]{1,12}$")],
) -> None:
    """Remove stock from favourites."""
    await remove_favorite(store, current_user.id, symbol)
