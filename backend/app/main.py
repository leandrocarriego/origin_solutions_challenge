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

from fastapi import FastAPI, Response, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from app.db import database_is_up
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
    """
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
