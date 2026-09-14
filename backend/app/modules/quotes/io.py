"""The HTTP contract of `quotes`: what the chart is drawn from.

Internal to the module. What travels to other modules is what the `__init__` declares, and that
is the router and nothing else: nobody else has any business with a series of prices.
"""

from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel

from app.modules.quotes.service import QuoteStatus


class QuotePointOut(BaseModel):
    """One point of the chart: the instant, and the close of that candle.

    The price crosses the wire as a string, which is what Pydantic does with a `Decimal` and is
    kept on purpose: it travels with the decimals the provider sent and becomes a `number` once,
    at the edge of the chart, which is the one place a number is needed at all.
    """

    ts: datetime
    price: Decimal


class QuoteSeriesResponse(BaseModel):
    """The series and what has to be said about it (ERR-05).

    The four states answer 200, every one of them: a spent quota is not a failure of the caller,
    and a closed market is the normal state of two days out of seven. And no field names the
    provider, neither in the happy path nor in the three notices (RF-26, Article I).
    """

    symbol: str
    interval: str
    status: QuoteStatus
    session_date: date | None
    points: list[QuotePointOut]
