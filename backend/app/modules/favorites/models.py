"""The favourites table."""

from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db import Base

# The same number as the catalogue's, and a test says so: the three modules that store a
# symbol declare it apart, because borrowing it would mean importing another module's
# interior.
SYMBOL_LENGTH = 12


class UserStock(Base):
    """One symbol a user follows.

    The composite primary key is what makes adding the same favourite twice impossible. It is a
    constraint of the schema and not an `if` in a service, so it holds even for the second
    request of a double click that the first one has not finished serving.

    Neither the name nor the currency are copied here: they are persisted in `stocks`, once,
    where the ingestion keeps them current.
    """

    __tablename__ = "user_stocks"

    user_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    # A foreign key across modules is legitimate: modules separate code, not schema, and this is
    # a guarantee of the engine. What is not allowed is a relationship() that crosses, which
    # would couple the two models without leaving an import behind.
    symbol: Mapped[str] = mapped_column(
        String(SYMBOL_LENGTH), ForeignKey("stocks.symbol"), primary_key=True
    )
    added_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
