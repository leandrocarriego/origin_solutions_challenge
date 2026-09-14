"""GET /api/stocks: the autocomplete of the catalogue (RF-08 to RF-13).

Written before the route exists, so every test here answers 404 until task 11 mounts it. That
is the red this file is for: what it fixes is the behaviour the screen depends on, not the one
an implementation happens to have.

Four claims are the ones a well-meaning implementation gets wrong, and each has its own class:

- **What matches.** Symbol (RF-08), name (RF-09), and neither of the two cares about case in
  either direction (RF-10): the catalogue stores `MSFT` and `Microsoft Corp`, and a person types
  whatever they type.
- **Twenty at most, chosen by relevance** (RF-11). The cap only proves something with more than
  twenty matches, and the relevance only proves something when the one being looked for is not
  among the first twenty by symbol -- otherwise a repository that already truncated at twenty
  passes while broken. `micro` bringing back `MSFT` is that test.
- **The validation of the length is asymmetric, on purpose.** `q = "a"` is a **422** from the
  router, and `q = "  "` and `q = "a "` are **`200 []`** from the service. Two answers to what a
  client might call the same mistake, fixed here so that nobody "fixes" them into one.
- **The wildcards of the `LIKE` belong to nobody but the repository.** `%` and `_` are operators
  inside an `ILIKE`, and unescaped they let whoever types into the box write the query: `"%a"`
  would match everything with an `a` in it, and `"a_c"` would match `abc`. Escaping is what
  makes them what the user sees -- two characters that are in no name -- and a `_` that somebody
  really does search for keeps being found.

The delisted symbol is the fifth claim and the counterpart of the rule H1 already tests: it
leaves the suggestions (RF-12), while staying in the grid of whoever already had it.
"""

from collections.abc import AsyncIterator, Iterator
from datetime import UTC, datetime

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_session
from app.main import app
from app.modules.auth.models import User
from app.security import create_access_token
from app.settings import get_settings
from tests.factories.stock_factory import StockFactory
from tests.factories.user_factory import UserFactory

_STOCKS = "/api/stocks"
_SECRET = "a-signing-secret-of-at-least-32-chars"

_DELISTED_AT = datetime(2026, 8, 1, tzinfo=UTC)

# More than the twenty of RF-11, so the cap has something to cut. Their names carry `micro`
# without starting with it, and their symbols sort before `MSFT`: ordered by symbol alone they
# would fill the whole dropdown and leave out the one company anybody typing `micro` is after.
_CROWD = 24


@pytest.fixture(autouse=True)
def signing_secret(monkeypatch: pytest.MonkeyPatch) -> Iterator[str]:
    """A usable `JWT_SECRET`, read at call time the way a request reads it."""
    get_settings.cache_clear()
    monkeypatch.setenv("JWT_SECRET", _SECRET)

    yield _SECRET

    get_settings.cache_clear()


@pytest.fixture
async def client(session: AsyncSession) -> AsyncIterator[AsyncClient]:
    """A client whose requests run inside the test's transaction, so nothing is left behind."""
    app.dependency_overrides[get_session] = lambda: session
    transport = ASGITransport(app=app)

    async with AsyncClient(transport=transport, base_url="http://test") as opened:
        yield opened

    app.dependency_overrides.pop(get_session, None)


@pytest.fixture
async def juan(session: AsyncSession) -> User:
    """Somebody signed in: the catalogue is not user data, but it is not public either."""
    return await UserFactory.create(session, username="juan", full_name="Juan Perez")


@pytest.fixture
async def catalogue(session: AsyncSession) -> None:
    """A catalogue big enough for the cap and awkward enough for the relevance.

    `MSFT` is the row every test about `micro` is looking for, and the twenty-four around it
    exist so that finding it means something: they match the same text, they sort first by
    symbol, and their names carry `micro` in the middle rather than at the start.

    The rest are the edges: a delisted symbol (RF-12), a name with an underscore in it, and one
    plain row whose symbol has nothing to do with any of the searches.
    """
    await StockFactory.create(session, symbol="MSFT", name="Microsoft Corp", currency="USD")

    for index in range(_CROWD):
        await StockFactory.create(
            session,
            symbol=f"A{index:02d}",
            name=f"Amicrobial Labs {index:02d}",
            currency="USD",
        )

    await StockFactory.create(
        session,
        symbol="ZZZZ",
        name="Zombie Microsystems",
        currency="USD",
        delisted_at=_DELISTED_AT,
    )
    await StockFactory.create(session, symbol="SPGI", name="S_P Global", currency="USD")
    await StockFactory.create(session, symbol="ABC", name="Abc Corp", currency="USD")


