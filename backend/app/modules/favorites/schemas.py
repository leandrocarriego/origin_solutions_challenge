"""The data structures of `favorites`: what comes in, what goes out, and what the module decides.

Internal to the module. `FavoriteStock` is the row of the grid *and* what `list_favorites`
answers, and writing it twice bought nothing but two places to keep in step.
"""

from pydantic import BaseModel, ConfigDict, Field


class FavoriteStock(BaseModel):
    """One row of `Mis Acciones`: what the service decides, and what the grid reads.

    Three fields, because the screen draws a symbol, a name and a currency. This is the risk the
    model carries by being the two things at once -- a field added here for the service is a
    field the API starts answering -- so nothing goes in that the grid does not draw.

    Frozen, because it is a value and not a record somebody edits on the way out.
    """

    model_config = ConfigDict(frozen=True)

    symbol: str
    name: str
    currency: str


class AddFavoriteRequest(BaseModel):
    """The symbol somebody asks to follow.

    `extra="forbid"`: a body carrying fields nobody declared is a body that will eventually carry
    one somebody forgot to ignore -- a `user_id`, for instance, which never arrives from the
    request.

    The pattern is the one of a symbol and not a general string: what cannot be a segment of a
    path cannot be a symbol, because this same value travels in the URL of the delete.
    """

    model_config = ConfigDict(extra="forbid")

    symbol: str = Field(min_length=1, max_length=12, pattern=r"^[A-Za-z0-9.\-]{1,12}$")
