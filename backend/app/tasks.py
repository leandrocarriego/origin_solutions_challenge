"""Coroutines that outlive a request: started with the application, stopped with it.

This is the second half of the composition root. `main.py` mounts the routers; this names what
runs in the background, and the two are the only files below the modules allowed to import one
(`GEN-03`, and the list of names is pinned by `TestTheExceptionIsDeclared`). A second background
task is a second entry in `run_background_tasks` and nothing else -- not another copy of the
cancel-and-wait dance below.

The split into two functions is the point. `running` is the mechanism and names nothing;
`run_background_tasks` is the list, and it is the only thing here that knows a module exists.

That dance is the whole reason this file exists. `cancel()` only *asks*: it schedules a
`CancelledError` at the task's next await. Without waiting afterwards, the process can exit while
a task is halfway through a database session. And awaiting a cancelled task re-raises the
`CancelledError` that was asked for, so a clean shutdown would look like a crash unless it is
swallowed. Three things to get right, once, instead of once per task.
"""

import asyncio
from collections.abc import AsyncGenerator, Callable, Coroutine
from contextlib import asynccontextmanager
from typing import Any

import structlog
from fastapi import FastAPI

from app.modules.stocks import keep_the_catalogue_fresh

# What can be run in the background: something to call that returns a coroutine. The factory and
# not the coroutine itself, so nothing is created until there is an event loop to create it on.
BackgroundTask = Callable[[], Coroutine[Any, Any, None]]

_log = structlog.get_logger()


@asynccontextmanager
async def running(*tasks: BackgroundTask) -> AsyncGenerator[None]:
    """Run every task for as long as the block lasts, and stop them all on the way out.

    The cancellation is in a `finally`, so it also happens when the application is torn down by
    an exception rather than by a clean shutdown. A task leaked that way would keep a database
    session open for as long as the process took to die.

    A task that ended **before** being asked to is logged. Nothing else can notice: an exception
    inside a task nobody awaits is swallowed by the event loop, and a background task that is
    silently gone looks exactly like one that is working.
    """
    started = [asyncio.create_task(task(), name=_name_of(task)) for task in tasks]

    try:
        yield
    finally:
        for task_ in started:
            if task_.done():
                _report(task_)
            task_.cancel()

        # `return_exceptions` so one task that refuses to unwind cleanly does not stop the rest
        # from being waited on -- including the `CancelledError` each of them answers with, which
        # is the expected end here and not a failure.
        await asyncio.gather(*started, return_exceptions=True)


def _name_of(task: BackgroundTask) -> str:
    """What to call the task in a log line.

    `__name__` is a property of functions, and a `BackgroundTask` is anything callable: a class
    with `__call__`, a `partial`, an object built to carry configuration. Falling back to the type
    keeps the log line useful instead of making the registry refuse a perfectly good task.
    """
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
    """Everything that outlives a request, for as long as the application does.

    This **is** the application's lifespan, handed to `FastAPI(lifespan=...)`, which is why it
    takes an application it never reads: Starlette calls it as `lifespan_context(app)`. A wrapper
    in the composition root that existed only to hide that parameter would be an adapter between
    two things that already fit.

    It has to be the lifespan and not something called earlier: `asyncio.create_task` needs a
    running event loop, and at import time there is none. And the lifespan is also the only place
    that *stops* them -- everything after the `yield` is the shutdown, which is what keeps a task
    from being left holding a database session while the process exits.

    The catalogue refresher is the only one today: `ADR-002` decided the catalogue keeps itself
    current instead of waiting for somebody to remember, and this is where "keeps itself" is
    wired.

    The return type is `AsyncGenerator` and not `AsyncIterator`: this function yields, so it is a
    generator, and annotating `@asynccontextmanager` with the iterator is deprecated.
    """
    async with running(keep_the_catalogue_fresh):
        yield


__all__ = ["BackgroundTask", "run_background_tasks", "running"]
