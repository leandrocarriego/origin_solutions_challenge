# Fuente ejecutable de los comandos del proyecto. `README.md` los explica; acá se corren.
#
# Regla: si un comando aparece en `CONVENTIONS.md` como verificación de una convención, acá
# se lo llama igual, sin variantes. Un comando que se escribe distinto en dos lugares termina
# divergiendo, y el día que diverge nadie sabe cuál de los dos es el que vale.

.DEFAULT_GOAL := help
SHELL := /bin/bash

BACKEND  := backend
FRONTEND := frontend
COMPOSE  := docker compose

.PHONY: help install hooks lint format typecheck test test-fast check build \
        up down logs ps dev-backend dev-frontend deploy clean

# --- Ayuda ------------------------------------------------------------------------------------

help:  ## Lista los comandos disponibles
	@echo "ORIGIN Acciones — comandos"
	@echo
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'
	@echo

# --- Puesta en marcha ---------------------------------------------------------------------------

install:  ## Instala las dependencias de ambos proyectos desde sus lockfiles
	cd $(BACKEND) && uv sync --frozen
	cd $(FRONTEND) && npm ci

hooks:  ## Instala los hooks de pre-commit (pre-commit y commit-msg)
	uvx pre-commit install --install-hooks

# --- Verificación (los mismos comandos que CONVENTIONS.md) --------------------------------------

lint:  ## Formato y lint de backend y frontend (GEN-01, PY-07, TS-02, TS-04)
	cd $(BACKEND) && uv run ruff format --check app tests && uv run ruff check app tests
	cd $(FRONTEND) && npm run format:check && npm run lint

format:  ## Reescribe el código con el formateador de cada proyecto
	cd $(BACKEND) && uv run ruff format app tests && uv run ruff check --fix app tests
	cd $(FRONTEND) && npm run format

typecheck:  ## Chequeo de tipos (PY-09, TS-01)
	cd $(BACKEND) && uv run mypy app tests
	cd $(FRONTEND) && npm run type-check

test:  ## Suite completa con cobertura (TEST-*, UI-02, UI-03)
	cd $(BACKEND) && uv run pytest
	cd $(FRONTEND) && npm test

test-fast:  ## Sólo unidad y arquitectura, sin cobertura: lo que corre el pre-commit
	cd $(BACKEND) && uv run pytest tests/unit tests/architecture --no-cov -q

check: lint typecheck test  ## Todo lo anterior, en el orden en que conviene fallar

# --- Desarrollo ---------------------------------------------------------------------------------

dev-backend:  ## Levanta el backend con recarga en http://localhost:8000
	cd $(BACKEND) && uv run uvicorn app.main:app --reload --port 8000

dev-frontend:  ## Levanta el frontend con recarga en http://localhost:5173
	cd $(FRONTEND) && npm run dev

build:  ## Compila el frontend para producción
	cd $(FRONTEND) && npm run build

# --- Infraestructura local ----------------------------------------------------------------------

up:  ## Levanta todo con docker compose (ADR-007)
	$(COMPOSE) up -d --build

down:  ## Baja todo, conservando el volumen de la base
	$(COMPOSE) down

logs:  ## Sigue los logs de todos los servicios
	$(COMPOSE) logs -f

ps:  ## Estado de los servicios locales
	$(COMPOSE) ps

# --- Producción ---------------------------------------------------------------------------------

deploy:  ## Despliega al VPS (requiere el ssh host `mendri` y su .env)
	./scripts/deploy.sh

# --- Limpieza ------------------------------------------------------------------------------------

clean:  ## Borra cachés y artefactos de build locales
	find . -type d \( -name __pycache__ -o -name .pytest_cache -o -name .mypy_cache \
		-o -name .ruff_cache \) -not -path './*/node_modules/*' -prune -exec rm -rf {} +
	rm -rf $(FRONTEND)/dist $(BACKEND)/.coverage $(BACKEND)/htmlcov
