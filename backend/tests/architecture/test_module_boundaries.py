"""The frontier between modules, and the direction of the flow inside one.

Four rules live here because they are one idea seen from four sides:

  - a module is entered by its package, and never below it
  - nothing underneath the modules imports a module -- except the composition root
  - no two modules import each other
  - inside a module the flow goes router -> service -> repository, one way

Each rule is a function that takes a tree and returns what it found, and each one is asserted
twice: against `app/`, and against a tree written on purpose to break it. The second assertion
is the one that has teeth today, because phase 0 has not created a single module yet -- so the
first one passes over an empty set and would keep passing if the check were broken.

The checks are static: they read imports with `ast` and never import the code, so they see a
violation in a file no test exercises.
"""

import ast
from pathlib import Path

import pytest

from tests.architecture.source_tree import (
    APP_ROOT,
    COMPOSITION_ROOTS,
    SourceFile,
    layer_of,
    module_names,
    owning_module,
    package_of,
    read_tree,
    root_package,
    write_tree,
)

# What a layer is not allowed to import from its own module. The pairs that are missing are the
# permitted ones: router -> service and service -> repository.
FORBIDDEN_SIBLINGS = {
    "router": ("repository",),
    "service": ("router",),
    "repository": ("router", "service"),
}

# A router that imports SQLAlchemy is querying where the decisions should be; a service that
# imports FastAPI has tied a business rule to the transport that happens to carry it today.
FORBIDDEN_LIBRARIES = {
    "router": ("sqlalchemy",),
    "service": ("fastapi",),
}


# --- the rules ---------------------------------------------------------------------------------


def reaching_into_another_module(files: list[SourceFile], app_root: Path) -> list[str]:
    """The outside clause: imports that enter another module below its package."""
    modules = module_names(app_root)
    found: list[str] = []

    for source in files:
        own = owning_module(source, app_root)
        for statement in source.imports:
            for module in modules:
                package = package_of(app_root, module)
                if module == own or statement.module == package:
                    continue
                if statement.reaches(package):
                    found.append(
                        f"{source.where(statement.line)}: {statement.module} is the inside of "
                        f"{module}, which for everyone else does not exist"
                    )

    return found


def reentering_its_own_package(files: list[SourceFile], app_root: Path) -> list[str]:
    """The inside clause: a file of a module importing its own package.

    This is the clause that prevents a bug rather than a coupling: it reenters an `__init__`
    that is still half initialised, and the `ImportError` it produces names neither the file
    nor the cycle.
    """
    found: list[str] = []

    for source in files:
        own = owning_module(source, app_root)
        if own is None or source.path.name == "__init__.py":
            continue

        package = package_of(app_root, own)
        found.extend(
            f"{source.where(statement.line)}: reenters its own package; import the sibling by "
            f"its full path instead"
            for statement in source.imports
            if statement.module == package
        )

    return found


def _is_docstring(node: ast.stmt) -> bool:
    """Whether the statement is a bare string expression, which is what a docstring is."""
    return isinstance(node, ast.Expr) and isinstance(node.value, ast.Constant)


def _is_literal_all(node: ast.stmt) -> bool:
    """Whether the statement is `__all__ = [...]` with nothing but string literals inside."""
    if not isinstance(node, ast.Assign) or len(node.targets) != 1:
        return False

    target = node.targets[0]
    if not isinstance(target, ast.Name) or target.id != "__all__":
        return False

    return isinstance(node.value, ast.List) and all(
        isinstance(element, ast.Constant) and isinstance(element.value, str)
        for element in node.value.elts
    )


