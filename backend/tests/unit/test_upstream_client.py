"""The real client, against JSON captured from the provider (TEST-03, ERR-05).

Every response here was captured from the live API on 2026-09-13 and lives in
`tests/fixtures/`. The suite never reaches the network: the quota is 800 requests a day
(Article II) and a suite that spends it is not a suite.

What is under test is the translation. The client receives the provider's JSON and hands back
the types of the contract, so a change of format breaks one file instead of every service test.
And it turns the four ways the upstream says no into exceptions of ours, because `ADR-005` has
to tell "the market is closed" from "we ran out of quota", and a raw 429 reaching the browser
would blame a client that has no account with the provider.
"""

import json
from datetime import UTC, datetime
from decimal import Decimal
from pathlib import Path
from typing import Any

import httpx
import pytest

from app.providers import (
    ProviderQuotaExceeded,
    ProviderRejectedCredentials,
    ProviderUnavailable,
    QuotePoint,
    StockRecord,
    SymbolNotFound,
    build_upstream_provider,
)

FIXTURES = Path(__file__).resolve().parents[1] / "fixtures" / "twelvedata"

API_KEY = "sentinel-api-key-do-not-log"

WINDOW = (datetime(2026, 9, 11, tzinfo=UTC), datetime(2026, 9, 12, tzinfo=UTC))


def fixture(name: str) -> dict[str, Any]:
    """One captured response, read from disk exactly as the provider sent it."""
    loaded: dict[str, Any] = json.loads((FIXTURES / f"{name}.json").read_text(encoding="utf-8"))

    return loaded


def answering(payload: dict[str, Any], status: int = 200) -> httpx.AsyncClient:
    """A client wired to a transport that replies with `payload` and never opens a socket."""

    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(status, json=payload, request=request)

    return httpx.AsyncClient(transport=httpx.MockTransport(handler))


def recording(payload: dict[str, Any]) -> tuple[httpx.AsyncClient, list[httpx.Request]]:
    """The same, keeping every request so a test can assert what was asked for."""
    seen: list[httpx.Request] = []

    def handler(request: httpx.Request) -> httpx.Response:
        seen.append(request)
        return httpx.Response(200, json=payload, request=request)

    return httpx.AsyncClient(transport=httpx.MockTransport(handler)), seen


class TestItReadsTheCatalogue:
    """`list_stocks` is what the reconciliation of ADR-002 compares against the table."""

    async def test_it_returns_the_contract_type(self) -> None:
        """The service sees StockRecord, never the provider's dict."""
        provider = build_upstream_provider(API_KEY, client=answering(fixture("stocks_nasdaq")))

        catalogue = await provider.list_stocks("NASDAQ")

        assert all(isinstance(entry, StockRecord) for entry in catalogue)

    async def test_it_returns_every_row_the_provider_sent(self) -> None:
        """Filtering is the ingestion's job (ADR-001); the client does not decide what counts."""
        provider = build_upstream_provider(API_KEY, client=answering(fixture("stocks_nasdaq")))

        catalogue = await provider.list_stocks("NASDAQ")

        assert len(catalogue) == 4

    async def test_it_carries_over_what_the_catalogue_table_stores(self) -> None:
        """symbol, name, currency and the rest of ADR-001's columns arrive filled in."""
        provider = build_upstream_provider(API_KEY, client=answering(fixture("stocks_nasdaq")))

        catalogue = await provider.list_stocks("NASDAQ")
        apple = next(entry for entry in catalogue if entry.symbol == "AAPL")

        assert apple.name == "Apple Inc."
        assert apple.currency == "USD"
        assert apple.mic_code == "XNGS"
        assert apple.instrument_type == "Common Stock"

    async def test_it_asks_for_the_exchange_it_was_given(self) -> None:
        """The reconciliation is per exchange, so the request has to be too."""
        client, seen = recording(fixture("stocks_nasdaq"))
        provider = build_upstream_provider(API_KEY, client=client)

        await provider.list_stocks("NYSE")

        assert seen[0].url.params["exchange"] == "NYSE"


