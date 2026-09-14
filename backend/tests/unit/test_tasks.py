"""What `running` promises about a background task: it starts, it stops, and it is waited for.

The three assertions are the three ways the cancel-and-wait dance is written wrong. A task that
was never started does nothing and says nothing. A task that was cancelled but not awaited leaves
the process free to exit while it is halfway through a database session. And a `CancelledError`
that escapes turns a clean shutdown into a crash in the logs.

The tasks here are not the catalogue: they are coroutines that record what happened to them,
because what is under test is the starting and the stopping, not what any particular task does.
"""

import asyncio

import pytest

from app.tasks import running


class _Recorder:
    """A background task that says how far it got before it was stopped."""

    def __init__(self) -> None:
        self.started = False
        self.cancelled = False
        self.cleaned_up = False

    async def __call__(self) -> None:
        """Run until cancelled, and record the cancellation on the way out."""
        self.started = True
        try:
            await asyncio.Event().wait()
        except asyncio.CancelledError:
            self.cancelled = True
            # Something that takes a turn of the loop, the way closing a session does: if the
            # block did not wait, this line would not run before the process moved on.
            await asyncio.sleep(0)
            self.cleaned_up = True
            raise


class TestRunning:
    """A task runs for as long as the block, and is stopped and waited for when it ends."""

    async def test_it_starts_the_task(self) -> None:
        """A registry that forgets to start what it was given is the quietest failure of all."""
        task = _Recorder()

        async with running(task):
            await asyncio.sleep(0)
            assert task.started

    async def test_it_cancels_the_task_when_the_block_ends(self) -> None:
        """The task outlives a request, not the application."""
        task = _Recorder()

        async with running(task):
            await asyncio.sleep(0)

        assert task.cancelled

    async def test_it_waits_for_the_task_to_finish_unwinding(self) -> None:
        """Cancelling only asks. What makes the shutdown clean is waiting for the answer."""
        task = _Recorder()

        async with running(task):
            await asyncio.sleep(0)

        assert task.cleaned_up

    async def test_the_cancellation_does_not_escape_as_a_failure(self) -> None:
        """The `CancelledError` was asked for: letting it out would report a crash."""
        task = _Recorder()

        async with running(task):
            await asyncio.sleep(0)

    async def test_it_stops_the_task_when_the_block_raises(self) -> None:
        """An application torn down by an exception must not leak what it started."""
        task = _Recorder()

        with pytest.raises(RuntimeError):
            async with running(task):
                await asyncio.sleep(0)
                raise RuntimeError("the application died")

        assert task.cancelled

    async def test_it_runs_every_task_it_is_given(self) -> None:
        """The point of the registry: a second task is an argument, not a second dance."""
        first, second = _Recorder(), _Recorder()

        async with running(first, second):
            await asyncio.sleep(0)

        assert (first.started, second.started) == (True, True)
        assert (first.cancelled, second.cancelled) == (True, True)


class TestATaskThatEndsOnItsOwn:
    """A background task that is gone looks exactly like one that is working."""

    async def test_it_is_reported(self, captured_logs: list[str]) -> None:
        """An exception in a task nobody awaits is swallowed by the event loop."""

        async def crashes_immediately() -> None:
            """End before anybody asks it to."""
            raise RuntimeError("no loop to survive in")

        async with running(crashes_immediately):
            await asyncio.sleep(0)

        assert any("background_task_ended_early" in line for line in captured_logs)
