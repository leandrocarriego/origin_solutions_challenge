# syntax=docker/dockerfile:1

# --- build: resolve dependencies once, in a layer that only changes with the lockfile ---------
FROM python:3.13-slim AS builder

COPY --from=ghcr.io/astral-sh/uv:0.7.13 /uv /usr/local/bin/uv

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=never

WORKDIR /app

# Dependencies first, and without the project itself: editing app code must not reinstall them.
COPY pyproject.toml uv.lock ./
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-install-project --no-dev

COPY app ./app
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev

# --- runtime: no uv, no build cache, no root ---------------------------------------------------
FROM python:3.13-slim AS runtime

# Non-root by default. A container that does not need root should not have it, and this one
# only reads its own code and talks to Postgres.
RUN useradd --create-home --uid 10001 origin

WORKDIR /app

COPY --from=builder --chown=origin:origin /app/.venv /app/.venv
COPY --from=builder --chown=origin:origin /app/app /app/app

# The schema and the two scripts that bring a container up: migrations run on every start, the
# seed only when SEED_ON_START says so.
COPY --chown=origin:origin alembic.ini ./alembic.ini
COPY --chown=origin:origin alembic ./alembic
COPY --chown=origin:origin seed.py ./seed.py
COPY --chown=origin:origin docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

USER origin

EXPOSE 8000

# Traefik decides whether to route here; this is what tells it and the orchestrator apart from
# a process that is up but cannot serve.
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8000/api/health', timeout=4).status==200 else 1)"

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# forwarded-allow-ips lists the private networks the proxy can live in, never "*". uvicorn walks
# X-Forwarded-For from right to left and stops at the first address it does not trust; with "*"
# it trusts everything and stops at the leftmost element, which is the one the client writes --
# so any caller could pick its own address. Only the proxy's hop is trusted here.
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--proxy-headers", "--forwarded-allow-ips", "127.0.0.1,172.16.0.0/12,10.0.0.0/8,192.168.0.0/16"]
