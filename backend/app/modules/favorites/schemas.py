"""The data structures of `favorites`: what comes in, what goes out, and what the module decides.

Internal to the module. What travels to other modules is what the `__init__` declares, and today
that is the router and nothing else.

The file is called `schemas` and not `io` because most of what is here is not exclusive to the
transport: `FavoriteStock` is the row of the grid *and* what `list_favorites` answers, and having
written it twice -- once as a Pydantic model for the response and once as a dataclass for the
service -- bought nothing but two places to keep in step.
"""

from pydantic import BaseModel, ConfigDict, Field


class FavoriteStock(BaseModel):
    """One row of `Mis Acciones`: what the service decides, and what the grid reads (RF-03).

    Three fields, and the reason there are only three is worth stating: the screen draws a
    symbol, a name and a currency, and anything else the tables happen to hold -- when it was
    added, which market it trades in -- would be answered for no reason. That habit is
    API3:2023 (BOPLA), and it is the risk this model carries by being the two things at once:
    a field added here for the service is a field the API starts answering. Nothing goes in
    that the grid does not draw.

    Whether the symbol still trades does not travel either: a favourite is shown either way, so
    a field nobody reads would be surface to keep. That decision is `stocks`' to publish and
    this module's to ignore.

    Frozen, because it is a value and not a record somebody edits on the way out.
    """

    model_config = ConfigDict(frozen=True)

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
