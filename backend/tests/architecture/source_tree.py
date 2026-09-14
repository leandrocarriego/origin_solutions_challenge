"""Reading the source tree the way the boundary checks need it.

Python has no visibility at module level: the underscore and `__all__` are convention, not
enforcement. That is why Article IV says the frontier is held by a test and not by the
language, and why these checks read the imports with `ast` and fail naming file and line.

Every function here takes the root of a package tree instead of reaching for `app/` on its
own. That is what lets each rule be applied twice: once to the real code, and once to a
synthetic tree that breaks it on purpose. A check nobody has ever seen fail is a check nobody
knows works.
"""

import ast
from dataclasses import dataclass
from pathlib import Path

BACKEND_ROOT = Path(__file__).resolve().parents[2]
APP_ROOT = BACKEND_ROOT / "app"

# The composition root mounts every module's router, so it imports from all of them by
# definition. GEN-03 excludes it by name, and this is the name.
COMPOSITION_ROOT = "main.py"

# The four clients CONVENTIONS.md names in GEN-08, and it has to stay those four: dropping one
# narrows a Blocker convention without a single test turning red.
#
# The rule is not about TwelveData. A service that imports one of these and builds a URL has
# already left through the window, and it can do that without ever naming the provider.
HTTP_CLIENTS = ("httpx", "requests", "aiohttp", "urllib.request")

# A piece of a module grows from file to directory of the same name when the size asks for it.
# The direction of the flow does not change with the shape, so both spellings map to one layer.
# `schemas` maps to itself, and the entry stays for that reason: without it the directory would
# read as a layer this map does not know, which is the same answer as "not part of a module".
LAYER_OF_DIRECTORY = {
    "routers": "router",
    "services": "service",
    "repositories": "repository",
    "schemas": "schemas",
    "models": "models",
}


@dataclass(frozen=True)
class Import:
    """One import statement, resolved to the absolute dotted path it reaches."""

    module: str
    names: tuple[str, ...]
    line: int

    def reaches(self, dotted: str) -> bool:
        """Whether the import lands on `dotted` or on anything underneath it."""
        return self.module == dotted or self.module.startswith(f"{dotted}.")


@dataclass(frozen=True)
class SourceFile:
    """One `.py` file, with its imports already resolved to absolute paths."""

    path: Path
    relative: Path
    package: str
    imports: tuple[Import, ...]
    tree: ast.Module

    def where(self, line: int) -> str:
        """A location a person can click on: path relative to the tree, plus the line."""
        return f"{self.relative}:{line}"

    def imports_any(self, dotted_names: tuple[str, ...]) -> list[Import]:
        """Every import that reaches one of `dotted_names`."""
        return [
            found for found in self.imports if any(found.reaches(dotted) for dotted in dotted_names)
        ]


def _resolve(node: ast.ImportFrom, package: str) -> str:
    """Turn a possibly relative `from ... import ...` into the absolute path it reaches."""
    if not node.level:
        return node.module or ""

    parts = package.split(".")
    base = ".".join(parts[: len(parts) - node.level + 1])
    return f"{base}.{node.module}" if node.module else base


def _imports_of(tree: ast.Module, package: str) -> tuple[Import, ...]:
    """Every import in the file, flattened to one entry per dotted path."""
    found: list[Import] = []

    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            found.extend(
                Import(module=alias.name, names=(), line=node.lineno) for alias in node.names
            )
        elif isinstance(node, ast.ImportFrom):
            names = tuple(alias.name for alias in node.names)
            found.append(Import(module=_resolve(node, package), names=names, line=node.lineno))

    return tuple(found)


def read_tree(app_root: Path) -> list[SourceFile]:
    """Parse every `.py` file under `app_root`, resolving imports against its own package."""
    files: list[SourceFile] = []

    for path in sorted(app_root.rglob("*.py")):
        relative = path.relative_to(app_root.parent)
        directory = relative.parent.parts
        package = ".".join(directory)
        source = path.read_text(encoding="utf-8")

        files.append(
            SourceFile(
                path=path,
                relative=relative,
                package=package,
                imports=_imports_of(ast.parse(source), package),
                tree=ast.parse(source),
            )
        )

    return files


def root_package(app_root: Path) -> str:
    """The name the tree is imported by: `app` for the real one, whatever a fixture called it."""
    return app_root.name


def module_names(app_root: Path) -> list[str]:
    """The business modules that exist today: every package under `modules/`.

    Empty is a valid answer and means phase 0 has not created them yet. The checks that build
    on this then have nothing to look at, which is why each of them is paired with a test that
    runs it against a tree that does have modules, and violations.
    """
    modules = app_root / "modules"
    if not modules.is_dir():
        return []

    return sorted(child.name for child in modules.iterdir() if (child / "__init__.py").is_file())


def owning_module(source: SourceFile, app_root: Path) -> str | None:
    """Which business module the file belongs to, or None if it is kernel or infrastructure."""
    prefix = f"{root_package(app_root)}.modules."
    if not source.package.startswith(prefix):
        return None

    return source.package[len(prefix) :].split(".")[0]


def layer_of(source: SourceFile, app_root: Path) -> str | None:
    """Which layer of its module the file is: router, service, repository, schemas or models."""
    module = owning_module(source, app_root)
    if module is None:
        return None

    inside = source.package.removeprefix(f"{root_package(app_root)}.modules.{module}").lstrip(".")
    if inside:
        return LAYER_OF_DIRECTORY.get(inside.split(".")[0])

    return None if source.path.name == "__init__.py" else source.path.stem


def package_of(app_root: Path, module: str) -> str:
    """The dotted path of a module's package: what the outside world is allowed to import."""
    return f"{root_package(app_root)}.modules.{module}"


def write_tree(root: Path, files: dict[str, str]) -> Path:
    """Write a throwaway package tree and return its root.

    This is how every check proves it is not vacuous. The tree is written under pytest's
    `tmp_path`, parsed like any other, and thrown away: nothing here touches the real `app/`.
    """
    for relative, source in files.items():
        target = root / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(source, encoding="utf-8")

    return root
