"""Composition root: mounts each module's router, CORS and error translation."""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.error_handlers import register_error_handlers
from app.health import router as health_router
from app.modules.auth import router as auth_router
from app.modules.favorites import router as favorites_router
from app.modules.quotes import router as quotes_router
from app.modules.stocks import router as stocks_router
from app.observability import RequestContextMiddleware, configure_logging, configure_sentry
from app.observability import router as metrics_router
from app.settings import get_settings
from app.tasks import run_background_tasks

settings = get_settings()

# Before the app exists: a failure while wiring it up should already be structured and reported.
configure_logging()
configure_sentry()


# `run_background_tasks` is the lifespan: everything that has to outlive a request starts when
# the application does and stops with it (`app/tasks.py`).
app = FastAPI(
    title="ORIGIN Acciones",
    version=settings.version,
    lifespan=run_background_tasks,
)

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
