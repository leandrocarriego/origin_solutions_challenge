"""The four tables of the schema, as SQLAlchemy describes them.

This reads `Base.metadata`, not the database: it is the shape the code declares, checked before
any migration has run and without a Postgres anywhere near it. Whether the database actually
matches that shape is another question, and `alembic check` in CI is what answers it.

The model is what the brief evaluates explicitly, and most of what was decided is
enforceable right here: a natural key, two composite keys, the foreign keys that make the
catalogue the single place a symbol is described, and the constraint that keeps `interval`
inside the three values the user is offered.
"""

from importlib import import_module
from pathlib import Path

import pytest
from sqlalchemy import CheckConstraint, MetaData, String
from sqlalchemy.schema import Index, Table

from app.db import Base

BACKEND_ROOT = Path(__file__).resolve().parents[2]

# Every table belongs to the module that owns its data. This mapping is the whole
# of the schema, and the tests below read it rather than repeating the four names.
TABLE_OF_MODULE = {
    "auth": "users",
    "stocks": "stocks",
    "favorites": "user_stocks",
    "quotes": "quotes",
}

# The user is given three intervals and no more. The database says so too, so a fourth one
# cannot arrive through a code path that forgot to validate.
REQ_16_INTERVALS = ("1min", "5min", "15min")


@pytest.fixture(scope="module")
def schema() -> MetaData:
    """The declared schema, with every model module imported so the tables register.

    Importing them here and not in `app/` is deliberate: nothing under the modules may import a
    module, so the only place that knows all four is the schema's composition root,
    `alembic/env.py` -- and a test below checks that it still knows all four.
    """
    for module in TABLE_OF_MODULE:
        import_module(f"app.modules.{module}.models")

    return Base.metadata


def _primary_key(table: Table) -> list[str]:
    """The primary key column names, in the order the key declares them."""
    return [column.name for column in table.primary_key]


def _foreign_keys(table: Table) -> set[str]:
    """Where each foreign key of the table points, as `table.column`."""
    return {key.target_fullname for key in table.foreign_keys}


def _index_columns(index: Index) -> list[str]:
    """The columns an index covers, in order, ignoring whether each is ascending."""
    covered: list[str] = []
    for expression in index.expressions:
        column = getattr(expression, "element", expression)
        covered.append(str(getattr(column, "name", column)))

    return covered


class TestTheSchemaIsTheFourTables:
    """decided four tables, and four is part of the decision."""

    def test_there_are_exactly_the_four_tables_adr_001_defines(self, schema: MetaData) -> None:
        """A fifth table is a decision nobody recorded; a missing one is a feature with no home."""
        assert set(schema.tables) == set(TABLE_OF_MODULE.values())

    @pytest.mark.parametrize(("module", "table"), sorted(TABLE_OF_MODULE.items()))
    def test_each_table_is_declared_by_the_module_that_owns_it(
        self, module: str, table: str, schema: MetaData
    ) -> None:
        """A module that does not own its tables owns nothing: the frontier stops at the schema."""
        declared = {
            value.__tablename__
            for value in vars(import_module(f"app.modules.{module}.models")).values()
            if isinstance(value, type) and issubclass(value, Base) and value is not Base
        }

        assert table in declared


class TestTheCatalogueIsKeyedByItsSymbol:
    """`stocks` is the one place a symbol is described."""

    def test_the_symbol_is_the_primary_key(self, schema: MetaData) -> None:
        """The natural key: it is what travels in the URL and what every other table points at."""
        assert _primary_key(schema.tables["stocks"]) == ["symbol"]

    def test_the_name_and_the_currency_are_always_present(self, schema: MetaData) -> None:
        """Persists symbol, name and currency, so two of them cannot be null."""
        columns = schema.tables["stocks"].columns

        assert not columns["name"].nullable
        assert not columns["currency"].nullable

    def test_a_symbol_that_stopped_trading_is_marked_and_not_deleted(
        self, schema: MetaData
    ) -> None:
        """Null means listed. A delisting is marked; deleting would take away a favourite."""
        assert schema.tables["stocks"].columns["delisted_at"].nullable

    def test_the_catalogue_records_when_each_symbol_was_last_seen(self, schema: MetaData) -> None:
        """The reconciliation needs to tell "still listed" from "never checked"."""
        assert "last_seen_at" in schema.tables["stocks"].columns


