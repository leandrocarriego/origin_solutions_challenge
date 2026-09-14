"""What the catalogue hands to another module (RF-01, RF-03, GEN-02).

`get_stocks` is one of the two cross-module reads of the whole backend, so what it returns *is*
the contract: `favorites` sees a `StockInfo` and never a row of `stocks`. Three properties are
the ones a refactor breaks without any test noticing, and each is asserted here on its own:

- **The ORM row does not leave the module.** A contract that returned the model would hand the
  session and the table layout to whoever called it, and the boundary would exist only in the
  documentation (Article IV).
- **It answers in one call.** The grid of N favourites is one question, not N. The N+1 leaves
  every functional test green, so the only way to catch it is to count what the repository was
  asked -- which is what the stub here does.
- **`is_listed` travels.** It is the fourth field of `StockInfo` and the reason the same
  function can serve two opposite needs: showing a favourite that stopped trading, and refusing
  to add one.

The repository is stubbed: what is under test is the conversion and the shape of the call, not
the SQL, which is asserted against a real table in `tests/integration/`.
"""

import dataclasses
from datetime import UTC, datetime
from typing import cast

import pytest
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.stocks import StockInfo, get_stocks
from app.modules.stocks.models import Stock

# The repository is replaced in every test, so the session is never touched. It is passed anyway
# because the signature takes one: the service is the layer that has no business opening it.
_UNUSED_SESSION = cast(AsyncSession, object())

_SEEN_AT = datetime(2026, 9, 13, 12, 0, tzinfo=UTC)
_DELISTED_AT = datetime(2026, 8, 1, tzinfo=UTC)


def _row(symbol: str, name: str, currency: str = "USD", delisted: bool = False) -> Stock:
    """One catalogue row, built in memory: no session is open in a unit test."""
    return Stock(
        symbol=symbol,
        name=name,
        currency=currency,
        exchange="NASDAQ",
        mic_code="XNGS",
        country="United States",
        instrument_type="Common Stock",
        last_seen_at=_SEEN_AT,
        delisted_at=_DELISTED_AT if delisted else None,
    )


class _Catalogue:
    """Stand-in for `find_many`, which remembers every call it was asked to serve."""

    def __init__(self, rows: list[Stock]) -> None:
        """Answer with those rows, whatever is asked, and keep the questions."""
        self.rows = rows
        self.asked_for: list[list[str]] = []

    async def find_many(self, session: AsyncSession, symbols: list[str]) -> list[Stock]:
        """Record the batch the service asked for, then answer with the fixed rows."""
        self.asked_for.append(list(symbols))

        return [row for row in self.rows if row.symbol in set(symbols)]


@pytest.fixture
def catalogue(monkeypatch: pytest.MonkeyPatch) -> _Catalogue:
    """A catalogue holding the three symbols of the wireframe, wired where the service reads it."""
    stub = _Catalogue(
        [
            _row("TSLA", "Tesla Inc"),
            _row("AAPL", "Apple Inc"),
            _row("NFLX", "Netflix Inc"),
        ]
    )
    monkeypatch.setattr("app.modules.stocks.service.find_many", stub.find_many)

    return stub


class TestWhatItReturns:
    """`StockInfo`, with the four fields of the contract and nothing of SQLAlchemy."""

    async def test_it_returns_stock_info_and_not_the_model(self, catalogue: _Catalogue) -> None:
        """Article IV: the row stays inside the module that owns the table."""
        described = await get_stocks(_UNUSED_SESSION, ["TSLA"])

        assert [type(info) for info in described] == [StockInfo]

    async def test_the_orm_row_leaves_no_trace_in_it(self, catalogue: _Catalogue) -> None:
        """The same statement said so that a subclass or a wrapper cannot pass it.

        `_sa_instance_state` is what an ORM object carries and a dataclass does not, and
        `exchange` is a column the contract deliberately does not publish.
        """
        info = (await get_stocks(_UNUSED_SESSION, ["TSLA"]))[0]

        assert not hasattr(info, "_sa_instance_state")
        assert not hasattr(info, "exchange")

    async def test_it_carries_the_symbol_the_name_and_the_currency(
        self, catalogue: _Catalogue
    ) -> None:
        """RF-03: the three columns of the grid, which is what the caller came for."""
        info = (await get_stocks(_UNUSED_SESSION, ["TSLA"]))[0]

        assert (info.symbol, info.name, info.currency) == ("TSLA", "Tesla Inc", "USD")

    async def test_it_cannot_be_edited_by_whoever_receives_it(self, catalogue: _Catalogue) -> None:
        """Frozen: a description another module could rewrite is not a contract.

        The assignment goes through `setattr` with the name in a variable so that the statement
        under test is the runtime one. Written as `info.name = ...` it would be a type error as
        well, and a type error is checked by `mypy` and never reached by the run.
        """
        info = (await get_stocks(_UNUSED_SESSION, ["TSLA"]))[0]
        field = "name"

        with pytest.raises(dataclasses.FrozenInstanceError):
            setattr(info, field, "Something Else")

    async def test_it_describes_every_symbol_the_catalogue_had(self, catalogue: _Catalogue) -> None:
        """One description per row found, so the grid can be painted from the answer alone."""
        described = await get_stocks(_UNUSED_SESSION, ["TSLA", "AAPL", "NFLX"])

        assert {info.symbol for info in described} == {"TSLA", "AAPL", "NFLX"}

    async def test_a_symbol_the_catalogue_does_not_have_is_simply_absent(
        self, catalogue: _Catalogue
    ) -> None:
        """Not an error: asking about something unknown is answered by not describing it."""
        described = await get_stocks(_UNUSED_SESSION, ["TSLA", "ZZZZ"])

        assert {info.symbol for info in described} == {"TSLA"}

    async def test_a_repeated_symbol_is_described_only_once(self, catalogue: _Catalogue) -> None:
        """Set semantics: the length of the answer does not follow the length of the question.

        Asking twice about the same symbol is asking the same thing twice, and a description is
        of a symbol and not of a position in the list. The implementation this rules out is the
        one that builds the answer by walking the input and looking each symbol up: that one
        hands back a row per repetition, and every other test of this file stays green while it
        does. Today the list comes from `symbols_of`, where the `(user_id, symbol)` primary key
        makes a repeat impossible -- so this fixes the answer before a second caller builds the
        list some other way and discovers it by accident.
        """
        described = await get_stocks(_UNUSED_SESSION, ["TSLA", "TSLA"])

        assert [info.symbol for info in described] == ["TSLA"]


