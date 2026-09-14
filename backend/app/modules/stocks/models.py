"""The catalogue table (ADR-001), which the ingestion reconciles (ADR-002)."""

from datetime import datetime

from sqlalchemy import DateTime, Index, String
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


# The autocomplete searches `ILIKE '%text%'` over both columns, and a leading wildcard rules a
# B-tree out entirely: trigrams are the only thing that can index that pattern. They are declared
# here as well as in the migration because a table the model does not describe is a table
# `alembic check` reports as drifted forever (DB-01, DB-03).
#
# Two caveats worth knowing before reading a slow query plan: the index only comes into play from
# the third character on -- a two-letter pattern has no complete trigram to look up -- and the
# two-character minimum of RF-13 therefore stays a sequential scan of ~7.200 rows, which is
# milliseconds and why it is enough.
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
