"""`Histórico`: the window the user asks for, and the windows that cannot be asked for.

H3 seen from the endpoint (RF-16, RF-36, RF-41 to RF-45, RF-47). `Tiempo Real` and `Histórico`
are the same route: what tells them apart is whether `from` and `to` travel with the request.

Three claims here are the ones an implementation that "works" still gets wrong:

- **`from` and `to` are market hours**, not server hours. Two tests ask for the same stored
  candle, once in each reading, and only one of them may find it. A service that stamped UTC on
  the naive input would answer both, and the whole chart would sit four hours away from where it
  was asked for.
- **The series falls entirely inside the window** (RF-16): no point before `from`, none after
  `to`. A repository that answered "everything for the symbol" passes a chart that looks right
  on a fresh database and wrong on a full one.
- **An invalid range costs nothing** (RF-47): no credit, and not one query against the database
  -- neither the cache nor the membership. The 422 is step 1, decided before authorizing and
  before the window is resolved, which is the ordering `plan.md` fixed on 2026-09-14 so that
  "it is not executed" means what it says.

The provider is a double that counts calls, and the database is watched through the statements
the engine really executes: nothing in a response body tells a cached answer from one that spent
a credit (Article II, TEST-03).
"""

from collections.abc import AsyncIterator, Iterator, Sequence
from datetime import UTC, datetime, timedelta
from decimal import Decimal
from typing import Any

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy import event, select
from sqlalchemy.engine import Engine
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_session
from app.main import app
from app.modules.auth.models import User
from app.modules.favorites.models import UserStock
from app.modules.quotes.models import Quote
from app.modules.stocks.models import Stock
from app.providers import (
    MarketDataProvider,
    QuotePoint,
    StockRecord,
    get_market_data_provider,
)
from app.security import create_access_token
from app.settings import get_settings
from tests.factories.user_factory import UserFactory

_QUOTES = "/api/quotes/TSLA"
_SYMBOL = "TSLA"
_SECRET = "a-signing-secret-of-at-least-32-chars"

# A session of the past, which is what `Histórico` is about. 13:35Z is 09:35 in New York, five
# minutes after the opening bell -- and, read as a server hour, half past one in the afternoon.
# That distance of four hours is what makes the timezone testable at all.
_TRADED_ON = datetime(2026, 9, 8, 13, 35, tzinfo=UTC)

# The opening and the close of that same session, written the way the user writes them: naive,
# and in the hours the market keeps (RF-36).
_MARKET_OPEN = "2026-09-08T09:30:00"
_MARKET_CLOSE = "2026-09-08T16:00:00"

# The caps of `plan.md`, one per interval (RF-42 to RF-44). Written out rather than imported
# from the service: a constant asserted against itself proves nothing, and what the spec fixes
# is the number of days, not the name of the dictionary that holds it.
_CAPS = [("1min", 7), ("5min", 30), ("15min", 90)]

# The four windows the backend refuses, which are the ones RF-47 says cost nothing.
_REFUSED_RANGES = [
    {"interval": "1min", "from": "2026-09-08T10:00:00", "to": "2026-09-08T10:00:00"},
    {"interval": "1min", "from": "2026-09-08T11:00:00", "to": "2026-09-08T10:00:00"},
    {"interval": "1min", "from": "2026-06-01T10:00:00", "to": "2026-06-30T10:00:00"},
    {"interval": "1min", "from": _MARKET_OPEN},
]
_REFUSED_IDS = ["equal", "reversed", "too long", "half a range"]


class _CountingProvider(MarketDataProvider):
    """The contract, counting calls: the only way Article II is checkable from the outside."""

    def __init__(self, points: Sequence[QuotePoint] = ()) -> None:
        """Answer with those points, and remember every window it was asked for."""
        self.points = list(points)
        self.calls: list[tuple[str, str, datetime, datetime]] = []

    async def list_stocks(self, exchange: str) -> list[StockRecord]:
        """Not what this endpoint asks for; the catalogue is another module's business."""
        return []

    async def get_time_series(
        self, symbol: str, interval: str, start: datetime, end: datetime
    ) -> list[QuotePoint]:
        """Record the call before anything else, then answer."""
        self.calls.append((symbol, interval, start, end))

        return list(self.points)


@pytest.fixture(autouse=True)
def signing_secret(monkeypatch: pytest.MonkeyPatch) -> Iterator[str]:
    """A usable `JWT_SECRET`, read at call time the way a request reads it."""
    get_settings.cache_clear()
    monkeypatch.setenv("JWT_SECRET", _SECRET)

    yield _SECRET

    get_settings.cache_clear()


