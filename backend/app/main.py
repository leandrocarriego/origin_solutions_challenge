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
from app.errors import (
    AuthenticationError,
    QuoteRangeInvalid,
    QuoteRangeTooLong,
    RateLimitedError,
    UnknownSymbolError,
)
from app.modules.auth import router as auth_router
from app.modules.favorites import router as favorites_router
from app.modules.quotes import router as quotes_router
from app.modules.stocks import keep_the_catalogue_fresh
from app.modules.stocks import router as stocks_router
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
app.include_router(favorites_router)
app.include_router(stocks_router)
app.include_router(quotes_router)


# One handler per domain error and not a generic {type: status} table. The table scales on its
# own and hides the translation behind a lookup; with a handful of entries, explicit wins
# (GEN-10).


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


@app.exception_handler(UnknownSymbolError)
async def symbol_not_on_offer(request: Request, exc: UnknownSymbolError) -> JSONResponse:
    """Answer 404 for a symbol that is not in the catalogue, or no longer trades.

    The body is in English and nobody shows it: what the person reads is the screen's decision
    (UI-02, Article VIII). And it says the same for both cases on purpose -- the caller could
    only choose from what was suggested, so telling them apart would answer a question nobody
    is asking.
    """
    return JSONResponse(
        status_code=status.HTTP_404_NOT_FOUND,
        content={"detail": "unknown symbol"},
    )


@app.exception_handler(QuoteRangeInvalid)
async def range_is_not_a_window(request: Request, exc: QuoteRangeInvalid) -> JSONResponse:
    """Answer 422 with the code the screen turns into a literal of `COPY.md` (RF-41).

    The body carries a code and no text: what the person reads is the screen's decision, and the
    literal lives in `frontend/src` (UI-02, Article VIII).
    """
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
        content={"detail": {"code": "range_invalid"}},
    )


@app.exception_handler(QuoteRangeTooLong)
async def range_is_longer_than_the_interval_serves(
    request: Request, exc: QuoteRangeTooLong
) -> JSONResponse:
    """Answer 422 with the interval and its cap, which the text names (RF-45).

    The two numbers travel because the sentence the person reads names both, and they come from
    here because this is where they are decided: a browser with its own copy of the caps would
    be the same rule written twice.
    """
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
        content={
            "detail": {
                "code": "range_too_long",
                "interval": exc.interval,
                "max_days": exc.max_days,
            }
        },
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
