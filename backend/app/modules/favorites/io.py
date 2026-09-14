"""The HTTP contract of `favorites`: what comes in and what goes out.

Internal to the module. What travels to other modules is what the `__init__` declares, and today
that is the router and nothing else.
"""

from pydantic import BaseModel, ConfigDict, Field


class FavoriteItem(BaseModel):
    """One row of `Mis Acciones`, as the grid reads it (RF-03).

    Three fields, and the reason there are only three is worth stating: the screen draws a
    symbol, a name and a currency, and anything else the tables happen to hold -- when it was
    added, which market it trades in -- would be answered for no reason. That habit is
    API3:2023 (BOPLA).
    """

    symbol: str
    name: str
    currency: str


class AddFavoriteRequest(BaseModel):
    """The symbol somebody asks to follow.

    `extra="forbid"` is API3:2023 (BOPLA): a body carrying fields nobody declared is a body that
    will eventually carry one somebody forgot to ignore -- a `user_id`, for instance, which is
    exactly what Article III says never arrives from the request.

    The pattern is the one of a symbol and not a general string: what cannot be a segment of a
    path cannot be a symbol, because this same value travels in the URL of the delete.
    """

    model_config = ConfigDict(extra="forbid")

    symbol: str = Field(min_length=1, max_length=12, pattern=r"^[A-Za-z0-9.\-]{1,12}$")
