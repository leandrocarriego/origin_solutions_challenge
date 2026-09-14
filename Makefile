# Executable source of the project's commands. README.md explains them; here they run.
#
# Rule: when a command appears in CONVENTIONS.md as a convention's verification, it is called
# here exactly the same way, with no variants. A command spelled differently in two places
# eventually diverges, and once it does nobody can tell which spelling counts.
#
# The `## ...` descriptions are what `make help` prints, so they stay in Spanish (GEN-07).

.DEFAULT_GOAL := help
SHELL := /bin/bash

BACKEND  := backend
FRONTEND := frontend
COMPOSE  := docker compose

.PHONY: help install hooks types lint format typecheck test test-fast check build \
        up down logs ps dev-backend dev-frontend deploy clean

# --- Help -------------------------------------------------------------------------------------

help:  ## Lista los comandos disponibles
	@echo "ORIGIN Acciones — comandos"
	@echo
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'
	@echo

# --- Setup --------------------------------------------------------------------------------------

install:  ## Instala las dependencias de ambos proyectos desde sus lockfiles
	cd $(BACKEND) && uv sync --frozen
	cd $(FRONTEND) && npm ci

hooks:  ## Instala los hooks de pre-commit (pre-commit y commit-msg)
	uvx pre-commit install --install-hooks

# --- Contract ------------------------------------------------------------------------------------

# The frontend's API types are generated, never written by hand (TS-03). The OpenAPI document is
# printed by importing the application, not by serving it: `import app.main` needs no database and
# no secret, so this runs on a laptop with nothing up. Prettier runs last because the generated
# file lives under src/ and `make lint` checks it like any other source.
# JWT_SECRET is inline and throwaway on purpose: exporting the OpenAPI imports the application,
# and since the secret is a required field of Settings (SEC-05), importing it demands one. What
# comes out of here is a document of types; nothing is signed or verified with this value.
types:  ## Genera los tipos de la API del frontend desde el OpenAPI del backend (TS-03)
	cd $(BACKEND) && JWT_SECRET=openapi-export-only-not-a-real-secret MARKET_DATA_PROVIDER=fake uv run python -c \
		'import json; from app.main import app; print(json.dumps(app.openapi()))' \
		| (cd ../$(FRONTEND) && npx openapi-typescript --output src/api/schema.d.ts)
	cd $(FRONTEND) && npx prettier --write src/api/schema.d.ts

# --- Verification (the same commands CONVENTIONS.md states) -------------------------------------

lint:  ## Formato y lint de backend y frontend (GEN-01, PY-07, TS-02, TS-04)
	cd $(BACKEND) && uv run ruff format --check app tests seed.py alembic && uv run ruff check app tests seed.py alembic
	cd $(FRONTEND) && npm run format:check && npm run lint

format:  ## Reescribe el código con el formateador de cada proyecto
	cd $(BACKEND) && uv run ruff format app tests seed.py alembic && uv run ruff check --fix app tests seed.py alembic
	cd $(FRONTEND) && npm run format

typecheck:  ## Chequeo de tipos (PY-09, TS-01)
	cd $(BACKEND) && uv run mypy app tests seed.py alembic
	cd $(FRONTEND) && npm run type-check

test:  ## Suite completa con cobertura (TEST-*, UI-02, UI-03)
	cd $(BACKEND) && uv run pytest
	cd $(FRONTEND) && npm test

test-fast:  ## Sólo unidad y arquitectura, sin cobertura: lo que corre el pre-commit
	cd $(BACKEND) && uv run pytest tests/unit tests/architecture --no-cov -q

check: lint typecheck test  ## Todo lo anterior, en el orden en que conviene fallar

# --- Development --------------------------------------------------------------------------------

dev-backend:  ## Levanta el backend con recarga en http://localhost:8000
	cd $(BACKEND) && uv run uvicorn app.main:app --reload --port 8000

dev-frontend:  ## Levanta el frontend con recarga en http://localhost:5173
	cd $(FRONTEND) && npm run dev

build:  ## Compila el frontend para producción
	cd $(FRONTEND) && npm run build

# --- Local infrastructure -----------------------------------------------------------------------

up:  ## Levanta todo con docker compose (ADR-007)
	$(COMPOSE) up -d --build

down:  ## Baja todo, conservando el volumen de la base
	$(COMPOSE) down

logs:  ## Sigue los logs de todos los servicios
	$(COMPOSE) logs -f

ps:  ## Estado de los servicios locales
	$(COMPOSE) ps

# --- Production ---------------------------------------------------------------------------------

deploy:  ## Despliega al VPS (requiere el ssh host `mendri` y su .env)
	./scripts/deploy.sh

# --- Cleanup -------------------------------------------------------------------------------------

clean:  ## Borra cachés y artefactos de build locales
	find . -type d \( -name __pycache__ -o -name .pytest_cache -o -name .mypy_cache \
		-o -name .ruff_cache \) -not -path './*/node_modules/*' -prune -exec rm -rf {} +
	rm -rf $(FRONTEND)/dist $(BACKEND)/.coverage $(BACKEND)/htmlcov