def contract_of_the_package(files: list[SourceFile], app_root: Path) -> list[str]:
    """A module's `__init__.py` is docstring, imports and a literal `__all__`.

    Nothing else -- not an `if`, not a computed constant, not a registry. The contract has to
    be readable at a glance by whoever is about to depend on it, and anything that runs there
    also runs on every import of the module.
    """
    found: list[str] = []

    for source in files:
        if source.path.name != "__init__.py" or owning_module(source, app_root) is None:
            continue

        declares_all = False
        for index, node in enumerate(source.tree.body):
            if index == 0 and _is_docstring(node):
                continue
            if isinstance(node, ast.Import | ast.ImportFrom):
                continue
            if _is_literal_all(node):
                declares_all = True
                continue
            found.append(
                f"{source.where(node.lineno)}: a module's __init__ holds a docstring, imports "
                f"and a literal __all__, and nothing else"
            )

        if not declares_all:
            found.append(
                f"{source.relative}:1: declares no literal __all__, so the module promises "
                f"nothing and everything in it is public by accident"
            )

    return found


def orm_models_in_the_contract(files: list[SourceFile], app_root: Path) -> list[str]:
    """Nothing a module exports may be a SQLAlchemy model.

    A contract that hands back an ORM entity has isolated nothing: the caller gets lazy loads,
    a live session and the table layout, and the frontier becomes decorative.
    """
    found: list[str] = []

    for source in files:
        module = owning_module(source, app_root)
        if source.path.name != "__init__.py" or module is None:
            continue

        models = f"{package_of(app_root, module)}.models"
        for statement in source.imports:
            if statement.reaches(models) or statement.reaches("sqlalchemy"):
                found.append(
                    f"{source.where(statement.line)}: the contract of {module} would hand back "
                    f"the ORM; export a type of its own instead"
                )

    return found


def modules_imported_from_below(files: list[SourceFile], app_root: Path) -> list[str]:
    """The kernel and the providers import no module.

    An import of `modules/` down here ties every module together underneath, and in
    `providers/` it inverts the dependency outright: infrastructure would depend on the domain.

    The composition root is excluded by name, and that is the whole exception: it mounts every
    router and names what runs in the background, so it imports from all of them by definition.
    It is two files -- `main.py` and `tasks.py` -- and the list is pinned by a test of its own.
    """
    root = root_package(app_root)
    found: list[str] = []

    for source in files:
        if owning_module(source, app_root) is not None or source.package.endswith(".modules"):
            continue
        if source.package == root and source.path.name in COMPOSITION_ROOTS:
            continue

        found.extend(
            f"{source.where(statement.line)}: {source.relative} is below the modules and "
            f"imports {statement.module}"
            for statement in source.imports
            if statement.reaches(f"{root}.modules")
        )

    return found


def layers_crossed(files: list[SourceFile], app_root: Path) -> list[str]:
    """Inside a module the flow goes router -> service -> repository, one way."""
    found: list[str] = []

    for source in files:
        module = owning_module(source, app_root)
        layer = layer_of(source, app_root)
        if module is None or layer is None:
            continue

        package = package_of(app_root, module)
        for sibling in FORBIDDEN_SIBLINGS.get(layer, ()):
            found.extend(
                f"{source.where(statement.line)}: a {layer} does not reach the {sibling}"
                for statement in source.imports
                if statement.reaches(f"{package}.{sibling}")
            )

        for library in FORBIDDEN_LIBRARIES.get(layer, ()):
            found.extend(
                f"{source.where(statement.line)}: a {layer} does not import {library}"
                for statement in source.imports
                if statement.reaches(library)
            )

    return found


def _canonical(ring: list[str]) -> tuple[str, ...]:
    """One spelling per cycle, whichever module the walk happened to start from.

    `a -> b -> c` and `b -> c -> a` are the same cycle; rotating to start at the smallest name
    is what stops it being reported three times.
    """
    start = ring.index(min(ring))
    return tuple(ring[start:] + ring[:start])


