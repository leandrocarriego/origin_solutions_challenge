"""Which provider the application builds, resolved by name instead of by import.

GEN-08 keeps the provider's name in one file, and that is what makes ADR-006's "changing
provider is a new class and a line of wiring" true rather than aspirational. A composition root
that imported the concrete class to wire it would have written the name in a second file, so the
name lives in the settings and this resolves it.

The name comes from the environment, which makes it input: it is validated before it reaches an
import, because a dynamic import of arbitrary input is arbitrary code execution.
"""

import re
from importlib import import_module
from typing import Annotated, Any, Protocol, cast

import httpx
from fastapi import Depends

from app.providers.base import MarketDataProvider
from app.settings import get_settings

# A module name and nothing else: no dots, no dashes, no traversal.
_NAME = re.compile(r"^[a-z][a-z0-9_]*$")


class UnknownProvider(Exception):
    """The configured name is not a provider.

    It is loud on purpose. Falling back to the fake would mean a production deploy quietly
    serving invented prices.
    """


class _ProviderModule(Protocol):
    """What every provider module exposes, and the only thing the wiring needs from it."""

    def build(self, api_key: str, client: httpx.AsyncClient | None = None) -> MarketDataProvider:
        """Build the provider this module implements."""
        ...


def _module(name: str) -> _ProviderModule:
    """Resolve a provider module by name, or say why it is not one."""
    if not _NAME.match(name):
        raise UnknownProvider(f"{name!r} is not a provider name")

    try:
        found: Any = import_module(f"app.providers.{name}")
    except ModuleNotFoundError:
        raise UnknownProvider(f"there is no provider called {name!r}") from None

    if not callable(getattr(found, "build", None)):
        raise UnknownProvider(f"{name!r} is a module but not a provider: it exposes no build()")

    return cast(_ProviderModule, found)


def _not_from_the_request() -> None:
    """Nothing, and that is the point: which provider is built is not a client's decision.

    This is what routes depend on, and a dependency whose parameters are plain values would have
    FastAPI read them off the query string. `?name=fake` would then let whoever asks choose to be
    served invented prices -- and, worse, have them written into the cache as if they were real.
    """
    return None


def get_market_data_provider(
    name: Annotated[str | None, Depends(_not_from_the_request)] = None,
) -> MarketDataProvider:
    """Build the configured provider, or the one named.

    The name is an argument for the wiring and for the tests that exercise it, and never a
    request parameter: see `_not_from_the_request`.
    """
    settings = get_settings()
    chosen = name or settings.market_data_provider

    return _module(chosen).build(settings.market_data_api_key)


def build_upstream_provider(
    api_key: str, client: httpx.AsyncClient | None = None
) -> MarketDataProvider:
    """Build the configured upstream provider with an explicit credential and client.

    This is what the suite uses to exercise the real parsing against fixed JSON: the client is
    wired to a transport that never opens a socket (TEST-03).
    """
    return _module(get_settings().market_data_provider).build(api_key, client)
