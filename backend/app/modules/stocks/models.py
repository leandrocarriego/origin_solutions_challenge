"""The catalogue table, which the ingestion reconciles."""

from datetime import datetime

from sqlalchemy import DateTime, Index, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db import Base

# The ingestion filter accepts at most nine characters.
SYMBOL_LENGTH = 12


class Stock(Base):
    """One symbol, described once for the whole application.

    The primary key is the symbol itself and not a surrogate: it is what travels in the URL and
    what `user_stocks` and `quotes` point at. The catalogue was measured before deciding that --
    zero collisions once warrants are dropped.
    """

    __tablename__ = "stocks"

    symbol: Mapped[str] = mapped_column(String(SYMBOL_LENGTH), primary_key=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    currency: Mapped[str] = mapped_column(String(8), nullable=False)
    exchange: Mapped[str] = mapped_column(String(32), nullable=False)
    mic_code: Mapped[str] = mapped_column(String(8), nullable=False)
    country: Mapped[str] = mapped_column(String(64), nullable=False)
    # Named `instrument_type` in Python and `type` in the database: the provider calls it type,
    # and shadowing the builtin inside the class buys nothing.
    instrument_type: Mapped[str] = mapped_column("type", String(64), nullable=False)

    # The provider's catalogue is a snapshot with no status field, so the only signal that a
    # symbol stopped trading is that it no longer comes back.
    last_seen_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    # Null means listed. A delisted symbol is marked, never deleted.
    delisted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


Index(
    "ix_stocks_symbol_trgm",
    Stock.symbol,
    postgresql_using="gin",
    postgresql_ops={"symbol": "gin_trgm_ops"},
)
Index(
    "ix_stocks_name_trgm",
    Stock.name,
    postgresql_using="gin",
    postgresql_ops={"name": "gin_trgm_ops"},
)
