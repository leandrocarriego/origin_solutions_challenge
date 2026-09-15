#!/usr/bin/env bash
#
# One command from a fresh clone to a running application: the environment file, the two optional
# credentials, the containers, the migrations, the demo dataset, and a health check that decides
# whether any of it worked.
#
# The two credentials are asked for, never required. A reviewer who has no TwelveData account has
# to be able to run this: skipping the key leaves the fake provider in place and the application
# is the same one, with simulated series. Skipping the DSN leaves Sentry off -- no events, no
# network. Article I applies to this script as well: a value that is typed here is written to
# .env and never echoed back, not even to confirm it.

set -euo pipefail

readonly ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly ENV_FILE="${ROOT}/.env"
readonly EXAMPLE_FILE="${ROOT}/.env.example"
readonly HEALTH_URL="http://localhost:8000/api/health"
readonly HEALTH_TIMEOUT=120

readonly BOLD=$'\033[1m'
readonly DIM=$'\033[2m'
readonly GREEN=$'\033[32m'
readonly YELLOW=$'\033[33m'
readonly RESET=$'\033[0m'

step() { printf '\n%s==>%s %s\n' "${BOLD}" "${RESET}" "$1"; }
note() { printf '    %s%s%s\n' "${DIM}" "$1" "${RESET}"; }

# --- The environment file ------------------------------------------------------------------------

# Read a key from .env. Empty when the key is absent or has no value, which is the same thing as
# far as every caller here is concerned.
env_get() {
	local key="$1"
	[[ -f "${ENV_FILE}" ]] || return 0
	sed -n "s/^${key}=//p" "${ENV_FILE}" | tail -n 1
}

# Write a key to .env, replacing the line if it is already there and appending it if it is not.
# Done with a temporary file instead of `sed -i` because the in-place flag takes an argument on
# BSD sed and none on GNU sed, and this runs on both.
env_set() {
	local key="$1" value="$2" tmp
	tmp="$(mktemp)"
	if grep -q "^${key}=" "${ENV_FILE}" 2>/dev/null; then
		awk -v key="${key}" -v value="${value}" \
			'$0 ~ "^" key "=" { print key "=" value; next } { print }' \
			"${ENV_FILE}" >"${tmp}"
	else
		cat "${ENV_FILE}" >"${tmp}" 2>/dev/null || true
		printf '%s=%s\n' "${key}" "${value}" >>"${tmp}"
	fi
	cat "${tmp}" >"${ENV_FILE}"
	rm -f "${tmp}"
}