class TestItReadsASeries:
    """`get_time_series` is what fills the cache the chart is served from."""

    async def test_it_returns_the_contract_type(self) -> None:
        """QuotePoint, not a dict of strings: parsing does not belong in a service."""
        provider = build_upstream_provider(
            API_KEY, client=answering(fixture("time_series_tsla_1min"))
        )

        series = await provider.get_time_series("TSLA", "1min", *WINDOW)

        assert all(isinstance(point, QuotePoint) for point in series)

    async def test_the_prices_are_decimals(self) -> None:
        """The provider sends strings, and money parsed as a float is money that drifts."""
        provider = build_upstream_provider(
            API_KEY, client=answering(fixture("time_series_tsla_1min"))
        )

        series = await provider.get_time_series("TSLA", "1min", *WINDOW)

        # The last one, because the series comes back oldest first: 365.47000 is the 15:59
        # candle, which is the newest in the fixture and the first one the provider sent.
        assert series[-1].close == Decimal("365.47000")

    async def test_it_returns_the_series_oldest_first(self) -> None:
        """The provider answers newest first. A chart drawn in that order runs backwards."""
        provider = build_upstream_provider(
            API_KEY, client=answering(fixture("time_series_tsla_1min"))
        )

        series = await provider.get_time_series("TSLA", "1min", *WINDOW)

        assert [point.ts for point in series] == sorted(point.ts for point in series)

    async def test_every_instant_knows_its_timezone(self) -> None:
        """A naive datetime in a cache keyed by instant is a duplicate waiting to happen."""
        provider = build_upstream_provider(
            API_KEY, client=answering(fixture("time_series_tsla_1min"))
        )

        series = await provider.get_time_series("TSLA", "1min", *WINDOW)

        assert all(point.ts.tzinfo is not None for point in series)

    async def test_it_asks_for_the_symbol_and_the_interval_it_was_given(self) -> None:
        """Article II is only checkable if the request matches what was asked for."""
        client, seen = recording(fixture("time_series_tsla_1min"))
        provider = build_upstream_provider(API_KEY, client=client)

        await provider.get_time_series("NFLX", "5min", *WINDOW)

        assert seen[0].url.params["symbol"] == "NFLX"
        assert seen[0].url.params["interval"] == "5min"


class TestItTranslatesEveryWayTheUpstreamSaysNo:
    """ERR-05: the failure modes are what arrive first in production."""

    async def test_the_quota_running_out_is_its_own_exception(self) -> None:
        """ADR-005 serves the cache with a notice for this one; it must be distinguishable."""
        provider = build_upstream_provider(
            API_KEY, client=answering(fixture("error_429_rate_limit"), status=429)
        )

        with pytest.raises(ProviderQuotaExceeded):
            await provider.get_time_series("TSLA", "1min", *WINDOW)

    async def test_an_unknown_symbol_is_its_own_exception(self) -> None:
        """Not the same as the upstream being down: one is about the request, the other is not."""
        provider = build_upstream_provider(
            API_KEY, client=answering(fixture("error_404_unknown_symbol"), status=404)
        )

        with pytest.raises(SymbolNotFound):
            await provider.get_time_series("NOPE", "1min", *WINDOW)

    async def test_a_rejected_key_is_its_own_exception(self) -> None:
        """This one is ours to fix, and it must not read as the provider being unavailable."""
        provider = build_upstream_provider(
            API_KEY, client=answering(fixture("error_401_invalid_key"), status=401)
        )

        with pytest.raises(ProviderRejectedCredentials):
            await provider.list_stocks("NASDAQ")

    async def test_a_server_error_is_the_upstream_being_unavailable(self) -> None:
        """A 500 from them is not a bug of ours, and the cache answers with a notice."""
        provider = build_upstream_provider(API_KEY, client=answering({}, status=503))

        with pytest.raises(ProviderUnavailable):
            await provider.list_stocks("NASDAQ")

    async def test_a_network_failure_is_the_upstream_being_unavailable(self) -> None:
        """A timeout reaches the service as the same thing a 503 does: no answer."""

        def refuse(request: httpx.Request) -> httpx.Response:
            raise httpx.ConnectTimeout("timed out", request=request)

        client = httpx.AsyncClient(transport=httpx.MockTransport(refuse))
        provider = build_upstream_provider(API_KEY, client=client)

        with pytest.raises(ProviderUnavailable):
            await provider.list_stocks("NASDAQ")

    async def test_a_body_that_is_not_what_was_promised_is_not_a_crash(self) -> None:
        """A 200 with the wrong shape is a failure mode too, and it has to be one of ours."""
        provider = build_upstream_provider(API_KEY, client=answering({"unexpected": "shape"}))

        with pytest.raises(ProviderUnavailable):
            await provider.get_time_series("TSLA", "1min", *WINDOW)


