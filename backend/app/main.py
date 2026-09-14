"""Composition root: mounts each module's router, CORS and error translation.

It enters modules through the same door as everyone else (Article IV): by the package.

The health endpoint lives here rather than in a module because it is not a business capability:
it is what the reverse proxy and the deploy ask the process about itself. A module is justified
when a domain language appears, and "health" is not one.
"""

import asyncio
import contextlib
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

import structlog
from fastapi import FastAPI, Request, Response, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel

from app.db import database_is_up
from app.errors import AuthenticationError, RateLimitedError
from app.modules.auth import router as auth_router
from app.modules.stocks import keep_the_catalogue_fresh
from app.observability import (
    RequestContextMiddleware,
    configure_logging,
    configure_sentry,
    metrics_endpoint,
)
from app.settings import get_settings

settings = get_settings()

# Before the app exists: a failure while wiring it up should already be structured and reported.
configure_logging()
configure_sentry()


@asynccontextmanager
async def lifespan(_: FastAPI) -> AsyncIterator[None]:
    """Start what has to outlive a request, and stop it when the process goes away.

    The catalogue refresher is the only one: ADR-002 decided the catalogue keeps itself current
    instead of waiting for somebody to remember, and this is where "keeps itself" is wired.

    The warning about the signing secret is here and not in `app/security.py` for the reason that
    file explains: the secret is validated at use and not at import, so a deployment that forgot
    the variable starts fine, answers health in green, and only breaks at the first login. This
    is the one moment where saying so costs nothing.
    """
    if not settings.jwt_secret:
        structlog.get_logger().warning("jwt_secret_missing")

    refresher = asyncio.create_task(keep_the_catalogue_fresh())

    yield

    refresher.cancel()
    with contextlib.suppress(asyncio.CancelledError):
        await refresher


app = FastAPI(title="ORIGIN Acciones", version=settings.version, lifespan=lifespan)

# Outermost, so the request id covers CORS and every error the layers below turn into a response.
app.add_middleware(RequestContextMiddleware)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


app.include_router(auth_router)


# One handler per domain error and not a generic {type: status} table. The table scales on its
# own and hides the translation behind a lookup; with two entries, explicit wins (GEN-10).


@app.exception_handler(AuthenticationError)
async def credential_refused(request: Request, exc: AuthenticationError) -> JSONResponse:
    """Turn the service's refusal into the only 401 the API answers a bad credential with.

    The body is in English and nobody shows it: the screen decides what the user reads, because
    UI-02 wants that literal to live in `frontend/src` (Article VIII). What matters here is that
    it is identical for an unknown user and for a wrong password (RF-06).
    """
    return JSONResponse(
        status_code=status.HTTP_401_UNAUTHORIZED,
        content={"detail": "invalid credentials"},
        headers={"WWW-Authenticate": "Bearer"},
    )


@app.exception_handler(RateLimitedError)
async def too_many_attempts(request: Request, exc: RateLimitedError) -> JSONResponse:
    """Answer 429 and say how long to wait, which is what makes this a wait and not a wall."""
    return JSONResponse(
        status_code=status.HTTP_429_TOO_MANY_REQUESTS,
        content={"detail": "too many attempts"},
        headers={"Retry-After": str(exc.retry_after_seconds)},
    )


class HealthStatus(BaseModel):
    """What health answers.

    Three fields, and none of them derived from configuration: no DSN, no host, no database
    name. A health endpoint that explains how it connects is a map for whoever reads it
    (Article I).
    """

    status: str
    database: str
    version: str


@app.get("/api/health", tags=["operations"], summary="Process and dependency status")
async def health(response: Response) -> HealthStatus:
    """Answer 200 when the database replies, and 503 when it does not.

    The 503 matters as much as the 200: answering 200 with the database down would keep the
    proxy sending traffic to an instance that can serve nothing.
    """
    database_up = await database_is_up()

    response.status_code = (
        status.HTTP_200_OK if database_up else status.HTTP_503_SERVICE_UNAVAILABLE
    )
    return HealthStatus(
        status="ok" if database_up else "degraded",
        database="ok" if database_up else "unavailable",
        version=settings.version,
    )


# Not published through Traefik: it needs no auth and it names symbols, so it stays on the
# internal Docker network where only Prometheus can reach it (ADR-009).
app.add_route("/metrics", metrics_endpoint, methods=["GET"], include_in_schema=False)


__all__ = ["app", "database_is_up"]
