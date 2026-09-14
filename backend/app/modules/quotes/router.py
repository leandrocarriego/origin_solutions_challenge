"""HTTP for `quotes`: it translates between transport and service, and decides nothing."""

from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Depends, Path, Query

from app.db import SessionDep
from app.modules.quotes.io import QuotePointOut, QuoteSeriesResponse
from app.modules.quotes.models import QuoteInterval
from app.modules.quotes.service import get_series
from app.providers import MarketDataProvider, get_market_data_provider
from app.security import CurrentUser, get_current_user

router = APIRouter(prefix="/api/quotes", tags=["quotes"])


@router.get("/{symbol}", summary="The series a chart of that stock is drawn from")
async def read_quotes(
    session: SessionDep,
    current_user: Annotated[CurrentUser, Depends(get_current_user)],
    provider: Annotated[MarketDataProvider, Depends(get_market_data_provider)],
    symbol: Annotated[str, Path(max_length=12, pattern=r"^[A-Za-z0-9.\-]{1,12}$")],
    interval: QuoteInterval,
    start: Annotated[datetime | None, Query(alias="from")] = None,
    end: Annotated[datetime | None, Query(alias="to")] = None,
) -> QuoteSeriesResponse:
    """Answer the series of that symbol, and the state it is served in (RF-13, RF-16).

    One route for the two modes of the screen, because they are not two questions: without
    `from` and `to` it is today's session in market hours, and with them it is the window the
    person asked for. Which hours those are is decided in the service -- this layer carries the
    two instants exactly as they were written, naive, and puts no timezone on them.

    The symbol travels in the path and **that is not an identity**: it is the object. Who is
    asking comes from the token and from nowhere else (Article III), and a symbol that is not on
    that person's list is a 404 that never reaches the provider (RF-35).

    The provider arrives by dependency rather than being built here: it is what lets the suite
    exercise this endpoint with no network and no API key (TEST-03).
    """
    series = await get_series(
        session,
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
        points=[QuotePointOut(ts=point.ts, price=point.price) for point in series.points],
    )
