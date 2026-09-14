"""Which provider the application builds, and why that is a setting and not an import.

GEN-08 says the provider's name appears in one file. That is not a style rule -- it is what makes
"changing provider is a new class and a line of wiring" (ADR-006) true rather than aspirational.
But a composition root that imports `TwelveDataProvider` to wire it has just written the name in
a second file.

So the name is a setting, and the wiring resolves it. The upstream provider is selected by
configuration, the fake runs the suite, and nothing outside `app/providers/<name>.py` and
`app/settings.py` ever spells the provider out.
"""

import pytest

from app.providers import (
    FakeProvider,
    MarketDataProvider,
    ProviderError,
    UnknownProvider,
    get_market_data_provider,
)


class TestTheProviderIsChosenByConfiguration:
    """The wiring reads a name and resolves it; it does not know any provider by import."""

    def test_it_builds_the_provider_the_settings_name(self) -> None:
        """The fake is a provider like any other, selected the same way the real one is."""
        provider = get_market_data_provider("fake")

        assert isinstance(provider, FakeProvider)

    def test_whatever_it_builds_honours_the_contract(self) -> None:
        """The wiring may not hand back something that is not a provider."""
        assert isinstance(get_market_data_provider("fake"), MarketDataProvider)

    def test_a_name_that_is_not_a_provider_fails_loudly(self) -> None:
        """Silently falling back to the fake in production would hide the misconfiguration."""
        with pytest.raises(UnknownProvider):
            get_market_data_provider("does-not-exist")

    def test_a_module_that_is_not_a_provider_fails_loudly(self) -> None:
        """`base` is importable and is not a provider: resolving it must not half-work."""
        with pytest.raises(UnknownProvider):
            get_market_data_provider("base")

    def test_the_name_cannot_reach_outside_the_providers_package(self) -> None:
        """It comes from configuration, so it is input: importing `os.system` is not an option."""
        with pytest.raises(UnknownProvider):
            get_market_data_provider("..settings")


class TestAMisconfigurationIsNotAProviderFailure:
    """`UnknownProvider` stays outside the `ProviderError` family, and that is load-bearing.

    Both services answer from the cache when the provider fails, so under that root a deploy
    that named a provider which does not exist would serve stale quotes with a notice on top
    instead of refusing to work. Tidying the package into one exception hierarchy is the kind of
    change that looks like housekeeping and is not.
    """

    def test_it_is_not_caught_by_a_service_handling_provider_failures(self) -> None:
        """`except ProviderError` must not swallow a name nobody configured."""
        assert not issubclass(UnknownProvider, ProviderError)

    def test_the_failures_that_are_the_providers_stay_inside_the_family(self) -> None:
        """The rule is about misconfiguration, not about narrowing what a service catches."""
        with pytest.raises(UnknownProvider):
            get_market_data_provider("does-not-exist")