def _bearer(user: User) -> dict[str, str]:
    """The header a session token for that user travels in."""
    token = create_access_token(user_id=user.id, full_name=user.full_name)

    return {"Authorization": f"Bearer {token}"}


def _symbols(payload: list[dict[str, str]]) -> list[str]:
    """The symbols of a suggestions response, in the order the endpoint answered them."""
    return [row["symbol"] for row in payload]


class TestWhatTheTextMatches:
    """RF-08, RF-09 and RF-10: symbol, name, and case in neither direction."""

    async def test_a_piece_of_the_symbol_finds_the_stock(
        self, client: AsyncClient, juan: User, catalogue: None
    ) -> None:
        """RF-08: typing part of the symbol is the fastest way to reach a known company."""
        response = await client.get(_STOCKS, params={"q": "MSF"}, headers=_bearer(juan))

        assert response.status_code == 200
        assert "MSFT" in _symbols(response.json())

    async def test_a_piece_of_the_name_finds_the_stock(
        self, client: AsyncClient, juan: User, catalogue: None
    ) -> None:
        """RF-09: somebody who knows the company and not its ticker still finds it."""
        response = await client.get(_STOCKS, params={"q": "Microsoft"}, headers=_bearer(juan))

        assert "MSFT" in _symbols(response.json())

    async def test_lower_case_finds_an_upper_case_symbol(
        self, client: AsyncClient, juan: User, catalogue: None
    ) -> None:
        """RF-10, one direction: the catalogue stores `MSFT` and nobody types in caps."""
        response = await client.get(_STOCKS, params={"q": "msft"}, headers=_bearer(juan))

        assert "MSFT" in _symbols(response.json())

    async def test_upper_case_finds_a_mixed_case_name(
        self, client: AsyncClient, juan: User, catalogue: None
    ) -> None:
        """RF-10, the other direction, and the one an `.upper()` on the text would break.

        The catalogue stores `Microsoft Corp`, so a search normalised to upper case matches the
        symbol and never the name. Asserting both directions is what tells "case-insensitive"
        apart from "upper-cased before asking".
        """
        response = await client.get(_STOCKS, params={"q": "MICROSOFT"}, headers=_bearer(juan))

        assert "MSFT" in _symbols(response.json())

    async def test_a_row_carries_the_symbol_the_name_and_the_currency(
        self, client: AsyncClient, juan: User, catalogue: None
    ) -> None:
        """Three fields and no fourth: `is_listed` is always true here, so it does not travel."""
        response = await client.get(_STOCKS, params={"q": "MSFT"}, headers=_bearer(juan))

        assert response.json() == [{"symbol": "MSFT", "name": "Microsoft Corp", "currency": "USD"}]

    async def test_an_anonymous_call_is_refused(self, client: AsyncClient) -> None:
        """PY-08: the catalogue is not user data, and it is not public either."""
        response = await client.get(_STOCKS, params={"q": "micro"})

        assert response.status_code == 401


class TestHowManyComeBackAndWhich:
    """RF-11 and the relevance: twenty at most, and the right twenty."""

    async def test_a_very_common_text_answers_twenty(
        self, client: AsyncClient, juan: User, catalogue: None
    ) -> None:
        """Twenty-five rows match `micro`; a dropdown holds twenty (RF-11)."""
        response = await client.get(_STOCKS, params={"q": "micro"}, headers=_bearer(juan))

        assert len(response.json()) == 20

    async def test_micro_brings_microsoft_among_the_twenty(
        self, client: AsyncClient, juan: User, catalogue: None
    ) -> None:
        """The acceptance criterion of RF-15, and the test that tells the two layers apart.

        Twenty-four symbols sort before `MSFT` and match the same text. If the repository cut at
        twenty before anybody ranked anything, `MSFT` is simply not in the set the service gets
        and no later ordering can bring it back -- which is the failure this catalogue is built
        to produce. The cut belongs after the ranking, and this is what says so.
        """
        response = await client.get(_STOCKS, params={"q": "micro"}, headers=_bearer(juan))

        assert "MSFT" in _symbols(response.json())

    async def test_the_name_that_starts_with_the_text_comes_before_the_rest(
        self, client: AsyncClient, juan: User, catalogue: None
    ) -> None:
        """Relevance, not the alphabet: `Microsoft Corp` starts with it, `Amicrobial` does not."""
        response = await client.get(_STOCKS, params={"q": "micro"}, headers=_bearer(juan))

        assert _symbols(response.json())[0] == "MSFT"

    async def test_no_match_answers_an_empty_list(
        self, client: AsyncClient, juan: User, catalogue: None
    ) -> None:
        """An empty list is a result, and the text that replaces the rows is the screen's."""
        response = await client.get(_STOCKS, params={"q": "qqqqqq"}, headers=_bearer(juan))

        assert response.status_code == 200
        assert response.json() == []


