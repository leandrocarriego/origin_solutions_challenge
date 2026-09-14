"""HTTP for `stocks`: it translates between transport and service, and decides nothing."""

from typing import Annotated

from fastapi import APIRouter, Depends, Query

from app.db import SessionDep
from app.modules.stocks.schemas import StockSuggestion
from app.modules.stocks.service import MIN_QUERY_LENGTH, search_stocks
from app.security import CurrentUser, get_current_user

router = APIRouter(prefix="/api/stocks", tags=["stocks"])


@router.get("", summary="Catalogue suggestions for what somebody is typing")
async def search_the_catalogue(
    session: SessionDep,
    current_user: Annotated[CurrentUser, Depends(get_current_user)],
    q: Annotated[str, Query(min_length=MIN_QUERY_LENGTH, max_length=50)],
) -> list[StockSuggestion]:
    """Answer at most twenty suggestions, most relevant first.

    The text travels to the service exactly as it arrived: normalising is a decision, and
    decisions are not made at this layer. The minimum length is declared in both places on
    purpose and the two are not symmetric -- this one measures what was received and answers 422;
    the service measures what was asked once stripped and answers `200 []`.

    `MIN_QUERY_LENGTH` is imported from the service rather than written again, so the rule cannot
    end up as two literals that one day say different numbers.

    Protected, like every route of this API: the catalogue is not user data, but a search box
    left open is the ingestion's work handed out for free.
    """
    found = await search_stocks(session, q)

    return [
        StockSuggestion(symbol=stock.symbol, name=stock.name, currency=stock.currency)
        for stock in found
    ]
