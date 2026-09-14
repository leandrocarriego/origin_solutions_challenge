"""The way out to the world is `app/providers/`, and it is the only one (GEN-08).

Two checks, and the second is the one that surprises people.

The first is the obvious half: no file outside `app/providers/` imports an HTTP client. This is
not a rule about TwelveData. A service that imports `httpx` and builds a URL has already left
through the window, and it can do that without ever naming the provider -- which is exactly the
failure mode, because a reviewer grepping for "twelvedata" would not find it.

The second is the name itself: `twelvedata`, its URL and its API key appear in one file. The
day the provider changes, what has to be rewritten is that file, and the test is what says so
before anyone finds out the hard way.

Both are static: they read the source, so they see a violation in a file no test exercises.
"""

from pathlib import Path

import pytest

from tests.architecture.source_tree import (
    APP_ROOT,
    HTTP_CLIENTS,
    SourceFile,
    read_tree,
    write_tree,
)

# Where the outside world is allowed to be named. `settings.py` reads the credential because
# Article I puts every secret there and nowhere else; the client is the file that uses it.
PROVIDER_NAME = "twelvedata"
PROVIDER_HOMES = ("providers/twelvedata.py",)

PROVIDERS_DIRECTORY = "providers"


def http_clients_outside_the_providers(files: list[SourceFile], app_root: Path) -> list[str]:
    """Every import of an HTTP client from a file that has no business making requests."""
    found: list[str] = []

    for source in files:
        if source.relative.parts[1:2] == (PROVIDERS_DIRECTORY,):
            continue

        found.extend(
            f"{source.where(statement.line)}: imports {statement.module}, and the way out to "
            f"the world is app/{PROVIDERS_DIRECTORY}/"
            for statement in source.imports_any(HTTP_CLIENTS)
        )

    return found


def the_provider_named_elsewhere(app_root: Path) -> list[str]:
    """Every mention of the provider's name outside the two files allowed to know it.

    Case-insensitive on purpose: without that, `TwelveDataClient` and `TWELVEDATA_API_KEY` walk
    straight past a check that was supposed to find them.
    """
    found: list[str] = []

    for path in sorted(app_root.rglob("*.py")):
        relative = path.relative_to(app_root)
        if relative.as_posix() in PROVIDER_HOMES:
            continue

        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
            if PROVIDER_NAME in line.lower():
                found.append(
                    f"{path.relative_to(app_root.parent)}:{number}: names the provider, which "
                    f"lives in {' and '.join(PROVIDER_HOMES)}"
                )

    return found


@pytest.fixture(scope="module")
def app_tree() -> list[SourceFile]:
    """Every `.py` file of `app/`, parsed once for the whole file."""
    return read_tree(APP_ROOT)


class TestTheProviderStaysBehindItsInterface:
    """GEN-08, over the code that is on disk."""

    def test_no_file_outside_the_providers_imports_an_http_client(
        self, app_tree: list[SourceFile]
    ) -> None:
        """A service that builds its own request is a provider nobody declared."""
        assert http_clients_outside_the_providers(app_tree, APP_ROOT) == []

    def test_the_provider_is_named_in_one_file_and_in_the_settings(self) -> None:
        """Replacing the provider has to be a rewrite of one file, and the test is the proof."""
        assert the_provider_named_elsewhere(APP_ROOT) == []


class TestTheChecksCatchARealViolation:
    """Both checks, run against a tree written on purpose to break them.

    Today `app/` has no provider and no service, so the assertions above run over almost
    nothing. These are what say the checks work.
    """

    def test_a_service_importing_an_http_client_is_caught(self, tmp_path: Path) -> None:
        """The real failure mode: no mention of the provider anywhere in the file."""
        root = write_tree(
            tmp_path / "app",
            {
                "modules/quotes/__init__.py": '"""Quotes."""\n',
                "modules/quotes/service.py": "import httpx\n\n\ndef fetch() -> None:\n    ...\n",
            },
        )

        found = http_clients_outside_the_providers(read_tree(root), root)

        assert any("modules/quotes/service.py:1" in line for line in found)

    def test_the_providers_own_client_is_not_reported(self, tmp_path: Path) -> None:
        """The rule moves the HTTP call, it does not forbid it."""
        root = write_tree(
            tmp_path / "app",
            {"providers/twelvedata.py": "import httpx\n"},
        )

        found = http_clients_outside_the_providers(read_tree(root), root)

        assert found == []

    def test_a_stdlib_request_is_caught_too(self, tmp_path: Path) -> None:
        """`urllib.request` needs no dependency, which is what makes it easy to reach for."""
        root = write_tree(
            tmp_path / "app",
            {
                "modules/stocks/__init__.py": '"""Stocks."""\n',
                "modules/stocks/repository.py": "from urllib.request import urlopen\n",
            },
        )

        found = http_clients_outside_the_providers(read_tree(root), root)

        assert any("modules/stocks/repository.py:1" in line for line in found)

    def test_the_provider_named_in_a_service_is_caught(self, tmp_path: Path) -> None:
        """A class name is a mention, and casing is not a hiding place."""
        root = write_tree(
            tmp_path / "app",
            {
                "modules/quotes/__init__.py": '"""Quotes."""\n',
                "modules/quotes/service.py": "from app.providers import TwelveDataClient\n",
            },
        )

        found = the_provider_named_elsewhere(root)

        assert any("modules/quotes/service.py:1" in line for line in found)

    def test_the_one_file_allowed_to_name_it_is_not_reported(self, tmp_path: Path) -> None:
        """The client knows the provider; that is what it is for, and it is the only one.

        It used to be two: `settings.py` carried a `twelvedata_api_key` and a default that named
        the provider. It asks for `market_data_api_key` now, and which provider is built has no
        default at all, so the name has one home and this test is what keeps it there.
        """
        root = write_tree(
            tmp_path / "app",
            {
                "providers/twelvedata.py": 'BASE_URL = "https://api.twelvedata.com"\n',
                "settings.py": 'market_data_api_key: str = ""\n',
            },
        )

        found = the_provider_named_elsewhere(root)

        assert found == []
