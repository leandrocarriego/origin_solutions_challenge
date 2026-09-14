"""The HTTP contract of `stocks`: what comes in and what goes out.

Internal to the module. What travels to other modules is what the `__init__` declares.
"""

from pydantic import BaseModel


class StockSuggestion(BaseModel):
    """One line of the dropdown of the `Símbolo` field (RF-08, RF-09).

    Three fields and not the four of `StockInfo`: `is_listed` is always true on this route --
    the search excludes what stopped trading (RF-12) -- and a constant in a contract is a field
    the frontend has to type for no reason.
    """

    symbol: str
    name: str
    currency: str
