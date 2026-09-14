"""The quote cache (ADR-001), which is what makes Article II possible."""

from datetime import datetime
from decimal import Decimal
from enum import StrEnum

from sqlalchemy import (
    BigInteger,
    CheckConstraint,
    DateTime,
    ForeignKey,
    Index,
    Numeric,
    String,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.db import Base

# The same number as the catalogue's, and a test says so: the three modules that store a
# symbol declare it apart, because borrowing it would mean importing another module's
# interior.
SYMBOL_LENGTH = 12

# Money, and therefore never a float: 18 digits with 6 decimals covers every price the provider
# returns without the rounding a binary fraction introduces.
PRICE = Numeric(18, 6)


class QuoteInterval(StrEnum):
    """The three intervals REQ-16 offers the user, and the only ones the table accepts."""

    ONE_MINUTE = "1min"
    FIVE_MINUTES = "5min"
    FIFTEEN_MINUTES = "15min"


_ALLOWED_INTERVALS = ", ".join(f"'{interval}'" for interval in QuoteInterval)


class Quote(Base):
    """One candle: a symbol, an interval and an instant.

    The composite primary key is the cache: fetching the same point twice writes one row, so a
    re-fetch cannot duplicate the series, and the gap detection can ask the database what it
    already has instead of trusting a bookkeeping table.

    `interval` is a String with a CHECK and not a native enum: adding a value to a Postgres enum
    is an awkward migration and removing one is worse, while a CHECK is altered in one line
    (ADR-001).
    """

    __tablename__ = "quotes"

    symbol: Mapped[str] = mapped_column(
        String(SYMBOL_LENGTH), ForeignKey("stocks.symbol"), primary_key=True
    )
    interval: Mapped[str] = mapped_column(String(8), primary_key=True)
    ts: Mapped[datetime] = mapped_column(DateTime(timezone=True), primary_key=True)

    open_price: Mapped[Decimal] = mapped_column("open", PRICE, nullable=False)
    high_price: Mapped[Decimal] = mapped_column("high", PRICE, nullable=False)
    low_price: Mapped[Decimal] = mapped_column("low", PRICE, nullable=False)
    close_price: Mapped[Decimal] = mapped_column("close", PRICE, nullable=False)
    volume: Mapped[int | None] = mapped_column(BigInteger, nullable=True)

    __table_args__ = (
        CheckConstraint(f"interval IN ({_ALLOWED_INTERVALS})", name="ck_quotes_interval"),
    )


# The only query the chart makes: one symbol, one interval, a window of time, newest first.
Index("ix_quotes_symbol_interval_ts", Quote.symbol, Quote.interval, Quote.ts.desc())