class TestAFavouriteCannotBeAddedTwice:
    """`user_stocks` makes the duplicate impossible in the schema, not in an `if`."""

    def test_the_primary_key_is_the_user_and_the_symbol(self, schema: MetaData) -> None:
        """Adding the same symbol twice is a key violation, not a branch someone has to remember."""
        assert _primary_key(schema.tables["user_stocks"]) == ["user_id", "symbol"]

    def test_it_points_at_the_catalogue(self, schema: MetaData) -> None:
        """The name and the currency of a favourite live in `stocks`, once."""
        assert "stocks.symbol" in _foreign_keys(schema.tables["user_stocks"])

    def test_it_belongs_to_a_user_that_exists(self, schema: MetaData) -> None:
        """A favourite of nobody is a row that the isolation rule cannot reason about."""
        assert "users.id" in _foreign_keys(schema.tables["user_stocks"])

    def test_it_copies_neither_the_name_nor_the_currency(self, schema: MetaData) -> None:
        """Denormalising here would add one copy per user, free to diverge."""
        columns = set(schema.tables["user_stocks"].columns.keys())

        assert not columns & {"name", "currency"}


class TestTheQuoteCache:
    """`quotes` is what makes the quota possible: served from here, or not served at all."""

    def test_the_primary_key_is_the_symbol_the_interval_and_the_instant(
        self, schema: MetaData
    ) -> None:
        """The same point fetched twice is one row, so a re-fetch cannot duplicate the series."""
        assert _primary_key(schema.tables["quotes"]) == ["symbol", "interval", "ts"]

    def test_the_symbol_points_at_the_catalogue(self, schema: MetaData) -> None:
        """Every symbol reaches the app through `stocks`; if this fires, something is wrong."""
        assert "stocks.symbol" in _foreign_keys(schema.tables["quotes"])

    def test_the_interval_is_constrained_to_the_three_values_of_req_16(
        self, schema: MetaData
    ) -> None:
        """A fourth interval cannot arrive through a code path that forgot to validate."""
        checks = [
            str(constraint.sqltext)
            for constraint in schema.tables["quotes"].constraints
            if isinstance(constraint, CheckConstraint)
        ]

        assert any(all(value in check for value in REQ_16_INTERVALS) for check in checks), (
            f"no CHECK on quotes constrains the interval to {REQ_16_INTERVALS}"
        )

    def test_there_is_an_index_for_the_range_the_chart_asks_for(self, schema: MetaData) -> None:
        """The chart asks for one symbol, one interval and a window: that is the index."""
        covered = [_index_columns(index) for index in schema.tables["quotes"].indexes]

        assert ["symbol", "interval", "ts"] in covered, (
            f"quotes has no index over (symbol, interval, ts); it has {covered}"
        )


class TestTheUsersTable:
    """`users` holds what the login checks, and nothing that would be worth stealing twice."""

    def test_the_username_is_unique(self, schema: MetaData) -> None:
        """Two users with the same username make the login ambiguous instead of wrong."""
        assert schema.tables["users"].columns["username"].unique

    def test_the_password_is_stored_hashed(self, schema: MetaData) -> None:
        """What is persisted is an Argon2id hash, and the column name says so."""
        columns = set(schema.tables["users"].columns.keys())

        assert "password_hash" in columns
        assert "password" not in columns


class TestTheSchemaCompositionRoot:
    """Alembic only migrates the tables that were imported before it read the metadata."""

    @pytest.mark.parametrize("module", sorted(TABLE_OF_MODULE))
    def test_alembic_knows_the_module_that_owns_each_table(self, module: str) -> None:
        """A model module nobody imports is a table autogenerate silently proposes dropping."""
        env = (BACKEND_ROOT / "alembic" / "env.py").read_text(encoding="utf-8")

        assert f"app.modules.{module}.models" in env


class TestTheThreeSymbolColumnsAgree:
    """`SYMBOL_LENGTH` is declared three times, and the three have to be the same number.

    The duplication is not an oversight and cannot be removed: each module owns its table, and
    `favorites` importing `app.modules.stocks.models` to borrow the number would be the interior
    of another module, which is the one thing the boundary forbids. Moving it to the kernel is
    worse -- `app/` would learn what a symbol is.

    So three copies it is, and what makes three copies safe is this test rather than the hope
    that whoever changes one changes the others. Drift is quiet in the worst way: `stocks` would
    accept a symbol that `favorites` truncates on INSERT, and the error would surface a module
    away from the line that caused it.
    """

    def test_every_module_that_stores_a_symbol_declares_the_same_length(self) -> None:
        """One number, three declarations, and the test is what keeps them one number."""
        declared = {
            module: import_module(f"app.modules.{module}.models").SYMBOL_LENGTH
            for module in ("stocks", "favorites", "quotes")
        }

        assert len(set(declared.values())) == 1, f"symbol columns disagree: {declared}"

    def test_the_symbol_columns_are_as_long_as_the_constant_says(self, schema: MetaData) -> None:
        """A constant nothing is measured against would agree with itself and with no column."""
        length = import_module("app.modules.stocks.models").SYMBOL_LENGTH

        for module, table in TABLE_OF_MODULE.items():
            if module == "auth":
                continue

            column_type = schema.tables[table].columns["symbol"].type

            assert isinstance(column_type, String)
            assert column_type.length == length, f"{table}.symbol is not {length} characters"
