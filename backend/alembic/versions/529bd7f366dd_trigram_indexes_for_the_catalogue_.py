"""trigram indexes for the catalogue autocomplete.

Revision ID: 529bd7f366dd
Revises: 394dab64d255
Create Date: 2026-09-14 03:05:12.146262

"""

from collections.abc import Sequence

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "529bd7f366dd"
down_revision: str | Sequence[str] | None = "394dab64d255"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Create `pg_trgm` and the two GIN indexes the autocomplete searches through.

    The extension comes first because the operator classes below do not exist without it.
    `IF NOT EXISTS` is what lets this run where somebody -- or a previous run -- already created
    it: on a managed Postgres the application user may not be allowed to, and there the operator
    creates it before the deploy rather than this failing.
    """
    op.execute("CREATE EXTENSION IF NOT EXISTS pg_trgm")
    op.create_index(
        "ix_stocks_symbol_trgm",
        "stocks",
        ["symbol"],
        unique=False,
        postgresql_using="gin",
        postgresql_ops={"symbol": "gin_trgm_ops"},
    )
    op.create_index(
        "ix_stocks_name_trgm",
        "stocks",
        ["name"],
        unique=False,
        postgresql_using="gin",
        postgresql_ops={"name": "gin_trgm_ops"},
    )


def downgrade() -> None:
    """Drop the two indexes, and leave the extension where it is.

    Deliberately asymmetric. An extension is database-wide and can have other users, so dropping
    it here would be an effect nobody asked for -- and one that could break something this
    migration never created.
    """
    op.drop_index("ix_stocks_name_trgm", table_name="stocks", postgresql_using="gin")
    op.drop_index("ix_stocks_symbol_trgm", table_name="stocks", postgresql_using="gin")