def cycles(files: list[SourceFile], app_root: Path) -> list[str]:
    """No module reaches another that, directly or not, reaches back.

    Two modules that call each other are one module with two names: they cannot be tested
    apart, deployed apart, or extracted apart. The same is true of three, which is why this
    follows each chain to its end instead of only comparing pairs -- `a -> b -> c -> a` is one
    module wearing three names, and a check that only looks at pairs never sees it.
    """
    modules = module_names(app_root)
    graph: dict[str, set[str]] = {module: set() for module in modules}

    for source in files:
        own = owning_module(source, app_root)
        if own is None:
            continue
        for statement in source.imports:
            for other in modules:
                if other != own and statement.reaches(package_of(app_root, other)):
                    graph[own].add(other)

    found: list[str] = []
    seen: set[tuple[str, ...]] = set()

    def walk(module: str, chain: list[str]) -> None:
        """Follow one chain of imports to its end, reporting the moment it turns back on itself."""
        for other in sorted(graph[module]):
            if other not in chain:
                walk(other, [*chain, other])
                continue

            ring = list(_canonical(chain[chain.index(other) :]))
            if tuple(ring) in seen:
                continue
            seen.add(tuple(ring))
            found.append(f"{' -> '.join([*ring, ring[0]])} is a cycle, so those are one module")

    for module in modules:
        walk(module, [module])

    return found


def _referenced_names(node: ast.AST) -> set[str]:
    """Every class name an annotation or a call argument mentions, as written."""
    names: set[str] = set()

    for child in ast.walk(node):
        if isinstance(child, ast.Constant) and isinstance(child.value, str):
            names.add(child.value.split(".")[-1])
        elif isinstance(child, ast.Name):
            names.add(child.id)

    return names


def relationships_that_cross(files: list[SourceFile], app_root: Path) -> list[str]:
    """The back door the import check cannot see.

    `favorite.stock.name` produces no import and still couples `favorites` to the model of
    `stocks`. A `ForeignKey` between tables of different modules is legitimate --it is a
    guarantee of the engine, and modules separate code, not schema-- but a `relationship()`
    that crosses is not.
    """
    classes: dict[str, set[str]] = {}
    for source in files:
        module = owning_module(source, app_root)
        if module is None:
            continue
        for node in ast.walk(source.tree):
            if isinstance(node, ast.ClassDef):
                classes.setdefault(module, set()).add(node.name)

    found: list[str] = []
    for source in files:
        module = owning_module(source, app_root)
        if module is None:
            continue

        for node in ast.walk(source.tree):
            if not isinstance(node, ast.AnnAssign | ast.Assign):
                continue
            call = node.value
            if not isinstance(call, ast.Call):
                continue
            function = call.func
            name = (
                function.attr
                if isinstance(function, ast.Attribute)
                else getattr(function, "id", "")
            )
            if name != "relationship":
                continue

            mentioned = _referenced_names(call)
            if isinstance(node, ast.AnnAssign) and node.annotation is not None:
                mentioned |= _referenced_names(node.annotation)

            targets = mentioned & set().union(*classes.values()) if classes else set()
            outside = targets - classes.get(module, set())
            if outside:
                found.append(
                    f"{source.where(node.lineno)}: relationship() reaches "
                    f"{', '.join(sorted(outside))}, which belongs to another module; a "
                    f"ForeignKey is fine, this is not"
                )

    return found


# --- the real tree -----------------------------------------------------------------------------


@pytest.fixture(scope="module")
def app_tree() -> list[SourceFile]:
    """Every `.py` file of `app/`, parsed once for the whole file."""
    return read_tree(APP_ROOT)


