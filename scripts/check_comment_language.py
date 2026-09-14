#!/usr/bin/env python3
"""GEN-07: comments in code and configuration files are written in English."""

import io
import re
import subprocess
import sys
import tokenize
from pathlib import Path

MARKERS = frozenset(
    """qué que para los las del con una unos unas este esta esto estos estas ese esa eso
    porque cuando cuándo donde dónde aunque mientras siempre nunca también así entonces cada
    nadie ninguno ninguna otro otra otros otras mismo misma nuestro nuestra según entorno
    sistema archivo archivos carpeta idioma comentario comentarios ejemplo configuración
    aplicación deja dejan queda quedan puede pueden debe deben tiene tienen lleva llevan
    hacer hace hacen levanta corre corren muestra vive viven""".split()
)

ACCENTS = re.compile(r"[áéíóúñ¿¡]", re.IGNORECASE)
WORD = re.compile(r"[a-záéíóúñ]+", re.IGNORECASE)

# What a comment quotes is not what a comment is written in: `Esa acción ya está en tu lista.`
# inside an English sentence is the copy being named, not prose in Spanish. Unterminated
# backticks are left alone -- with an odd number of them there is no quote to speak of.
QUOTED = re.compile(r"`[^`]*`")

# Documentation and spec artefacts are Spanish on purpose (Article VIII), and so is everything
# the agent process reads.
SKIPPED_PREFIXES = ("docs/", "agents/", ".claude/")
SKIPPED_SUFFIXES = (".md", ".pdf", ".lock", ".mako")


def comment_of(line: str, markers: tuple[str, ...]) -> str | None:
    """The comment part of a line, with quoted text removed so a `#` inside a string is ignored."""
    quote: str | None = None
    index = 0
    while index < len(line):
        char = line[index]
        if quote:
            if char == "\\":
                index += 2
                continue
            if char == quote:
                quote = None
        elif char in "\"'":
            quote = char
        else:
            for marker in markers:
                if line.startswith(marker, index):
                    return line[index + len(marker) :]
        index += 1
    return None


def markers_for(path: Path) -> tuple[str, ...]:
    """Which comment markers this file's language uses."""
    if path.suffix in {".ts", ".tsx", ".js", ".jsx", ".css"}:
        return ("//",)
    if path.suffix == ".sql":
        return ("--",)
    return ("#",)


def python_comments(source: str) -> list[tuple[int, str]]:
    """Every real comment in a Python file, found by the tokenizer.

    Scanning character by character cannot tell a comment from a `#` inside a docstring, because
    a docstring spans lines and the scanner sees one line at a time. The tokenizer knows.
    """
    found: list[tuple[int, str]] = []
    try:
        for token in tokenize.generate_tokens(io.StringIO(source).readline):
            if token.type == tokenize.COMMENT:
                found.append((token.start[0], token.string.lstrip("#")))
    except (tokenize.TokenError, IndentationError, SyntaxError):
        return []
    return found


def tracked_files() -> list[Path]:
    """Every file git knows about or would add, minus what is Spanish on purpose."""
    salida = subprocess.run(
        ["git", "ls-files", "-c", "-o", "--exclude-standard"],
        capture_output=True,
        text=True,
        check=True,
    ).stdout.split("\n")
    return [
        Path(name)
        for name in salida
        if name
        and not name.startswith(SKIPPED_PREFIXES)
        and not name.endswith(SKIPPED_SUFFIXES)
        and Path(name).is_file()
    ]


def main() -> int:
    """Report every Spanish comment and fail if there is one."""
    findings: list[str] = []
    for path in tracked_files():
        try:
            lines = path.read_text(encoding="utf-8").splitlines()
        except (UnicodeDecodeError, OSError):
            continue
        if path.suffix == ".py":
            comments = python_comments("\n".join(lines))
        else:
            markers = markers_for(path)
            comments = []
            for number, line in enumerate(lines, 1):
                found = comment_of(line, markers)
                if found is None:
                    continue
                # `## text` in a Makefile is what `make help` prints, not a comment for whoever
                # edits the file, and GEN-07 keeps that output in Spanish.
                if path.name == "Makefile" and found.startswith("#"):
                    continue
                comments.append((number, found))

        for number, comment in comments:
            prose = QUOTED.sub(" ", comment)
            words = {w.lower() for w in WORD.findall(prose)}
            if words & MARKERS or ACCENTS.search(prose):
                findings.append(f"  {path}:{number}  {comment.strip()[:90]}")

    if findings:
        print("\n".join(findings))
        print(f"\nGEN-07: {len(findings)} comentario(s) en castellano en código o configuración.")
        print("Los comentarios van en inglés; la salida que ve la terminal va en español.")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
