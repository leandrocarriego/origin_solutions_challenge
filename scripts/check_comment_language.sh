#!/usr/bin/env bash
#
# GEN-07: comments in code and configuration files are written in English.
#
# The markers below are Spanish function words that do not exist in English. Words that are
# spelled the same in both ("no", "es", "son", "si", "la", "un", "sin", "solo", "version") are
# deliberately left out: a check that cries wolf is a check people learn to skip.
#
# What stays in Spanish is output, not comments: `make help` descriptions, pre-commit hook
# names, CI step names and the script's own echo lines. None of those start a comment, so none
# of them are inspected here.
set -uo pipefail

MARCADORES='que|qué|para|los|las|del|con|una|unos|unas|este|esta|esto|porque|cuando|donde'
MARCADORES="${MARCADORES}|aunque|mientras|siempre|nunca|también|así|entonces|cada|nadie|otro"
MARCADORES="${MARCADORES}|misma|mismo|nuestro|según|entorno|sistema|archivo|carpeta|idioma"
MARCADORES="${MARCADORES}|ejemplo|configuración|aplicación|deja|queda|puede|debe|tiene|lleva"

# Comment lines only: `#`, `//`, `--`, and the ` * ` of a block comment.
PATRON="^[[:space:]]*(#|//|--|\*)[[:space:]]*.*(\b(${MARCADORES})\b|[áéíóúñ¿¡])"

# Documentation and spec artefacts are written in Spanish on purpose (Article VIII), and so is
# everything the agent process reads.
archivos=$(git ls-files -c -o --exclude-standard \
  | grep -vE '\.(md|pdf|lock)$' \
  | grep -vE '^(docs/|agents/|\.claude/)')

fallos=0
while IFS= read -r archivo; do
  [ -f "$archivo" ] || continue
  if salida=$(grep -nEI "$PATRON" "$archivo" 2>/dev/null); then
    while IFS= read -r linea; do
      echo "  ${archivo}:${linea}"
      fallos=$((fallos + 1))
    done <<< "$salida"
  fi
done <<< "$archivos"

if [ "$fallos" -gt 0 ]; then
  echo
  echo "GEN-07: ${fallos} comentario(s) en castellano en código o configuración."
  echo "Los comentarios van en inglés; la salida que ve la terminal va en español."
  exit 1
fi