class TestASymbolThatStoppedTrading:
    """RF-12: it leaves the suggestions, and only the suggestions."""

    async def test_it_is_not_suggested_even_by_its_whole_symbol(
        self, client: AsyncClient, juan: User, catalogue: None
    ) -> None:
        """The strongest possible query for it -- the exact symbol -- still answers `[]`."""
        response = await client.get(_STOCKS, params={"q": "ZZZZ"}, headers=_bearer(juan))

        assert response.json() == []

    async def test_it_is_not_suggested_by_its_name_either(
        self, client: AsyncClient, juan: User, catalogue: None
    ) -> None:
        """`Zombie Microsystems` matches `micro` and is filtered out all the same."""
        response = await client.get(_STOCKS, params={"q": "micro"}, headers=_bearer(juan))

        assert "ZZZZ" not in _symbols(response.json())


class TestHowShortATextIsRejected:
    """RF-13, and the asymmetry between the router and the service.

    The two answers are different on purpose and the reason is written in the plan: the 422 is
    the contract of the transport about what arrived, and the `[]` is the result of the domain
    about what was asked. A test that demanded one answer for both would be asking the service
    to speak HTTP or the router to normalise text.
    """

    async def test_one_character_is_a_422(
        self, client: AsyncClient, juan: User, catalogue: None
    ) -> None:
        """The router refuses it before any service exists (RF-13)."""
        response = await client.get(_STOCKS, params={"q": "a"}, headers=_bearer(juan))

        assert response.status_code == 422

    async def test_two_spaces_are_an_empty_list_and_not_a_422(
        self, client: AsyncClient, juan: User, catalogue: None
    ) -> None:
        """`"  "` passes the router's `min_length` and is no text at all once stripped.

        Without the guard this ends up as `ILIKE '%%'`, which matches the whole catalogue: the
        cost RF-13's minimum exists to avoid, paid by a query the minimum never saw.
        """
        response = await client.get(_STOCKS, params={"q": "  "}, headers=_bearer(juan))

        assert response.status_code == 200
        assert response.json() == []

    async def test_a_character_and_a_space_are_an_empty_list_too(
        self, client: AsyncClient, juan: User, catalogue: None
    ) -> None:
        """One character of intention, whatever the router counted."""
        response = await client.get(_STOCKS, params={"q": "a "}, headers=_bearer(juan))

        assert response.status_code == 200
        assert response.json() == []

    async def test_the_surrounding_spaces_do_not_change_the_answer(
        self, client: AsyncClient, juan: User, catalogue: None
    ) -> None:
        """The positive half of the same `strip()`: `" micro "` is `micro`."""
        padded = await client.get(_STOCKS, params={"q": " micro "}, headers=_bearer(juan))
        plain = await client.get(_STOCKS, params={"q": "micro"}, headers=_bearer(juan))

        assert padded.status_code == 200
        assert "MSFT" in _symbols(padded.json())
        assert padded.json() == plain.json()


class TestTheWildcardsOfTheLike:
    """The escaping, asserted against real SQL because that is what it is about."""

    async def test_a_percent_sign_does_not_bring_the_whole_catalogue(
        self, client: AsyncClient, juan: User, catalogue: None
    ) -> None:
        """`"%a"` is two characters somebody typed, not an operator they get to use.

        Unescaped it becomes `ILIKE '%%a%'` and matches everything with an `a` in it -- a wide
        scan that the two-character guard let through precisely because it assumed two
        characters narrow a search.
        """
        response = await client.get(_STOCKS, params={"q": "%a"}, headers=_bearer(juan))

        assert response.json() == []

    async def test_an_underscore_does_not_match_any_character(
        self, client: AsyncClient, juan: User, catalogue: None
    ) -> None:
        """`a_c` is a text, so it does not find `Abc Corp`."""
        response = await client.get(_STOCKS, params={"q": "a_c"}, headers=_bearer(juan))

        assert "ABC" not in _symbols(response.json())

    async def test_an_underscore_that_really_is_in_a_name_is_found(
        self, client: AsyncClient, juan: User, catalogue: None
    ) -> None:
        """Escaping means the `_` is searched for, not that it is ignored: `S_P Global`."""
        response = await client.get(_STOCKS, params={"q": "s_p"}, headers=_bearer(juan))

        assert _symbols(response.json()) == ["SPGI"]

    async def test_an_ordinary_text_answers_exactly_what_it_did_before(
        self, client: AsyncClient, juan: User, catalogue: None
    ) -> None:
        """The case that happens always: no wildcard, nothing escaped, nothing changed."""
        response = await client.get(_STOCKS, params={"q": "microsoft"}, headers=_bearer(juan))

        assert _symbols(response.json()) == ["MSFT"]