class TestTheKeyNeverLeaves:
    """Article I, at the one place that holds the credential."""

    @pytest.mark.parametrize("status", [401, 429, 503])
    async def test_the_api_key_is_not_in_the_exception(self, status: int) -> None:
        """An exception text ends up in a log, in Sentry, and sometimes on a screen."""
        provider = build_upstream_provider(
            API_KEY, client=answering({"message": f"failed with key {API_KEY}"}, status=status)
        )

        # Any of the four, on purpose: what is under test is that none of them carries it.
        with pytest.raises(Exception) as raised:
            await provider.list_stocks("NASDAQ")

        assert API_KEY not in str(raised.value)


class TestTheSeriesAndItsTimezone:
    """The most expensive bug of `003-quote-chart`, and the most silent one (RF-15, RF-36).

    The provider sends its timestamps in the exchange's timezone unless it is asked otherwise,
    and this client used to stamp UTC on them. Nothing fails when that happens: the whole chart
    simply sits four or five hours away from where it belongs, depending on the time of year,
    and every point still lands neatly on an axis.

    The fix is to ask for the series in UTC, which also settles the other half: the window we
    send is then read in the same timezone we are answered in. And `outputsize` explicitly at
    the top of the plan, because the default is 30 candles and a `1min` session has 390 -- a
    chart cropped to 8% of itself, with no error anywhere.
    """

    async def test_it_asks_for_the_series_in_utc(self) -> None:
        """Asserted on the value and not on the name of the parameter.

        `plan.md` fixes the behaviour -- the series is requested in UTC -- and not the spelling
        the provider gives that knob. What must be true is that the request says UTC somewhere;
        which key carries it is the client's business.
        """
        client, seen = recording(fixture("time_series_tsla_1min"))
        provider = build_upstream_provider(API_KEY, client=client)

        await provider.get_time_series("TSLA", "1min", *WINDOW)

        assert "UTC" in set(seen[0].url.params.values())

    async def test_it_asks_for_the_whole_session_and_not_the_first_thirty_candles(self) -> None:
        """5.000 is the cap of the plan, and the caps of MAX_RANGE_DAYS were chosen to fit it."""
        client, seen = recording(fixture("time_series_tsla_1min"))
        provider = build_upstream_provider(API_KEY, client=client)

        await provider.get_time_series("TSLA", "1min", *WINDOW)

        assert seen[0].url.params["outputsize"] == "5000"

    async def test_the_window_it_sends_is_written_in_the_timezone_it_is_answered_in(self) -> None:
        """The service hands over an aware window in UTC, and that is what has to travel.

        A `start_date` read by the provider in exchange time while the answer comes back in UTC
        is the same corruption seen from the other end: the window asked for and the window
        received would be different windows.
        """
        client, seen = recording(fixture("time_series_tsla_1min"))
        provider = build_upstream_provider(API_KEY, client=client)

        await provider.get_time_series("TSLA", "1min", *WINDOW)

        assert seen[0].url.params["start_date"] == "2026-09-11 00:00:00"
        assert seen[0].url.params["end_date"] == "2026-09-12 00:00:00"

    @pytest.mark.xfail(
        strict=True,
        reason=(
            "Waiting for task 1 of 003-quote-chart: the fixed JSON has to be captured again with "
            "the series requested in UTC. The one in the repository is the old capture, in "
            "exchange time (America/New_York), and TEST-03 forbids editing a fixture by hand: a "
            "retouched fixture describes a provider that does not exist. The expected instants "
            "below are the candles of that same session written in UTC, which is what the new "
            "capture has to carry; when it lands they are re-derived from it and this marker "
            "goes away."
        ),
    )
    async def test_the_first_and_the_last_candle_are_the_instants_they_claim(self) -> None:
        """The exact instant, not that there are candles: that is what a shift of hours hides.

        The fixed session runs from 15:55 to 15:59 in New York on 2026-09-11, which is 19:55 to
        19:59 UTC. A client that parses the provider's string and stamps UTC on it answers 15:55
        and 15:59 -- four hours early, with a chart that looks perfectly fine.
        """
        provider = build_upstream_provider(
            API_KEY, client=answering(fixture("time_series_tsla_1min"))
        )

        series = await provider.get_time_series("TSLA", "1min", *WINDOW)

        assert series[0].ts == datetime(2026, 9, 11, 19, 55, tzinfo=UTC)
        assert series[-1].ts == datetime(2026, 9, 11, 19, 59, tzinfo=UTC)