@pytest.fixture
def provider() -> Iterator[_CountingProvider]:
    """The market data provider the request is served with, and its call counter."""
    double = _CountingProvider()
    app.dependency_overrides[get_market_data_provider] = lambda: double

    yield double

    app.dependency_overrides.pop(get_market_data_provider, None)


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
    """The demo user of the README, following the symbol of the wireframe."""
    user = await UserFactory.create(session, username="juan", full_name="Juan Perez")
    await _follow(session, user_id=user.id, symbol=_SYMBOL)

    return user


@pytest.fixture
def statements() -> Iterator[list[str]]:
    """Every SQL statement the engine executes while the test runs.

    RF-47 says an invalid range is refused *before* anything else happens, and "anything else"
    includes the authorization and the cache. Recording the statements is what makes that
    observable from outside: a validation done later is green on the body and wrong on the
    ordering.

    The list is shared with the arrangement, so a test that cares about it empties it before
    acting -- the rows a test sets up are not what it is measuring.
    """
    recorded: list[str] = []

    def _record(
        conn: Any, cursor: Any, statement: str, parameters: Any, context: Any, executemany: bool
    ) -> None:
        """Keep the statement text, which is all these assertions look at."""
        recorded.append(statement)

    event.listen(Engine, "before_cursor_execute", _record)

    yield recorded

    event.remove(Engine, "before_cursor_execute", _record)


async def _follow(session: AsyncSession, user_id: int, symbol: str) -> None:
    """Make the symbol one of that user's favourites, catalogue row included.

    The chart is served only for the acciones of whoever is asking (RF-35), so every test here
    needs the membership to exist or it would be measuring a 404 instead of a range.
    """
    await _catalogue(session, symbol)
    session.add(UserStock(user_id=user_id, symbol=symbol))
    await session.flush()


async def _catalogue(session: AsyncSession, symbol: str) -> None:
    """Insert the `stocks` row the two foreign keys need, if it is not there yet."""
    existing = await session.get(Stock, symbol)
    if existing is not None:
        return

    session.add(
        Stock(
            symbol=symbol,
            name="Tesla Inc",
            currency="USD",
            exchange="NASDAQ",
            mic_code="XNGS",
            country="United States",
            instrument_type="Common Stock",
            last_seen_at=datetime.now(tz=UTC),
        )
    )
    await session.flush()


async def _candle(
    session: AsyncSession, ts: datetime, interval: str = "1min", close: str = "365.47"
) -> None:
    """Store one candle of `TSLA`, which is what a warm cache looks like."""
    price = Decimal(close)
    await _catalogue(session, _SYMBOL)

    session.add(
        Quote(
            symbol=_SYMBOL,
            interval=interval,
            ts=ts,
            open_price=price - Decimal("0.5"),
            high_price=price + Decimal("0.75"),
            low_price=price - Decimal("0.75"),
            close_price=price,
            volume=100_000,
        )
    )
    await session.flush()


def _bearer(user: User) -> dict[str, str]:
    """The header a session token for that user travels in."""
    token = create_access_token(user_id=user.id, full_name=user.full_name)

    return {"Authorization": f"Bearer {token}"}


def _instants(payload: dict[str, Any]) -> list[datetime]:
    """The instants of a response, parsed: the wire format is not what is under test here."""
    return [datetime.fromisoformat(point["ts"]) for point in payload["points"]]


def _touched_the_database(statements: Sequence[str]) -> bool:
    """Whether any statement went to a table this endpoint reads.

    RF-47 is taken literally *(decision of 2026-09-14, in `plan.md`)*: validating the range is
    step 1, ahead of authorizing, so a window that cannot be asked for reads nothing at all --
    neither `user_stocks`, which is how `favorites` answers whose symbol it is, nor `quotes`,
    which is the cache. Both tables are named here because leaving either out would let the
    ordering slip back by one step without a test noticing.

    Transaction bookkeeping is not a read, so what is looked for is the tables and not the
    number of statements: a savepoint the fixture opens says nothing about this requirement.
    """
    return any(
        table in statement.lower()
        for statement in statements
        for table in ("quotes", "user_stocks")
    )


