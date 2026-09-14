"""HTTP for `quotes`: it translates between transport and service."""

from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Depends, Path, Query

from app.modules.quotes.models import QuoteInterval
from app.modules.quotes.schemas import QuoteSeriesResponse
from app.modules.quotes.service import (
    FavoriteCheck,
    QuoteStore,
    favorite_check,
    get_series,
    quote_store,
)
from app.providers import MarketDataProvider, get_market_data_provider
from app.security import CurrentUser, get_current_user

router = APIRouter(prefix="/api/quotes", tags=["quotes"])


@router.get("/{symbol}", summary="The series a chart of that stock is drawn from")
async def read_quotes(
    store: Annotated[QuoteStore, Depends(quote_store)],
    follows: Annotated[FavoriteCheck, Depends(favorite_check)],
    current_user: Annotated[CurrentUser, Depends(get_current_user)],
    provider: Annotated[MarketDataProvider, Depends(get_market_data_provider)],
    symbol: Annotated[str, Path(max_length=12, pattern=r"^[A-Za-z0-9.\-]{1,12}$")],
    interval: QuoteInterval,
    start: Annotated[datetime | None, Query(alias="from")] = None,
    end: Annotated[datetime | None, Query(alias="to")] = None,
) -> QuoteSeriesResponse:
    """Answer the series of that symbol, and the state it is served in."""
    series = await get_series(
        store,
        follows,
        provider,
        symbol=symbol,
        interval=interval,
        user_id=current_user.id,
        start=start,
        end=end,
    )

    return QuoteSeriesResponse(
        symbol=symbol.strip().upper(),
        interval=interval.value,
        status=series.status,
        session_date=series.session_date,
        points=list(series.points),
    )
