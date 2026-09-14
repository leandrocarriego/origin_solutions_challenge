"""The data schemas of `stocks`."""

from pydantic import BaseModel, ConfigDict


class StockSuggestion(BaseModel):
    """A symbol, name and currency that the catalogue suggests for what somebody is typing."""

    symbol: str
    name: str
    currency: str


class CatalogueReconciliation(BaseModel):
    """What one reconciliation did, for the log line and the metric that follow it."""

    model_config = ConfigDict(frozen=True)

    exchange: str
    listed: int
    delisted: int
    discarded: int


class CatalogueRefresh(BaseModel):
    """What one scheduled refresh did, including the markets that did not answer."""

    model_config = ConfigDict(frozen=True)

    reconciled: tuple[CatalogueReconciliation, ...]
    failed: tuple[str, ...]
    skipped: bool


class StockInfo(BaseModel):
    """The catalogue row for one symbol, as the autocomplete returns it."""

    model_config = ConfigDict(frozen=True)

    symbol: str
    name: str
    currency: str
    is_listed: bool
