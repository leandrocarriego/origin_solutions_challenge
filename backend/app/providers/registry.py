"""Which provider the application builds, resolved by name instead of by import."""

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

    Deliberately not a `ProviderError`: this is a misconfiguration and not a provider that
    failed. The separate root is what keeps it loud.
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

    return _module(chosen).build(settings.market_data_api_key.get_secret_value())


def build_upstream_provider(
    api_key: str, client: httpx.AsyncClient | None = None
) -> MarketDataProvider:
    """Build the configured upstream provider with an explicit credential and client."""
    return _module(get_settings().market_data_provider).build(api_key, client)
