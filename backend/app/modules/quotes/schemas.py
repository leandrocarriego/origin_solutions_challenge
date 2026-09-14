"""The data schemas of `quotes`."""

from datetime import date, datetime
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, ConfigDict

QuoteStatus = Literal["ok", "stale", "market_closed", "no_data"]


class QuoteCandle(BaseModel):
    """One point of the chart: an instant, and the close of that candle."""

    model_config = ConfigDict(frozen=True)

    ts: datetime
    price: Decimal


class QuoteSeries(BaseModel):
    """A chart, and what has to be said about it."""

    model_config = ConfigDict(frozen=True)

    status: QuoteStatus
    points: tuple[QuoteCandle, ...]
    session_date: date | None


class QuoteSeriesResponse(BaseModel):
    """The series and what has to be said about it, as the chart reads it."""

    symbol: str
    interval: str
    status: QuoteStatus
    session_date: date | None
    points: list[QuoteCandle]