# Ask for a credential, once. Three ways out without asking: the value is already configured, the
# input is not a terminal (CI, `make setup < /dev/null`), or the person presses Enter. A setup that
# blocks on a `read` in a pipeline is a bug that surfaces on the worst possible day.
ask_secret() {
	local key="$1" prompt="$2" value

	if [[ -n "$(env_get "${key}")" ]]; then
		note "${key} ya está configurada — no se vuelve a preguntar."
		return 0
	fi

	if [[ ! -t 0 ]]; then
		note "${key} sin configurar (entrada no interactiva)."
		return 1
	fi

	printf '    %s\n    %s[Enter] para omitir:%s ' "${prompt}" "${DIM}" "${RESET}"
	read -r -s value || value=""
	printf '\n'

	# Trim: a value pasted from a dashboard tends to arrive with a space attached.
	value="${value#"${value%%[![:space:]]*}"}"
	value="${value%"${value##*[![:space:]]}"}"

	if [[ -z "${value}" ]]; then
		note "Omitida."
		return 1
	fi

	env_set "${key}" "${value}"
	note "Guardada en .env (que no se versiona)."
	return 0
}

# --- Steps ---------------------------------------------------------------------------------------

require_docker() {
	command -v docker >/dev/null 2>&1 || {
		printf '%sDocker no está instalado o no está en el PATH.%s\n' "${YELLOW}" "${RESET}" >&2
		exit 1
	}
	docker compose version >/dev/null 2>&1 || {
		printf '%sDocker está, pero `docker compose` no responde. ¿Está corriendo el daemon?%s\n' \
			"${YELLOW}" "${RESET}" >&2
		exit 1
	}
}

create_env_file() {
	step "Archivo de entorno"
	if [[ -f "${ENV_FILE}" ]]; then
		note ".env ya existe — se conserva tal como está."
	else
		cp "${EXAMPLE_FILE}" "${ENV_FILE}"
		note ".env creado desde .env.example."
	fi
}

ask_credentials() {
	step "Credenciales (las dos son opcionales)"

	if ask_secret TWELVEDATA_API_KEY \
		"API key de TwelveData — https://twelvedata.com/ (gratis, 800 requests por día)"; then
		env_set MARKET_DATA_PROVIDER twelvedata
	else
		env_set MARKET_DATA_PROVIDER fake
		note "Sin key: el proveedor queda en 'fake' y la aplicación funciona con series simuladas."
	fi

	ask_secret SENTRY_DSN "DSN de Sentry — reporte de errores" || \
		note "Sin DSN: Sentry queda desactivado, sin eventos y sin red."
}

start_services() {
	step "Contenedores"
	note "Construye las imágenes, aplica las migraciones y carga los datos de prueba."
	docker compose up -d --build
}

wait_for_health() {
	step "Esperando a que la API esté sana"
	local waited=0
	until curl --silent --fail --max-time 2 "${HEALTH_URL}" >/dev/null 2>&1; do
		if ((waited >= HEALTH_TIMEOUT)); then
			printf '\n%sLa API no respondió en %ss. Mirá qué pasó con: make logs%s\n' \
				"${YELLOW}" "${HEALTH_TIMEOUT}" "${RESET}" >&2
			exit 1
		fi
		sleep 2
		waited=$((waited + 2))
		printf '.'
	done
	printf '\n'
	note "GET /api/health responde 200."
}

# The catalogue is what the autocomplete searches, and it is filled by the ingestion -- which
# needs a key. Without one there are seven symbols, enough for the brief's own grid and not much
# else. So when no key was given, the dataset comes from the backup instead: the same catalogue,
# photographed from a run that did have a key. With a key, nothing is restored -- the ingestion
# fills it and reconciles it on its own (ADR-002), and the two paths end at the same place.
load_dataset() {
	local dump="${ROOT}/db/backup.sql"

	[[ -f "${dump}" ]] || return 0
	[[ "$(env_get MARKET_DATA_PROVIDER)" != "twelvedata" ]] || return 0

	step "Catálogo"
	note "Sin API key: se restaura db/backup.sql, que trae el catálogo completo."
	docker compose exec -T db psql -q -v ON_ERROR_STOP=1 -U origin -d origin <"${dump}" >/dev/null
	docker compose restart backend >/dev/null
	wait_for_health
}

summary() {
	local provider
	provider="$(env_get MARKET_DATA_PROVIDER)"

	printf '\n%s%sTodo listo.%s\n\n' "${BOLD}" "${GREEN}" "${RESET}"
	printf '  Aplicación    http://localhost:5173\n'
	printf '  API           http://localhost:8000/api/health\n'
	printf '  OpenAPI       http://localhost:8000/docs\n'
	printf '  Grafana       http://localhost:3000\n'
	printf '\n'
	printf '  Usuario       juan@demo.com  /  Demo1234*\n'
	printf '  Grafana       juan@demo.com  /  Demo1234*\n'
	printf '\n'
	if [[ "${provider}" == "twelvedata" ]]; then
		printf '  Proveedor     TwelveData — cotizaciones reales\n'
	else
		printf '  Proveedor     fake — series simuladas, sin red ni cuota consumida\n'
		printf '                %sLa aplicación es la misma; sólo cambia de dónde salen los datos.%s\n' \
			"${DIM}" "${RESET}"
	fi
	printf '\n  %smake down%s para bajarlo, %smake up%s para volver a levantarlo.%s\n\n' \
		"${BOLD}" "${RESET}" "${BOLD}" "${RESET}" "${RESET}"
}

main() {
	require_docker
	create_env_file
	ask_credentials
	start_services
	wait_for_health
	load_dataset
	summary
}

main "$@"
