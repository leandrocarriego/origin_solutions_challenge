"""The translation from a domain error to an HTTP answer, registered on the application.

A service communicates a failure by raising, never by returning a status: `PY-06` and `ERR-04`
keep `HTTPException` out of the modules, so somewhere the raise has to become a response. That
somewhere is here.

It lives beside `main.py` and not inside it because the composition root is where the application
is *assembled*, and eighty lines of translation there make the assembly hard to read. What
`main.py` keeps is the call: one line that says the handlers are registered.

It imports from `app.errors` and from nothing else of ours. That is what makes the extraction
legal at all: `GEN-03` lets only `main.py` reach into a module, and a file that translated a
module's own exception would have to.

One handler per error and not a generic `{type: status}` table. The table scales on its own and
hides the translation behind a lookup; with a handful of entries, explicit wins (GEN-10).

Every body is in English and nobody shows it: what the person reads is the screen's decision, and
`UI-02` wants that literal to live in `frontend/src` (Article VIII).
"""

from typing import cast

from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse
from starlette.types import ExceptionHandler

from app.errors import (
    AuthenticationError,
    QuoteRangeInvalid,
    QuoteRangeTooLong,
    RateLimitedError,
    UnknownSymbolError,
)


async def credential_refused(request: Request, exc: AuthenticationError) -> JSONResponse:
    """Turn the service's refusal into the only 401 the API answers a bad credential with.

    What matters here is that it is identical for an unknown user and for a wrong password
    (RF-06).
    """
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
    """Answer 404 for a symbol that is not in the catalogue, or no longer trades.

    It says the same for both cases on purpose -- the caller could only choose from what was
    suggested, so telling them apart would answer a question nobody is asking.
    """
    return JSONResponse(
        status_code=status.HTTP_404_NOT_FOUND,
        content={"detail": "unknown symbol"},
    )


async def range_is_not_a_window(request: Request, exc: QuoteRangeInvalid) -> JSONResponse:
    """Answer 422 with the code the screen turns into a literal of `COPY.md` (RF-41).

    The body carries a code and no text: what the person reads is the screen's decision.
    """
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
        content={"detail": {"code": "range_invalid"}},
    )


async def range_is_longer_than_the_interval_serves(
    request: Request, exc: QuoteRangeTooLong
) -> JSONResponse:
    """Answer 422 with the interval and its cap, which the text names (RF-45).

    The two numbers travel because the sentence the person reads names both, and they come from
    the service because that is where they are decided: a browser with its own copy of the caps
    would be the same rule written twice.
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


def register_error_handlers(app: FastAPI) -> None:
    """Wire every domain error to the answer it becomes.

    The pairs are written out rather than derived from the functions' annotations: reading a
    signature to decide what a handler is for would be clever, and the list it saves is five
    lines that say exactly what happens.

    The cast is Starlette's signature and not a hole in ours. `add_exception_handler` is typed to
    take a handler of `Exception`, because the registry it writes into holds every handler
    together; each function here declares the error it actually translates -- which is what makes
    `exc.retry_after_seconds` and `exc.interval` type-check inside them -- and that narrower type
    is not assignable to the broader one. Starlette hands each handler the exception class it was
    registered for, so the cast asserts something the framework guarantees.
    """
    app.add_exception_handler(AuthenticationError, cast("ExceptionHandler", credential_refused))
    app.add_exception_handler(RateLimitedError, cast("ExceptionHandler", too_many_attempts))
    app.add_exception_handler(UnknownSymbolError, cast("ExceptionHandler", symbol_not_on_offer))
    app.add_exception_handler(QuoteRangeInvalid, cast("ExceptionHandler", range_is_not_a_window))
    app.add_exception_handler(
        QuoteRangeTooLong,
        cast("ExceptionHandler", range_is_longer_than_the_interval_serves),
    )


__all__ = ["register_error_handlers"]
