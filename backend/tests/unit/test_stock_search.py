"""What the search decides before HTTP and before SQL.

**Everything here is red until task 11 exists**, and it is red by name. The four names the plan
fixed -- `search_stocks`, `MIN_QUERY_LENGTH`, `SUGGESTION_LIMIT`, `CANDIDATE_LIMIT` -- are looked
up on the service instead of imported from it, for the same reason `frontend/tests/client.test.ts`
casts `setAuthTokenProvider`: importing a name a module does not define yet is a collection error,
and a collection error hides every test of the file behind one line that says nothing about what
is missing. The lookup fails loudly, per test, saying which piece of the plan has not been written.
When task 11 lands, these helpers become a plain import.

Three decisions live in the service and none of them is visible from an integration test:

- **The order is applied before the cut.** The repository brings candidates up to
  `CANDIDATE_LIMIT`, the service ranks them and only then keeps `SUGGESTION_LIMIT`. Reading
  `search_listed(..., limit=20)` anywhere is the bug this asserts against: with the cut first,
  the twenty that survive are the ones the database happened to return.
- **A text that is too short never reaches the database.** `200 []` is the answer, and the
  spied repository is the only way to tell "it answered empty" from "it asked and got nothing".
- **The service does not escape and does not change case.** It hands over the text the person
  typed, stripped and nothing else: escaping `%` is the syntax of an operator the service does
  not know about, and a service that escaped would then rank an escaped
  `s_p` against a catalogue that stores `S_P Global`.

The ranking compares with `casefold()` on both sides, because the two fields are not in the same
case: `MSFT` is stored upper and `Microsoft Corp` is not, so one single folded comparison is the
only one that can serve both.
"""

from collections.abc import Awaitable
from datetime import UTC, datetime
from typing import Protocol, cast

import pytest
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.stocks import StockInfo
from app.modules.stocks import service as catalogue_service
from app.modules.stocks.models import Stock


class _SearchStocks(Protocol):
    """The signature the plan fixes for the search: the store first, raw text second."""

    def __call__(self, store: object, text: str) -> Awaitable[list[StockInfo]]:
        """Answer at most `SUGGESTION_LIMIT` suggestions, already ordered by relevance."""
        ...


def _of_the_service(name: str) -> object:
    """One name of `stocks/service.py`, or a failure that says which one is missing."""
    try:
        return getattr(catalogue_service, name)
    except AttributeError as missing:
        raise AssertionError(
            f"app/modules/stocks/service.py does not define {name} yet "
            "(plan.md -> Contratos -> GET /api/stocks, tasks.md task 11)"
        ) from missing


async def search_stocks(store: object, text: str) -> list[StockInfo]:
    """Call the service's search, failing by name while that door does not exist yet."""
    return await cast(_SearchStocks, _of_the_service("search_stocks"))(store, text)


def _suggestion_limit() -> int:
    """How many suggestions fit in the dropdown."""
    return cast(int, _of_the_service("SUGGESTION_LIMIT"))


def _candidate_limit() -> int:
    """The containment cap of the query, which is a different number for a different reason."""
    return cast(int, _of_the_service("CANDIDATE_LIMIT"))


def _min_query_length() -> int:
    """How short a text the service refuses to ask the database about."""
    return cast(int, _of_the_service("MIN_QUERY_LENGTH"))


# The repository is replaced in every test, so the session is never touched. It is passed anyway
# because the signature takes one: the service is the layer that has no business opening it.
_UNUSED_SESSION = cast(AsyncSession, object())

_SEEN_AT = datetime(2026, 9, 13, 12, 0, tzinfo=UTC)


def _row(symbol: str, name: str) -> Stock:
    """One catalogue row, built in memory: no session is open in a unit test."""
    return Stock(
        symbol=symbol,
        name=name,
        currency="USD",
        exchange="NASDAQ",
        mic_code="XNGS",
        country="United States",
        instrument_type="Common Stock",
        last_seen_at=_SEEN_AT,
        delisted_at=None,
    )


class _Catalogue:
    """Stand-in for `search_listed`, which remembers the text and the limit it was asked with."""

    def __init__(self, rows: list[Stock]) -> None:
        """Answer with those rows, whatever is asked, and keep the questions."""
        self.rows = rows
        self.asked_for: list[tuple[str, int]] = []

    async def search_listed(self, text: str, limit: int) -> list[Stock]:
        """Record the text and the limit the service passed down, then answer the fixed rows."""
        self.asked_for.append((text, limit))

        return list(self.rows)


@pytest.fixture
def catalogue() -> _Catalogue:
    """A spied repository holding the four groups of the ranking, in a misleading order."""
    return _Catalogue(
        [
            _row("ALPHA", "Amicrobial Labs"),
            _row("BETA", "Micron Systems"),
            _row("MICROX", "Zeta Holdings"),
            _row("MICRO", "Micro Devices"),
        ]
    )