class TestTheSymbolsArriveInUpperCase:
    """The precondition of the contract, written in code instead of in prose."""

    async def test_the_same_symbol_in_lower_case_is_not_described(
        self, catalogue: _Catalogue
    ) -> None:
        """`get_stocks` does not normalise, and the silence that costs is fixed here.

        Normalising already has an owner -- `add_favorite`, which does `strip().upper()` before
        looking at the catalogue -- and two places that normalise are two places that one day do
        it differently. The price is that a caller passing lower case gets no error: it gets
        `[]`, which travels up as a 404 for a symbol that does exist. That is deliberate, so it
        has to be asserted rather than discovered, and the defence is this test and never an
        `upper()` inside `get_stocks`.

        The two halves are one test on purpose: `[]` alone would be indistinguishable from a
        symbol the catalogue never had. Paired with the same symbol in upper case returning its
        row, it can only be read as the precondition.
        """
        assert [info.symbol for info in await get_stocks(_UNUSED_SESSION, ["TSLA"])] == ["TSLA"]

        assert await get_stocks(_UNUSED_SESSION, ["tsla"]) == []


class TestWhetherItIsStillListed:
    """The fourth field, and the two opposite things `favorites` does with it."""

    async def test_a_listed_symbol_is_listed(self, catalogue: _Catalogue) -> None:
        """`delisted_at` null means it still trades, which is the ordinary case."""
        info = (await get_stocks(_UNUSED_SESSION, ["TSLA"]))[0]

        assert info.is_listed is True

    async def test_a_delisted_symbol_is_described_and_marked(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """It is described and not filtered out: the grid of whoever had it must not lose a row."""
        stub = _Catalogue([_row("ZZZZ", "Zombie Holdings", delisted=True)])
        monkeypatch.setattr("app.modules.stocks.service.find_many", stub.find_many)

        described = await get_stocks(_UNUSED_SESSION, ["ZZZZ"])

        assert [(info.symbol, info.is_listed) for info in described] == [("ZZZZ", False)]


class TestItAnswersInOneCall:
    """The N+1 that the module boundary exists to prevent (GEN-02)."""

    async def test_the_repository_is_asked_once_for_the_whole_batch(
        self, catalogue: _Catalogue
    ) -> None:
        """Three favourites are one question. A loop here costs a query per row of the grid."""
        await get_stocks(_UNUSED_SESSION, ["TSLA", "AAPL", "NFLX"])

        assert catalogue.asked_for == [["TSLA", "AAPL", "NFLX"]]

    async def test_asking_about_nothing_never_reaches_the_repository(
        self, catalogue: _Catalogue
    ) -> None:
        """A user with no favourites: the service answers `[]` without asking the database.

        This is the ordinary path of `GET /api/favorites`, not a rare edge: `favorites` hands
        over whatever list of symbols it has, empty included. The guard belongs to the service,
        because "is this query worth making" is a decision and decisions do not live in the
        repository (`PY-06`). `asked_for` staying empty is what tells "it was never called"
        apart from "it was called with an empty list", which is the whole point.
        """
        described = await get_stocks(_UNUSED_SESSION, [])

        assert described == []
        assert catalogue.asked_for == []