class TestTheWindowTheUserAsksFor:
    """RF-16 and RF-36: the hours are the market's, and the series stays inside them."""

    async def test_from_and_to_are_read_as_market_hours(
        self, client: AsyncClient, juan: User, provider: _CountingProvider, session: AsyncSession
    ) -> None:
        """09:30 to 10:00 is the opening of the session, and the stored candle is inside it."""
        await _candle(session, ts=_TRADED_ON)

        response = await client.get(
            _QUOTES,
            params={"interval": "1min", "from": _MARKET_OPEN, "to": "2026-09-08T10:00:00"},
            headers=_bearer(juan),
        )

        assert _instants(response.json()) == [_TRADED_ON]

    async def test_from_and_to_are_not_read_as_server_hours(
        self, client: AsyncClient, juan: User, provider: _CountingProvider, session: AsyncSession
    ) -> None:
        """The same candle, asked for by its UTC wall clock, must not be found.

        This is the half that catches the bug. A service that stamped UTC on the naive input
        would answer the 13:35Z candle here as well, and both tests would be green while the
        chart sat four hours away from where the user pointed.
        """
        await _candle(session, ts=_TRADED_ON)

        response = await client.get(
            _QUOTES,
            params={
                "interval": "1min",
                "from": "2026-09-08T13:30:00",
                "to": "2026-09-08T14:00:00",
            },
            headers=_bearer(juan),
        )

        assert response.json()["points"] == []

    async def test_the_series_falls_entirely_inside_the_window(
        self, client: AsyncClient, juan: User, provider: _CountingProvider, session: AsyncSession
    ) -> None:
        """RF-16: no point before `from`, and no point after `to`."""
        await _candle(session, ts=_TRADED_ON - timedelta(hours=2))
        await _candle(session, ts=_TRADED_ON)
        await _candle(session, ts=_TRADED_ON + timedelta(hours=8))

        response = await client.get(
            _QUOTES,
            params={"interval": "1min", "from": _MARKET_OPEN, "to": _MARKET_CLOSE},
            headers=_bearer(juan),
        )

        assert _instants(response.json()) == [_TRADED_ON]

    async def test_the_window_asked_for_answers_200(
        self, client: AsyncClient, juan: User, provider: _CountingProvider, session: AsyncSession
    ) -> None:
        """The happy path of H3, which is the call the screen makes with `Histórico` marked."""
        await _candle(session, ts=_TRADED_ON)

        response = await client.get(
            _QUOTES,
            params={"interval": "1min", "from": _MARKET_OPEN, "to": _MARKET_CLOSE},
            headers=_bearer(juan),
        )

        assert response.status_code == 200

    async def test_a_cached_window_of_the_past_spends_no_credit(
        self, client: AsyncClient, juan: User, provider: _CountingProvider, session: AsyncSession
    ) -> None:
        """Yesterday's prices do not expire, so a closed window is never fetched twice.

        It is the one place where the TTL must *not* apply: a candle of last Tuesday is a week
        old and perfectly current, because the session it belongs to finished happening.
        """
        await _candle(session, ts=_TRADED_ON)
        await _candle(session, ts=_TRADED_ON + timedelta(minutes=1))

        response = await client.get(
            _QUOTES,
            params={"interval": "1min", "from": _MARKET_OPEN, "to": _MARKET_CLOSE},
            headers=_bearer(juan),
        )

        assert response.status_code == 200
        assert provider.calls == []


