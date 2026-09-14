"""The data structures of `quotes`: the chart, and what has to be said about it.

Internal to the module. What travels to other modules is what the `__init__` declares, and that
is the router and nothing else: nobody else has any business with a series of prices.

The file is called `schemas` and not `io` because what is here is not exclusive to the transport.
`QuoteStatus` and `QuoteCandle` are decisions of the service that the answer happens to carry, and
they live here so the service can import them instead of the other way round -- a `schemas` that
reached into `service` for a type the service needs back is a cycle waiting for its second half.

`QuoteSeriesResponse` stays a type of its own, and that is deliberate: it carries `symbol` and
`interval`, which the service never decides -- they are what the caller asked for, echoed back by
the route that read them.
"""

from datetime import date, datetime
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, ConfigDict

QuoteStatus = Literal["ok", "stale", "market_closed", "no_data"]


class QuoteCandle(BaseModel):
    """One point of the chart: an instant, and the close of that candle.

    The chart draws one value per instant (RF-14), so what leaves this module is the close and
    not the four prices of a candle. A type of ours and never the ORM row: a contract that
    handed back the model would have aisled nothing (Article IV).

    The price crosses the wire as a string, which is what Pydantic does with a `Decimal` and is
    kept on purpose: it travels with the decimals the provider sent and becomes a `number` once,
    at the edge of the chart, which is the one place a number is needed at all.
    """

    model_config = ConfigDict(frozen=True)

    ts: datetime
    price: Decimal


class QuoteSeries(BaseModel):
    """A chart, and what has to be said about it.

    `session_date` travels only with `market_closed`: it is the `{fecha}` of the notice, and on
    every other state there is no session to name.
    """

    model_config = ConfigDict(frozen=True)

    status: QuoteStatus
    points: tuple[QuoteCandle, ...]
    session_date: date | None


class QuoteSeriesResponse(BaseModel):
    """The series and what has to be said about it, as the chart reads it (ERR-05).

    The four states answer 200, every one of them: a spent quota is not a failure of the caller,
    and a closed market is the normal state of two days out of seven. And no field names the
    provider, neither in the happy path nor in the three notices (RF-26, Article I).
    """

    symbol: str
    interval: str
    status: QuoteStatus
    session_date: date | None
    points: list[QuoteCandle]