class TestTheFrontierBetweenModules:
    """The package frontier and the absence of cycles, over the code that is on disk."""

    def test_nothing_reaches_into_another_module(self, app_tree: list[SourceFile]) -> None:
        """A module is entered by its package; anything deeper does not exist for the rest."""
        assert reaching_into_another_module(app_tree, APP_ROOT) == []

    def test_no_file_reenters_its_own_package(self, app_tree: list[SourceFile]) -> None:
        """Siblings import each other by full path, never through the module's `__init__`."""
        assert reentering_its_own_package(app_tree, APP_ROOT) == []

    def test_every_contract_is_docstring_imports_and_a_literal_all(
        self, app_tree: list[SourceFile]
    ) -> None:
        """The `__init__` of a module is readable at a glance, because it is the contract."""
        assert contract_of_the_package(app_tree, APP_ROOT) == []

    def test_no_contract_hands_back_the_orm(self, app_tree: list[SourceFile]) -> None:
        """A module that exports a SQLAlchemy model has isolated nothing."""
        assert orm_models_in_the_contract(app_tree, APP_ROOT) == []

    def test_no_two_modules_import_each_other(self, app_tree: list[SourceFile]) -> None:
        """A cycle between modules means there is one module wearing two names."""
        assert cycles(app_tree, APP_ROOT) == []

    def test_no_relationship_crosses_a_module(self, app_tree: list[SourceFile]) -> None:
        """The coupling that leaves no import behind is still coupling."""
        assert relationships_that_cross(app_tree, APP_ROOT) == []


class TestWhatIsBelowTheModules:
    """Nothing underneath the modules imports a module, over the code that is on disk."""

    def test_the_kernel_and_the_providers_import_no_module(
        self, app_tree: list[SourceFile]
    ) -> None:
        """Everything under the modules stays ignorant of them, bar the composition root."""
        assert modules_imported_from_below(app_tree, APP_ROOT) == []


class TestTheExceptionIsDeclared:
    """The list of files allowed to reach a module from below is pinned, not merely documented.

    Every name in it is a file that may depend on the domain, and the rule survives exactly as
    long as the list stays short. Pinning it does not stop anybody from adding a third -- nothing
    could -- but it makes adding one a line somebody edits on purpose, in a test, with the reason
    in the commit, instead of a name that appears and is never noticed again.
    """

    def test_the_composition_root_is_two_files(self) -> None:
        """`main.py` mounts the routers; `tasks.py` names what runs in the background."""
        assert COMPOSITION_ROOTS == ("main.py", "tasks.py")


class TestTheLayersInsideAModule:
    """The one-way flow inside a module, over the code that is on disk."""

    def test_the_flow_goes_one_way(self, app_tree: list[SourceFile]) -> None:
        """A router does not reach the repository, and a service does not import FastAPI."""
        assert layers_crossed(app_tree, APP_ROOT) == []


# --- the checks, against trees built to break them ----------------------------------------------


