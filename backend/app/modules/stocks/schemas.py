"""The HTTP contract of `stocks`: what comes in and what goes out.

Internal to the module. What travels to other modules is what the `__init__` declares.
"""

from pydantic import BaseModel


class StockSuggestion(BaseModel):
    """One line of the dropdown of the `Símbolo` field.

    Three fields and not the four of `StockInfo`: `is_listed` is always true on this route, since
    the search excludes what stopped trading, and a constant in a contract is a field the
    frontend has to type for no reason.
    """

    symbol: str
    name: str
    currency: str