class TestTheOrderByRelevance:
    """Exact symbol, then symbol that starts, then name that starts, then the rest."""

    async def test_the_four_groups_come_back_in_that_order(self, catalogue: _Catalogue) -> None:
        """One row per group, handed over shuffled so the sequence cannot be an accident."""
        found = await search_stocks(catalogue, "micro")

        assert [info.symbol for info in found] == ["MICRO", "MICROX", "BETA", "ALPHA"]

    async def test_inside_a_group_the_symbol_decides(self) -> None:
        """`symbol ASC` is what makes the answer the same on every call."""
        stub = _Catalogue([_row("ZZ", "Zz Micro Corp"), _row("AA", "Aa Micro Corp")])

        found = await search_stocks(stub, "micro")

        assert [info.symbol for info in found] == ["AA", "ZZ"]

    async def test_the_symbol_is_compared_without_case(self) -> None:
        """`msft` is the exact symbol `MSFT`, or the first group is empty for everybody."""
        stub = _Catalogue([_row("AMSFT", "Amsft Corp"), _row("MSFT", "Microsoft Corp")])

        found = await search_stocks(stub, "msft")

        assert [info.symbol for info in found] == ["MSFT", "AMSFT"]

    async def test_the_name_is_compared_without_case_too(self) -> None:
        """The half an `.upper()` breaks: `Microsoft Corp` does not start with `MICRO`."""
        stub = _Catalogue([_row("ZZZ", "Zeta Microsystems"), _row("MSFT", "Microsoft Corp")])

        found = await search_stocks(stub, "MICRO")

        assert [info.symbol for info in found] == ["MSFT", "ZZZ"]


class TestTheCutAtTwentyHappensAfterTheOrder:
    """the bug the plan corrected: ranking a set somebody already truncated."""

    async def test_at_most_twenty_come_back(self) -> None:
        """Twenty-five candidates, twenty suggestions: `SUGGESTION_LIMIT` is the dropdown."""
        stub = _Catalogue([_row(f"A{index:02d}", f"Amicrobial {index:02d}") for index in range(25)])

        found = await search_stocks(stub, "micro")

        assert len(found) == _suggestion_limit() == 20

    async def test_the_relevant_one_survives_the_cut(self) -> None:
        """`MSFT` sorts last by symbol and first by relevance, and twenty rows fit.

        Cutting before ranking drops it, and nothing downstream can bring it back: this is the
        acceptance criterion expressed against the service alone.
        """
        crowd = [_row(f"A{index:02d}", f"Amicrobial {index:02d}") for index in range(24)]
        stub = _Catalogue([*crowd, _row("MSFT", "Microsoft Corp")])

        found = await search_stocks(stub, "micro")

        assert next(info.symbol for info in found) == "MSFT"

    async def test_the_repository_is_asked_for_candidates_and_not_for_suggestions(
        self, catalogue: _Catalogue
    ) -> None:
        """`CANDIDATE_LIMIT` is a containment cap; `SUGGESTION_LIMIT` is a product decision.

        A `limit=20` travelling down to `search_listed` is the corrected bug returning, so the
        assertion is on the number that went down and not only on the number that came back.
        """
        await search_stocks(catalogue, "micro")

        assert catalogue.asked_for == [("micro", _candidate_limit())]
        assert _candidate_limit() > _suggestion_limit()


class TestATextThatIsTooShort:
    """from the service: `[]`, and the database never hears about it."""

    async def test_two_spaces_never_reach_the_repository(self, catalogue: _Catalogue) -> None:
        """`ILIKE '%%'` is the whole catalogue, and this is where it is not asked for.

        Integration cannot see this: an empty answer looks the same whether the query ran or
        not. `asked_for` staying empty is the assertion.
        """
        found = await search_stocks(catalogue, "  ")

        assert found == []
        assert catalogue.asked_for == []

    async def test_a_character_and_a_space_never_reach_it_either(
        self, catalogue: _Catalogue
    ) -> None:
        """One character of intention is below `MIN_QUERY_LENGTH`, whatever the router counted."""
        found = await search_stocks(catalogue, "a ")

        assert found == []
        assert catalogue.asked_for == []
        assert _min_query_length() == 2


class TestTheTextThatTravelsDown:
    """What the repository receives is the text, stripped -- not a pattern and not upper case."""

    async def test_the_surrounding_spaces_are_stripped_before_asking(
        self, catalogue: _Catalogue
    ) -> None:
        """The raw text would search `ILIKE '%  micro  %'` while the ranking read `micro`."""
        await search_stocks(catalogue, "  micro  ")

        assert catalogue.asked_for == [("micro", _candidate_limit())]

    async def test_the_case_is_left_alone(self, catalogue: _Catalogue) -> None:
        """`ILIKE` is case-insensitive by itself, so an `.upper()` here is a second rule."""
        await search_stocks(catalogue, "MiCrO")

        assert catalogue.asked_for == [("MiCrO", _candidate_limit())]

    async def test_a_wildcard_travels_unescaped(self, catalogue: _Catalogue) -> None:
        """Escaping is the repository's: a service that escaped would rank against `%a`.

        The consequence is not theoretical -- with the escape one layer up, the ranking would
        compare an escaped `s_p` against `S_P Global` and the name group would stop matching.
        """
        await search_stocks(catalogue, "%a")

        assert catalogue.asked_for == [("%a", _candidate_limit())]
