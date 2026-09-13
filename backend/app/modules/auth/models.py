"""The users table (ADR-001)."""

from datetime import datetime

from sqlalchemy import DateTime, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db import Base


class User(Base):
    """Someone who can log in.

    There is no sign-up: users arrive through the seed (A1, REQ-19), which is why this table
    has no state a registration flow would need.
    """

    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    username: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    full_name: Mapped[str] = mapped_column(String(120), nullable=False)
    # SEC-06: an Argon2id hash and never the password. The column is named after what it holds,
    # so a query that selects it cannot be misread as selecting a credential.
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
