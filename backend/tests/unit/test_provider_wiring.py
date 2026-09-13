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
