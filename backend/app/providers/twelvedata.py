"""The TwelveData client: the one file in the application that knows the provider exists."""

from datetime import UTC, datetime
from decimal import Decimal, InvalidOperation
from typing import Any

import httpx

from app.providers.base import MarketDataProvider
from app.providers.errors import (
    ProviderQuotaExceeded,
    ProviderRejectedCredentials,
    ProviderUnavailable,
    SymbolNotFound,
)
from app.providers.schemas import QuotePoint, StockRecord

BASE_URL = "https://api.twelvedata.com"

# Generous enough for the catalogue, short enough that a hung upstream does not hold a
# request open until someone notices.
TIMEOUT = httpx.Timeout(30.0, connect=10.0)

# The provider's own error codes, which it sends both as an HTTP status and inside the body.
_ERRORS = {
    401: ProviderRejectedCredentials,
    403: ProviderRejectedCredentials,
    404: SymbolNotFound,
    429: ProviderQuotaExceeded,
}

# The provider's format for an instant, which is also the format the window travels in.
_DATETIME_FORMATS = ("%Y-%m-%d %H:%M:%S", "%Y-%m-%d")
_WINDOW_FORMAT = "%Y-%m-%d %H:%M:%S"

# The provider's ceiling for one series, and the number the range caps of the plan were chosen
# to fit: seven days at `1min` are about 2.730 candles.
_MAX_OUTPUT_SIZE = 5000


class TwelveDataProvider(MarketDataProvider):
    """Reads TwelveData and answers in the types of the contract."""

    def __init__(self, api_key: str, client: httpx.AsyncClient | None = None) -> None:
        """Take the credential and, optionally, the client to use."""
        self._api_key = api_key
        self._client = client or httpx.AsyncClient(timeout=TIMEOUT)

    async def list_stocks(self, exchange: str) -> list[StockRecord]:
        """Every symbol the provider lists for a market, unfiltered."""
        payload = await self._get("/stocks", {"exchange": exchange})
        rows = payload.get("data")

        if not isinstance(rows, list):
            raise ProviderUnavailable("the catalogue response carried no data")

        return [self._to_record(row) for row in rows]

    async def get_time_series(
        self, symbol: str, interval: str, start: datetime, end: datetime
    ) -> list[QuotePoint]:
        """The candles of a symbol in a window, oldest first."""
        payload = await self._get(
            "/time_series",
            {
                "symbol": symbol,
                "interval": interval,
                "start_date": start.astimezone(UTC).strftime(_WINDOW_FORMAT),
                "end_date": end.astimezone(UTC).strftime(_WINDOW_FORMAT),
                # Both knobs are the same bug seen from two sides, and neither one fails loudly.
                # Without the timezone the provider answers in the exchange's hours while the
                # window we sent is read as exchange hours too, so the series lands four or five
                # hours from where it was asked for and every point still sits on the axis.
                # Without `outputsize` the default is 30 candles, and a `1min` session has 390.
                "timezone": "UTC",
                "outputsize": str(_MAX_OUTPUT_SIZE),
            },
        )
        rows = payload.get("values")

        if not isinstance(rows, list):
            raise ProviderUnavailable("the series response carried no values")

        points = [self._to_point(row) for row in rows]

        # The provider answers newest first.
        return sorted(points, key=lambda point: point.ts)

    async def _get(self, path: str, params: dict[str, str]) -> dict[str, Any]:
        """Make one request and turn every way it can fail into an exception of ours."""
        try:
            response = await self._client.get(
                f"{BASE_URL}{path}", params={**params, "apikey": self._api_key}
            )

        except httpx.HTTPError as error:
            raise ProviderUnavailable(
                f"the provider did not answer: {type(error).__name__}"
            ) from None

        failure = _ERRORS.get(response.status_code)

        if failure is not None:
            raise failure(f"the provider refused the request with {response.status_code}")

        if response.status_code >= 400:
            raise ProviderUnavailable(f"the provider answered {response.status_code}")

        try:
            payload = response.json()

        except ValueError:
            raise ProviderUnavailable("the provider answered something that is not JSON") from None

        if not isinstance(payload, dict):
            raise ProviderUnavailable("the provider answered a shape that is not an object")

        # A 200 can still carry an error envelope, so the code inside the body is checked too.
        code = payload.get("code")

        if isinstance(code, int) and code in _ERRORS:
            raise _ERRORS[code](f"the provider refused the request with {code}")

        return payload

    @staticmethod
    def _to_record(row: Any) -> StockRecord:
        """One catalogue entry, or an exception naming what was missing."""
        if not isinstance(row, dict):
            raise ProviderUnavailable("a catalogue entry was not an object")

        try:
            return StockRecord(
                symbol=str(row["symbol"]),
                name=str(row["name"]),
                currency=str(row["currency"]),
                exchange=str(row["exchange"]),
                mic_code=str(row["mic_code"]),
                country=str(row["country"]),
                instrument_type=str(row["type"]),
            )

        except KeyError as error:
            raise ProviderUnavailable(f"a catalogue entry had no {error.args[0]}") from None

    @classmethod
    def _to_point(cls, row: Any) -> QuotePoint:
        """One candle, with prices as Decimal because money is never a float."""
        if not isinstance(row, dict):
            raise ProviderUnavailable("a series entry was not an object")

        try:
            volume = row.get("volume")
            return QuotePoint(
                ts=cls._to_instant(str(row["datetime"])),
                open=Decimal(str(row["open"])),
                high=Decimal(str(row["high"])),
                low=Decimal(str(row["low"])),
                close=Decimal(str(row["close"])),
                volume=int(volume) if volume not in (None, "") else None,
            )

        except KeyError as error:
            raise ProviderUnavailable(f"a series entry had no {error.args[0]}") from None

        except (InvalidOperation, ValueError):
            raise ProviderUnavailable(
                "a series entry carried a price that is not a number"
            ) from None

    @staticmethod
    def _to_instant(value: str) -> datetime:
        """Parse the provider's timestamp and stamp it UTC."""
        for shape in _DATETIME_FORMATS:
            try:
                # Naive on purpose: the timezone is stamped two lines down.
                parsed = datetime.strptime(value, shape)

            except ValueError:
                continue

            return parsed.replace(tzinfo=UTC)

        raise ProviderUnavailable("a series entry carried a timestamp in an unknown format")


def build(api_key: str, client: httpx.AsyncClient | None = None) -> MarketDataProvider:
    """Build this provider. Every provider module exposes this, and the wiring calls it."""
    return TwelveDataProvider(api_key, client)
