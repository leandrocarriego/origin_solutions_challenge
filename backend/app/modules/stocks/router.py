"""HTTP for `stocks`: it translates between transport and service."""

from typing import Annotated

from fastapi import APIRouter, Depends, Query

from app.modules.stocks.schemas import StockSuggestion
from app.modules.stocks.service import (
    MIN_QUERY_LENGTH,
    CatalogueStore,
    catalogue_store,
    search_stocks,
)
from app.security import CurrentUser, get_current_user

router = APIRouter(prefix="/api/stocks", tags=["stocks"])


@router.get("", summary="Catalogue suggestions for what somebody is typing")
async def search_the_catalogue(
    store: Annotated[CatalogueStore, Depends(catalogue_store)],
    current_user: Annotated[CurrentUser, Depends(get_current_user)],
    q: Annotated[str, Query(min_length=MIN_QUERY_LENGTH, max_length=50)],
) -> list[StockSuggestion]:
    """Answer at most twenty suggestions, most relevant first."""
    found = await search_stocks(store, q)

    return [
        StockSuggestion(symbol=stock.symbol, name=stock.name, currency=stock.currency)
        for stock in found
    ]