class TestARangeThatCannotBeAskedFor:
    """RF-41 to RF-45: the 422 the screen turns into the text under the date fields."""

    @pytest.mark.parametrize(
        "start,end",
        [
            ("2026-09-08T10:00:00", "2026-09-08T10:00:00"),
            ("2026-09-08T11:00:00", "2026-09-08T10:00:00"),
        ],
        ids=["equal", "reversed"],
    )
    async def test_from_not_before_to_is_422(
        self, client: AsyncClient, juan: User, provider: _CountingProvider, start: str, end: str
    ) -> None:
        """RF-41: `desde` equal to `hasta` is an empty window, and after it is a mistake."""
        response = await client.get(
            _QUOTES,
            params={"interval": "1min", "from": start, "to": end},
            headers=_bearer(juan),
        )

        assert response.status_code == 422

    @pytest.mark.parametrize(
        "start,end",
        [
            ("2026-09-08T10:00:00", "2026-09-08T10:00:00"),
            ("2026-09-08T11:00:00", "2026-09-08T10:00:00"),
        ],
        ids=["equal", "reversed"],
    )
    async def test_an_inverted_range_says_which_rule_it_broke(
        self, client: AsyncClient, juan: User, provider: _CountingProvider, start: str, end: str
    ) -> None:
        """The `code` is what the screen maps to a literal of COPY.md; the body carries no text."""
        response = await client.get(
            _QUOTES,
            params={"interval": "1min", "from": start, "to": end},
            headers=_bearer(juan),
        )

        assert response.json()["detail"]["code"] == "range_invalid"

    @pytest.mark.parametrize("interval,days", _CAPS)
    async def test_a_range_exactly_at_the_cap_is_graphed(
        self, client: AsyncClient, juan: User, provider: _CountingProvider, interval: str, days: int
    ) -> None:
        """RF-42 to RF-44, from the side that graphs: 7 days, 30 days, 90 days."""
        start = datetime(2026, 6, 1, 10, 0)

        response = await client.get(
            _QUOTES,
            params={
                "interval": interval,
                "from": start.isoformat(),
                "to": (start + timedelta(days=days)).isoformat(),
            },
            headers=_bearer(juan),
        )

        assert response.status_code == 200

    @pytest.mark.parametrize("interval,days", [(name, cap + 1) for name, cap in _CAPS])
    async def test_a_range_one_day_past_the_cap_is_422(
        self, client: AsyncClient, juan: User, provider: _CountingProvider, interval: str, days: int
    ) -> None:
        """RF-42 to RF-44 from the side that refuses: 8 days, 31 days, 91 days."""
        start = datetime(2026, 6, 1, 10, 0)

        response = await client.get(
            _QUOTES,
            params={
                "interval": interval,
                "from": start.isoformat(),
                "to": (start + timedelta(days=days)).isoformat(),
            },
            headers=_bearer(juan),
        )

        assert response.status_code == 422

    @pytest.mark.parametrize("interval,cap", _CAPS)
    async def test_a_range_too_long_carries_the_interval_and_its_cap(
        self, client: AsyncClient, juan: User, provider: _CountingProvider, interval: str, cap: int
    ) -> None:
        """RF-45: `{intervalo}` and `{N}` of the text are filled in from the body, never guessed.

        The caps live in the service and nowhere else. A browser carrying its own copy would be
        one business rule written twice, and one of the two would go stale without anybody
        noticing until a user saw a number that was not true.
        """
        start = datetime(2026, 6, 1, 10, 0)

        response = await client.get(
            _QUOTES,
            params={
                "interval": interval,
                "from": start.isoformat(),
                "to": (start + timedelta(days=cap + 1)).isoformat(),
            },
            headers=_bearer(juan),
        )

        detail = response.json()["detail"]
        assert (detail["code"], detail["interval"], detail["max_days"]) == (
            "range_too_long",
            interval,
            cap,
        )

    @pytest.mark.parametrize(
        "params",
        [
            {"interval": "1min", "from": _MARKET_OPEN},
            {"interval": "1min", "to": _MARKET_CLOSE},
        ],
        ids=["only from", "only to"],
    )
    async def test_half_a_range_is_refused(
        self,
        client: AsyncClient,
        juan: User,
        provider: _CountingProvider,
        params: dict[str, str],
    ) -> None:
        """`from` and `to` are both or neither: half a window is not a window (plan.md).

        Read as `Tiempo Real` it would quietly graph today instead of what was asked for, which
        is the kind of answer that looks like a bug in the chart and is a bug in the contract.
        """
        response = await client.get(_QUOTES, params=params, headers=_bearer(juan))

        assert response.status_code == 422


class TestARefusedRangeCostsNothing:
    """RF-47: the four windows the backend refuses are refused before anything is spent."""

    @pytest.mark.parametrize("params", _REFUSED_RANGES, ids=_REFUSED_IDS)
    async def test_it_never_reaches_the_provider(
        self,
        client: AsyncClient,
        juan: User,
        provider: _CountingProvider,
        params: dict[str, str],
    ) -> None:
        """A query the screen would not have sent does not reach the world either (Article II).

        The status code is asserted alongside: the claim is that *the refusal* costs nothing,
        and an endpoint that answered something else entirely would satisfy the counter without
        satisfying the requirement.
        """
        response = await client.get(_QUOTES, params=params, headers=_bearer(juan))

        assert response.status_code == 422
        assert provider.calls == []

    @pytest.mark.parametrize("params", _REFUSED_RANGES, ids=_REFUSED_IDS)
    async def test_it_never_reaches_the_database(
        self,
        client: AsyncClient,
        juan: User,
        provider: _CountingProvider,
        statements: list[str],
        params: dict[str, str],
    ) -> None:
        """The validation is step 1 of the plan: ahead of authorizing and of the window.

        Done later the response is identical, which is why the ordering needs a test of its own:
        it is invisible from the body and it is the whole of RF-47.
        """
        statements.clear()

        response = await client.get(_QUOTES, params=params, headers=_bearer(juan))

        assert response.status_code == 422
        assert not _touched_the_database(statements)

    @pytest.mark.parametrize("params", _REFUSED_RANGES, ids=_REFUSED_IDS)
    async def test_it_stores_nothing(
        self,
        client: AsyncClient,
        juan: User,
        provider: _CountingProvider,
        session: AsyncSession,
        params: dict[str, str],
    ) -> None:
        """A refused window leaves the cache exactly as it was."""
        response = await client.get(_QUOTES, params=params, headers=_bearer(juan))

        assert response.status_code == 422
        stored = (await session.execute(select(Quote))).scalars().all()
        assert stored == []
