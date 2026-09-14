"""The data schemas of `favorites`."""

from pydantic import BaseModel, ConfigDict, Field


class FavoriteStock(BaseModel):
    """
    One row of `Mis Acciones`.

    Frozen, because it is a value and not a record somebody edits on the way out.
    """

    model_config = ConfigDict(frozen=True)

    symbol: str
    name: str
    currency: str


class AddFavoriteRequest(BaseModel):
    """The symbol somebody asks to follow."""

    model_config = ConfigDict(extra="forbid")

    symbol: str = Field(min_length=1, max_length=12, pattern=r"^[A-Za-z0-9.\-]{1,12}$")


class FavoriteAddition(BaseModel):
    """What one add did: whether it created the row, and the row itself."""

    model_config = ConfigDict(frozen=True)

    created: bool
    favorite: FavoriteStock
