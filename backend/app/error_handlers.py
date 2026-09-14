"""The translation from a domain error to an HTTP answer, registered on the application."""

from typing import cast

import structlog
from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse
from starlette.types import ExceptionHandler

from app.errors import (
    AuthenticationError,
    DomainError,
    QuoteRangeInvalid,
    QuoteRangeTooLong,
    RateLimitedError,
    UnknownSymbolError,
)

_log = structlog.get_logger()


async def rule_nobody_translated(request: Request, exc: DomainError) -> JSONResponse:
    """Answer 500 for a domain error that was never given a handler of its own.

    Starlette resolves a handler by walking the exception's MRO, so this one catches every
    `DomainError` subclass that was added without its line below. That is a missing wire and not
    a business outcome, and it answers as one.

    The body says nothing about the exception: its message was written for a log and not for an
    API, so a rule nobody translated has no contract to honour. The log line does carry the type,
    because answering quietly would hide the only thing worth knowing -- which handler is
    missing.
    """
    _log.error("domain_error_not_translated", error=type(exc).__name__)

    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "internal error"},
    )


async def credential_refused(request: Request, exc: AuthenticationError) -> JSONResponse:
    """Turn the service's refusal into the only 401 the API answers a bad credential with."""
    return JSONResponse(
        status_code=status.HTTP_401_UNAUTHORIZED,
        content={"detail": "invalid credentials"},
        headers={"WWW-Authenticate": "Bearer"},
    )


async def too_many_attempts(request: Request, exc: RateLimitedError) -> JSONResponse:
    """Answer 429 and say how long to wait, which is what makes this a wait and not a wall."""
    return JSONResponse(
        status_code=status.HTTP_429_TOO_MANY_REQUESTS,
        content={"detail": "too many attempts"},
        headers={"Retry-After": str(exc.retry_after_seconds)},
    )


async def symbol_not_on_offer(request: Request, exc: UnknownSymbolError) -> JSONResponse:
    """Answer 404 for a symbol that is not in the catalogue, or no longer trades."""
    return JSONResponse(
        status_code=status.HTTP_404_NOT_FOUND,
        content={"detail": "unknown symbol"},
    )


async def range_is_not_a_window(request: Request, exc: QuoteRangeInvalid) -> JSONResponse:
    """Answer 422 with the code the screen turns into the text it shows."""
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
        content={"detail": {"code": "range_invalid"}},
    )


async def range_is_longer_than_the_interval_serves(
    request: Request, exc: QuoteRangeTooLong
) -> JSONResponse:
    """Answer 422 with the interval and its cap."""
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


def register_error_handlers(app: FastAPI) -> None:
    """Wire every domain error to the answer it becomes."""
    app.add_exception_handler(DomainError, cast("ExceptionHandler", rule_nobody_translated))
    app.add_exception_handler(AuthenticationError, cast("ExceptionHandler", credential_refused))
    app.add_exception_handler(RateLimitedError, cast("ExceptionHandler", too_many_attempts))
    app.add_exception_handler(UnknownSymbolError, cast("ExceptionHandler", symbol_not_on_offer))
    app.add_exception_handler(QuoteRangeInvalid, cast("ExceptionHandler", range_is_not_a_window))
    app.add_exception_handler(
        QuoteRangeTooLong,
        cast("ExceptionHandler", range_is_longer_than_the_interval_serves),
    )


__all__ = ["register_error_handlers"]