class TestTheChecksCatchARealViolation:
    """Each rule, run against a tree written on purpose to break it.

    These are the tests that carry weight today. Phase 0 has created no module yet, so every
    assertion above runs over an empty set and would stay green if the check were broken --
    which is the failure mode an architecture test is most likely to have and least likely to
    show.
    """

    def test_an_import_into_another_modules_internals_is_caught(self, tmp_path: Path) -> None:
        """`favorites` reaching for the repository of `stocks`."""
        root = write_tree(
            tmp_path / "app",
            {
                "modules/stocks/__init__.py": '"""Stocks."""\n',
                "modules/stocks/repository.py": "class StockRepository:\n    pass\n",
                "modules/favorites/__init__.py": '"""Favorites."""\n',
                "modules/favorites/service.py": (
                    "from app.modules.stocks.repository import StockRepository\n"
                ),
            },
        )

        found = reaching_into_another_module(read_tree(root), root)

        assert any("modules/favorites/service.py:1" in line for line in found)

    def test_an_import_of_its_own_package_is_caught(self, tmp_path: Path) -> None:
        """The half-initialised `__init__` reentry, which fails with a confusing `ImportError`."""
        root = write_tree(
            tmp_path / "app",
            {
                "modules/stocks/__init__.py": '"""Stocks."""\n',
                "modules/stocks/router.py": "from app.modules.stocks import get_stocks\n",
            },
        )

        found = reentering_its_own_package(read_tree(root), root)

        assert any("modules/stocks/router.py:1" in line for line in found)

    def test_logic_in_a_contract_is_caught(self, tmp_path: Path) -> None:
        """An `if` in an `__init__` is code that runs on every import of the module."""
        root = write_tree(
            tmp_path / "app",
            {
                "modules/stocks/__init__.py": (
                    '"""Stocks."""\n\nimport os\n\nif os.environ.get("X"):\n    pass\n\n'
                    '__all__ = ["get_stocks"]\n'
                ),
            },
        )

        found = contract_of_the_package(read_tree(root), root)

        assert any("modules/stocks/__init__.py:5" in line for line in found)

    def test_a_contract_without_a_literal_all_is_caught(self, tmp_path: Path) -> None:
        """No `__all__` means the module promises nothing and exports everything by accident."""
        root = write_tree(
            tmp_path / "app",
            {"modules/stocks/__init__.py": '"""Stocks."""\n\nfrom app.db import get_session\n'},
        )

        found = contract_of_the_package(read_tree(root), root)

        assert any("declares no literal __all__" in line for line in found)

    def test_an_exported_orm_model_is_caught(self, tmp_path: Path) -> None:
        """Exporting the ORM entity hands the caller the table layout and a live session."""
        root = write_tree(
            tmp_path / "app",
            {
                "modules/stocks/__init__.py": (
                    '"""Stocks."""\n\nfrom app.modules.stocks.models import Stock\n\n'
                    '__all__ = ["Stock"]\n'
                ),
                "modules/stocks/models.py": "class Stock:\n    pass\n",
            },
        )

        found = orm_models_in_the_contract(read_tree(root), root)

        assert any("modules/stocks/__init__.py:3" in line for line in found)

    def test_the_kernel_importing_a_module_is_caught(self, tmp_path: Path) -> None:
        """`db.py` reaching up into a module ties every module together underneath."""
        root = write_tree(
            tmp_path / "app",
            {
                "db.py": "from app.modules.stocks import StockInfo\n",
                "modules/stocks/__init__.py": '"""Stocks."""\n\n__all__ = ["StockInfo"]\n',
            },
        )

        found = modules_imported_from_below(read_tree(root), root)

        assert any("db.py:1" in line for line in found)

    def test_a_provider_importing_a_module_is_caught(self, tmp_path: Path) -> None:
        """Infrastructure depending on the domain is the inversion that breaks extraction."""
        root = write_tree(
            tmp_path / "app",
            {
                "providers/twelvedata.py": "from app.modules.quotes import Quote\n",
                "modules/quotes/__init__.py": '"""Quotes."""\n\n__all__ = ["Quote"]\n',
            },
        )

        found = modules_imported_from_below(read_tree(root), root)

        assert any("providers/twelvedata.py:1" in line for line in found)

    def test_the_composition_root_is_not_reported(self, tmp_path: Path) -> None:
        """The composition root mounts every router: excluding it is the point of the exception."""
        root = write_tree(
            tmp_path / "app",
            {
                "main.py": "from app.modules.stocks import router\n",
                "modules/stocks/__init__.py": '"""Stocks."""\n\n__all__ = ["router"]\n',
            },
        )

        found = modules_imported_from_below(read_tree(root), root)

        assert found == []

    def test_a_router_reaching_the_repository_is_caught(self, tmp_path: Path) -> None:
        """Skipping the service is skipping the layer where the decisions live."""
        root = write_tree(
            tmp_path / "app",
            {
                "modules/stocks/__init__.py": '"""Stocks."""\n',
                "modules/stocks/router.py": (
                    "from app.modules.stocks.repository import StockRepository\n"
                ),
            },
        )

        found = layers_crossed(read_tree(root), root)

        assert any("does not reach the repository" in line for line in found)

    def test_a_service_importing_fastapi_is_caught(self, tmp_path: Path) -> None:
        """A business rule that raises `HTTPException` is tied to today's transport."""
        root = write_tree(
            tmp_path / "app",
            {
                "modules/stocks/__init__.py": '"""Stocks."""\n',
                "modules/stocks/service.py": "from fastapi import HTTPException\n",
            },
        )

        found = layers_crossed(read_tree(root), root)

        assert any("does not import fastapi" in line for line in found)

    def test_a_grown_layer_is_still_a_layer(self, tmp_path: Path) -> None:
        """`service.py` growing into `services/` changes the shape, not the direction."""
        root = write_tree(
            tmp_path / "app",
            {
                "modules/quotes/__init__.py": '"""Quotes."""\n',
                "modules/quotes/services/cache.py": "from fastapi import HTTPException\n",
            },
        )

        found = layers_crossed(read_tree(root), root)

        assert any("modules/quotes/services/cache.py:1" in line for line in found)

    def test_a_cycle_between_two_modules_is_caught(self, tmp_path: Path) -> None:
        """Two modules that call each other cannot be extracted, tested or deployed apart."""
        root = write_tree(
            tmp_path / "app",
            {
                "modules/stocks/__init__.py": '"""Stocks."""\n',
                "modules/stocks/service.py": "from app.modules.favorites import is_favorite\n",
                "modules/favorites/__init__.py": '"""Favorites."""\n',
                "modules/favorites/service.py": "from app.modules.stocks import get_stocks\n",
            },
        )

        found = cycles(read_tree(root), root)

        assert found == ["favorites -> stocks -> favorites is a cycle, so those are one module"]

    def test_a_cycle_through_a_third_module_is_caught(self, tmp_path: Path) -> None:
        """`a -> b -> c -> a`: no two of them import each other, and the three are still one."""
        root = write_tree(
            tmp_path / "app",
            {
                "modules/auth/__init__.py": '"""Auth."""\n',
                "modules/auth/service.py": "from app.modules.favorites import count\n",
                "modules/favorites/__init__.py": '"""Favorites."""\n',
                "modules/favorites/service.py": "from app.modules.stocks import get_stocks\n",
                "modules/stocks/__init__.py": '"""Stocks."""\n',
                "modules/stocks/service.py": "from app.modules.auth import current_user\n",
            },
        )

        found = cycles(read_tree(root), root)

        assert found == ["auth -> favorites -> stocks -> auth is a cycle, so those are one module"]

    def test_a_one_way_dependency_is_not_a_cycle(self, tmp_path: Path) -> None:
        """The cross-module read the project actually has must not be reported."""
        root = write_tree(
            tmp_path / "app",
            {
                "modules/stocks/__init__.py": '"""Stocks."""\n',
                "modules/favorites/__init__.py": '"""Favorites."""\n',
                "modules/favorites/service.py": "from app.modules.stocks import get_stocks\n",
            },
        )

        found = cycles(read_tree(root), root)

        assert found == []

    def test_a_relationship_that_crosses_is_caught(self, tmp_path: Path) -> None:
        """The coupling that leaves no import behind: `favorite.stock.name`."""
        root = write_tree(
            tmp_path / "app",
            {
                "modules/stocks/__init__.py": '"""Stocks."""\n',
                "modules/stocks/models.py": "class Stock:\n    pass\n",
                "modules/favorites/__init__.py": '"""Favorites."""\n',
                "modules/favorites/models.py": (
                    "class UserStock:\n"
                    '    stock: Mapped["Stock"] = relationship(back_populates="favorites")\n'
                ),
            },
        )

        found = relationships_that_cross(read_tree(root), root)

        assert any("modules/favorites/models.py:2" in line for line in found)

    def test_a_relationship_inside_its_own_module_is_not_reported(self, tmp_path: Path) -> None:
        """The rule is about crossing, not about `relationship()`: a false positive is noise."""
        root = write_tree(
            tmp_path / "app",
            {
                "modules/quotes/__init__.py": '"""Quotes."""\n',
                "modules/quotes/models.py": (
                    "class Quote:\n    pass\n\n\n"
                    "class QuotePoint:\n"
                    '    quote: Mapped["Quote"] = relationship()\n'
                ),
            },
        )

        found = relationships_that_cross(read_tree(root), root)

        assert found == []
