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


app = FastAPI(
    title="ORIGIN Acciones",
    version=settings.version,
    lifespan=run_background_tasks,
)

# Middlewares

app.add_middleware(RequestContextMiddleware)

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
