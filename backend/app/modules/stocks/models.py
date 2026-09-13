"""The catalogue table (ADR-001), which the ingestion reconciles (ADR-002)."""

from datetime import datetime

from sqlalchemy import DateTime, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db import Base

# The ingestion filter of ADR-001 accepts at most nine characters; the column has room to
# spare so a longer symbol fails the filter where the reason is written, not on an INSERT.
SYMBOL_LENGTH = 12


class Stock(Base):
    """One symbol, described once for the whole application.

    The primary key is the symbol itself and not a surrogate: it is what travels in the URL
    (REQ-11) and what `user_stocks` and `quotes` point at. ADR-001 measured the catalogue
    before deciding that -- zero collisions once warrants are dropped.
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

    # The two columns ADR-002 needs, and the reason they exist: the provider's catalogue is a
    # snapshot with no status field, so the only signal that a symbol stopped trading is that it
    # no longer comes back.
    last_seen_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    # Null means listed. A delisted symbol is marked, never deleted: `user_stocks` and `quotes`
    # reference it, and removing the row would take away somebody's favourite or its history.
    delisted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
