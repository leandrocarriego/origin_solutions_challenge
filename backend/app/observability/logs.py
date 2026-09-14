"""Structured logging: one JSON object per line, and the request id already merged in.

The file is `logs.py` and not `logging.py` on purpose: a module of that name inside this package
reads as the standard library at every glance, and being right about absolute imports does not
make it readable.
"""

import logging
import sys
from typing import Any, TextIO

import structlog


def configure_logging(stream: TextIO | Any | None = None) -> None:
    """Emit one JSON object per line, with the request id already merged in."""
    structlog.configure(
        processors=[
            structlog.contextvars.merge_contextvars,
            structlog.processors.add_log_level,
            structlog.processors.TimeStamper(fmt="iso", utc=True),
            structlog.processors.StackInfoRenderer(),
            structlog.processors.format_exc_info,
            structlog.processors.JSONRenderer(),
        ],
        logger_factory=structlog.PrintLoggerFactory(file=stream or sys.stdout),
        cache_logger_on_first_use=False,
    )
    # Everything that logs through the standard library --uvicorn, sqlalchemy-- goes to the same
    # stream, so a request never spans two formats.
    logging.basicConfig(format="%(message)s", stream=stream or sys.stdout, level=logging.INFO)


def bind_request_id(request_id: str) -> None:
    """Attach an id to everything logged from here on in this context."""
    structlog.contextvars.bind_contextvars(request_id=request_id)


def get_logger(name: str | None = None) -> Any:
    """Return the structured logger every module should use instead of print (ERR-03)."""
    return structlog.get_logger(name)
