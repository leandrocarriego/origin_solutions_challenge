"""The deliverables the brief asks for exist, and still say what they claimed.

`REQ-21` to `REQ-24` are the only requirements that are not about behaviour: a backup in the
repository, a README with the steps to bring the application up, two projects rather than one,
and an API built on FastAPI. They were the four empty cells of the traceability table, and an
empty cell is a requirement whose fulfilment somebody has to remember -- which is exactly what
the table exists to stop.

None of them needs a database or a network. What each one checks is the artefact as it is
committed, so a backup that stopped carrying rows, a README whose start command was renamed, or
a frontend quietly folded into the backend fails here instead of during the evaluation.

`REQ-20` -- the repository is public and under version control -- has no test on purpose: it is a
property of the hosting, not of the tree, and a test that asserted it from inside would be
asserting its own existence.
"""

from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[3]


class TestTheDatabaseBackupIsShipped:
    """REQ-21: a backup of the database, included in the repository."""

    @pytest.fixture(scope="class")
    @classmethod
    def backup(cls) -> str:
        """The dump as it is committed, read once for the whole class."""
        dump = REPO_ROOT / "db" / "backup.sql"

        assert dump.is_file(), "falta db/backup.sql -- se genera con `make backup`"

        return dump.read_text(encoding="utf-8", errors="replace")

    def test_it_creates_the_four_tables(self, backup: str) -> None:
        """A dump of the schema alone would restore an application with nothing in it."""
        for table in ("users", "stocks", "user_stocks", "quotes"):
            assert f"CREATE TABLE public.{table}" in backup

    def test_it_carries_the_demo_accounts(self, backup: str) -> None:
        """REQ-19 again, from the other side: the backup restores a usable application."""
        assert "juan@demo.com" in backup
        assert "ana@demo.com" in backup

    def test_it_carries_no_password_in_the_clear(self, backup: str) -> None:
        """The demo passwords are public, the hashes are what the dump may hold."""
        assert "Demo1234*" not in backup
        assert "$argon2" in backup

    def test_it_carries_the_catalogue_the_autocomplete_searches(self, backup: str) -> None:
        """A backup with the three favourites and nothing else is a backup of an empty search."""
        assert backup.count("Common Stock") > 1000


class TestTheReadmeSaysHowToRunIt:
    """REQ-22: a README with the steps to bring the application up."""

    @pytest.fixture(scope="class")
    @classmethod
    def readme(cls) -> str:
        """The README as it is committed."""
        return (REPO_ROOT / "README.md").read_text(encoding="utf-8")

    def test_it_hands_out_the_command_that_exists(self, readme: str) -> None:
        """The command it teaches has to be a target of the Makefile that ships with it."""
        makefile = (REPO_ROOT / "Makefile").read_text(encoding="utf-8")

        assert "make setup" in readme
        assert "\nsetup:" in makefile

    def test_it_hands_out_the_credentials_the_seed_creates(self, readme: str) -> None:
        """Steps that end at a login screen nobody can pass are not steps."""
        assert "juan@demo.com" in readme
        assert "Demo1234*" in readme


class TestTheArchitectureIsTwoProjects:
    """REQ-23 and REQ-24: a frontend, an API, and the API is FastAPI."""

    def test_the_two_projects_have_their_own_dependencies(self) -> None:
        """Two projects, not one repository with two folders in it."""
        assert (REPO_ROOT / "backend" / "pyproject.toml").is_file()
        assert (REPO_ROOT / "frontend" / "package.json").is_file()

    def test_the_api_is_fastapi(self) -> None:
        """Named in the dependencies, so a rewrite onto something else fails here."""
        pyproject = (REPO_ROOT / "backend" / "pyproject.toml").read_text(encoding="utf-8")

        assert "fastapi" in pyproject

    def test_the_frontend_is_react_18_or_newer(self) -> None:
        """The brief allows React >= 18 or Angular >= 18, and this is the React half."""
        package = (REPO_ROOT / "frontend" / "package.json").read_text(encoding="utf-8")
        major = package.split('"react": "^', 1)[1].split(".", 1)[0]

        assert int(major) >= 18
