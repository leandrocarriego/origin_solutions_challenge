"""The data structures of `stocks`: what comes in, what goes out, and what the module decides.

Internal to the module. What travels to other modules is what the `__init__` declares.
"""

from pydantic import BaseModel, ConfigDict


class StockSuggestion(BaseModel):
    """One line of the dropdown of the `Símbolo` field.

    Three fields and not the four of `StockInfo`: `is_listed` is always true on this route, since
    the search excludes what stopped trading, and a constant in a contract is a field the
    frontend has to type for no reason.
    """

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
    """What the catalogue tells another module about a symbol.

    Four fields, and the fourth is the one that needs a reason. The first three are the grid of
    `Mis Acciones`. `is_listed` exists because `favorites` has to do two opposite things
    with the same lookup: **show** a favourite that stopped trading -- the business rule asks for
    it expressly -- and **refuse** to add one that is no longer offered. Filtering the delisted
    ones out here would take rows away from whoever saved them; saying nothing would let the add
    accept what the autocomplete cannot suggest. A boolean is less surface than a second exported
    function.

    Frozen, and never a row of `stocks`: a contract that handed back the ORM would hand the
    session and the table layout over with it, and the boundary would live only in the docs.
    """

    model_config = ConfigDict(frozen=True)

    symbol: str
    name: str
    currency: str
    is_listed: bool
