"""Composition root: mounts each module's router, CORS and error translation."""

import asyncio
import contextlib
from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.error_handlers import register_error_handlers
from app.health import router as health_router
from app.modules.auth import router as auth_router
from app.modules.favorites import router as favorites_router
from app.modules.quotes import router as quotes_router
from app.modules.stocks import keep_the_catalogue_fresh
from app.modules.stocks import router as stocks_router
from app.observability import RequestContextMiddleware, configure_logging, configure_sentry
from app.observability import router as metrics_router
from app.settings import get_settings

settings = get_settings()

# Before the app exists: a failure while wiring it up should already be structured and reported.
configure_logging()
configure_sentry()


@asynccontextmanager
async def lifespan(_: FastAPI) -> AsyncGenerator[None]:
    """Start what has to outlive a request, and stop it when the process goes away.

    The catalogue refresher is the only one: ADR-002 decided the catalogue keeps itself current
    instead of waiting for somebody to remember, and this is where "keeps itself" is wired.

    The return type is `AsyncGenerator` and not `AsyncIterator`: this function yields, so it is a
    generator, and annotating `@asynccontextmanager` with the iterator is deprecated.

    Nothing is checked about the signing secret here any more, and that is the improvement rather
    than an omission: `JWT_SECRET` is a required field of `Settings` with a minimum length, so a
    process without a usable one never gets as far as this function. The warning that used to live
    here was the compensation for a check that happened at the first login; the check now happens
    before the application object exists.
    """
    refresher = asyncio.create_task(keep_the_catalogue_fresh())

    yield

    refresher.cancel()
    with contextlib.suppress(asyncio.CancelledError):
        await refresher


app = FastAPI(title="ORIGIN Acciones", version=settings.version, lifespan=lifespan)

# Middlewares

# Outermost, so the request id covers CORS and every error the layers below turn into a response.
app.add_middleware(RequestContextMiddleware)

# `allow_credentials=False` because nothing here travels in a cookie: the session is a bearer
# token in `Authorization`, which is a request header and is governed by `allow_headers`. The flag
# is what turns a widened origin list into any site making authenticated requests, so it is off
# for the same reason a door nobody uses is still locked.
#
# The methods are the three the API has. `*` would also announce PUT and PATCH, which exist
# nowhere and would answer 405 -- advertising surface that is not there.
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=False,
    allow_methods=["GET", "POST", "DELETE"],
    allow_headers=["*"],
)

# Routers

app.include_router(health_router)
app.include_router(metrics_router)

app.include_router(auth_router)
app.include_router(favorites_router)
app.include_router(stocks_router)
app.include_router(quotes_router)

# When a service communicates a failure by raising, this is where the raise turns into a status.
register_error_handlers(app)

__all__ = ["app"]
