"""What listing the favourites decides, before HTTP and before SQL (RF-01, RF-03, RF-06).

Two collaborators are substituted here and neither one is patched: the service declares what it
needs -- a `FavoritesStore` for its own rows, a `Catalogue` for the batch lookup that belongs to
`stocks` -- and these are handed in. Nothing rewrites a module attribute, so what the test
exercises is the contract and not an import somebody could rename.

Three properties, and the order one is the subtle one. `get_stocks` answers a *set*: it is a
batch lookup and nothing in its contract promises a sequence. So the order of the grid is a
decision of this service, taken from what the repository already sorted, and an implementation
that simply forwarded the catalogue's answer would paint RF-06 wrong while every integration
test that only checks membership stayed green.

That the ordering *in the database* is `added_at DESC, symbol ASC` is a different claim, and it
is asserted against a real table in `tests/integration/test_favorites.py`.
"""

import pytest

from app.modules.favorites.service import list_favorites
from app.modules.stocks import StockInfo

_JUAN = 1

_CATALOGUE = {
    "TSLA": StockInfo(symbol="TSLA", name="Tesla Inc", currency="USD", is_listed=True),
    "AAPL": StockInfo(symbol="AAPL", name="Apple Inc", currency="USD", is_listed=True),
    "NFLX": StockInfo(symbol="NFLX", name="Netflix Inc", currency="USD", is_listed=True),
    "ZZZZ": StockInfo(symbol="ZZZZ", name="Zombie Holdings", currency="EUR", is_listed=False),
}


class _Store:
    """A `FavoritesStore` that answers a fixed list and remembers whose it was asked for."""

    def __init__(self, symbols: list[str]) -> None:
        """Answer every call with the same already-ordered list of symbols."""
        self.symbols = symbols
        self.asked_for: list[int] = []

    async def symbols_of(self, user_id: int) -> list[str]:
        """Record the user id the service passed down, then answer with the fixed list."""
        self.asked_for.append(user_id)

        return list(self.symbols)

    async def add(self, user_id: int, symbol: str) -> bool:
        """Not exercised here: adding has its own suite."""
        raise NotImplementedError

    async def remove(self, user_id: int, symbol: str) -> None:
        """Not exercised here: removing has its own suite."""
        raise NotImplementedError

    async def follows(self, user_id: int, symbol: str) -> bool:
        """Not exercised here: the question another module asks has its own suite."""
        raise NotImplementedError


class _Catalogue:
    """A `Catalogue` that answers out of order on purpose."""

    def __init__(self) -> None:
        """Start with no calls recorded: what matters is how many there are, and with what."""
        self.asked_for: list[list[str]] = []

    async def __call__(self, symbols: list[str]) -> list[StockInfo]:
        """Describe the symbols asked for, sorted alphabetically rather than as requested.

        The alphabetical answer is the test double doing its job: the contract promises a batch
        lookup and not a sequence, so a service that forwarded this list would be relying on
        something nobody agreed to.
        """
        self.asked_for.append(list(symbols))

        return [_CATALOGUE[symbol] for symbol in sorted(symbols) if symbol in _CATALOGUE]


@pytest.fixture
def catalogue() -> _Catalogue:
    """The batch lookup `favorites` is served with."""
    return _Catalogue()


class TestWhoseListItIs:
    """Article III at the layer that decides: the id travels down, it is never looked up."""

    async def test_the_repository_is_asked_for_the_user_it_was_given(
        self, catalogue: _Catalogue
    ) -> None:
        """The service passes on the id of the authenticated caller and invents none."""
        store = _Store(["TSLA"])

        await list_favorites(store, catalogue, _JUAN)

        assert store.asked_for == [_JUAN]


class TestTheOrderComesFromTheRepository:
    """RF-06: the grid is ordered by the query, and the service keeps that order."""

    async def test_the_answer_is_in_the_order_the_repository_gave(
        self, catalogue: _Catalogue
    ) -> None:
        """The catalogue answers alphabetically; the grid must not come out that way."""
        store = _Store(["NFLX", "AAPL", "TSLA"])

        favourites = await list_favorites(store, catalogue, _JUAN)

        assert [favourite.symbol for favourite in favourites] == ["NFLX", "AAPL", "TSLA"]

    async def test_a_single_favourite_is_answered_too(self, catalogue: _Catalogue) -> None:
        """The degenerate case of the ordering, stated so the reordering cannot drop a row."""
        store = _Store(["AAPL"])

        favourites = await list_favorites(store, catalogue, _JUAN)

        assert [favourite.symbol for favourite in favourites] == ["AAPL"]


class TestWhatEachRowCarries:
    """RF-03: symbol, name and currency, read from the catalogue and not from `user_stocks`."""

    async def test_it_carries_the_three_columns_of_the_grid(self, catalogue: _Catalogue) -> None:
        """The favourites table stores none of the last two: they can only come from `stocks`."""
        store = _Store(["TSLA"])

        favourite = (await list_favorites(store, catalogue, _JUAN))[0]

        assert (favourite.symbol, favourite.name, favourite.currency) == (
            "TSLA",
            "Tesla Inc",
            "USD",
        )

    async def test_a_favourite_that_stopped_trading_is_still_listed(
        self, catalogue: _Catalogue
    ) -> None:
        """The business rule: it leaves the suggestions, never the grid of whoever had it."""
        store = _Store(["ZZZZ"])

        favourites = await list_favorites(store, catalogue, _JUAN)

        assert [(row.symbol, row.name, row.currency) for row in favourites] == [
            ("ZZZZ", "Zombie Holdings", "EUR")
        ]


class TestItAsksTheCatalogueOnce:
    """GEN-02: the grid of N favourites is one cross-module call, not N."""

    async def test_the_whole_grid_is_one_call(self, catalogue: _Catalogue) -> None:
        """A `get_stocks` inside a `for` is the N+1 the boundary exists to prevent."""
        store = _Store(["NFLX", "AAPL", "TSLA"])

        await list_favorites(store, catalogue, _JUAN)

        assert catalogue.asked_for == [["NFLX", "AAPL", "TSLA"]]


class TestAUserWithNoFavourites:
    """RF-07 seen from the service: nothing to describe is an empty list, not a failure."""

    async def test_it_answers_an_empty_list(self, catalogue: _Catalogue) -> None:
        """The text of the empty state belongs to the screen; here there is just no row."""
        store = _Store([])

        favourites = await list_favorites(store, catalogue, _JUAN)

        assert favourites == []
