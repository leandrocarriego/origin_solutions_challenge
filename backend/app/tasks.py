"""
Coroutines that outlive a request: started with the application, stopped with it.

A new background task is only a new entry in `run_background_tasks`.
"""

import asyncio
from collections.abc import AsyncGenerator, Callable, Coroutine
from contextlib import asynccontextmanager
from typing import Any

import structlog
from fastapi import FastAPI

from app.modules.stocks import keep_the_catalogue_fresh

BackgroundTask = Callable[[], Coroutine[Any, Any, None]]

_log = structlog.get_logger()


@asynccontextmanager
async def running(*tasks: BackgroundTask) -> AsyncGenerator[None]:
    """Run every task for as long as the block lasts, and stop them all on the way out."""
    started = [asyncio.create_task(task(), name=_name_of(task)) for task in tasks]

    try:
        yield

    # The cancellation is placed in a `finally` block so that it also executes when the
    # application shuts down due to an exception rather than a clean shutdown.
    finally:
        for task_ in started:
            if task_.done():
                _report(task_)

            task_.cancel()

        # `return_exceptions` so one task that refuses to unwind cleanly does not stop the rest
        # from being waited on -- including the `CancelledError` each of them answers with.
        await asyncio.gather(*started, return_exceptions=True)


def _name_of(task: BackgroundTask) -> str:
    """What to call the task in a log line."""
    return getattr(task, "__name__", type(task).__name__)


def _report(task: asyncio.Task[None]) -> None:
    """Say that a background task ended on its own, and why, before it is cancelled."""
    error = task.exception() if not task.cancelled() else None

    _log.warning(
        "background_task_ended_early",
        task=task.get_name(),
        reason=type(error).__name__ if error else "returned",
    )


@asynccontextmanager
async def run_background_tasks(_: FastAPI) -> AsyncGenerator[None]:
    """Everything that outlives a request, for as long as the application does."""
    async with running(keep_the_catalogue_fresh):
        yield


__all__ = ["BackgroundTask", "run_background_tasks", "running"]
