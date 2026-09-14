"""What a provider answers with: types of ours, never the shape the vendor sent."""

from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict


class StockRecord(BaseModel):
    """One entry of a provider's catalogue, in the shape `stocks` stores."""

    model_config = ConfigDict(frozen=True)

    symbol: str
    name: str
    currency: str
    exchange: str
    mic_code: str
    country: str
    instrument_type: str


class QuotePoint(BaseModel):
    """One candle of a series, in the shape `quotes` stores."""

    model_config = ConfigDict(frozen=True)

    ts: datetime
    open: Decimal
    high: Decimal
    low: Decimal
    close: Decimal
    volume: int | None
