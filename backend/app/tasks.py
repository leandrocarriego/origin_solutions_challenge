"""Coroutines that outlive a request: started with the application, stopped with it.

Kernel file, and it knows nothing about what it runs. That is not decoration: `GEN-03` lets only
`main.py` import a module, so a registry that named `keep_the_catalogue_fresh` here would put the
catalogue inside the kernel. It takes what to run as an argument, and the composition root is
what decides -- which also means a second background task is one more argument and not one more
copy of the cancel-and-wait dance below.

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


__all__ = ["BackgroundTask", "running"]
