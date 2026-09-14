"""What happens to a domain error nobody wrote a handler for.

Every error of `app/errors.py` has its own line in `register_error_handlers`, and the integration
tests of each feature exercise those. This file is about the one case none of them can reach: a
`DomainError` subclass that exists and was never registered.

It is reachable by forgetting a single line, and forgetting it is silent -- the error is raised
from the service, no test of that feature fails, and what the caller gets is a 500 carrying a
traceback. Starlette resolves a handler by walking the exception's MRO, so a handler on the root
is what turns that into an answer instead of a crash.
"""

import pytest
from fastapi import FastAPI
from httpx import ASGITransport, AsyncClient

from app.error_handlers import register_error_handlers
from app.errors import DomainError, UnknownSymbolError


class RuleNobodyTranslated(DomainError):
    """A domain error added without its line in `register_error_handlers`."""


def _app_that_raises(error: DomainError) -> FastAPI:
    """A one-route application whose handlers are the real ones."""
    app = FastAPI()
    register_error_handlers(app)

    @app.get("/boom")
    async def boom() -> None:
        raise error

    return app


async def _get(app: FastAPI) -> tuple[int, object]:
    """Call the route, with no server and no socket."""
    transport = ASGITransport(app=app, raise_app_exceptions=False)

    async with AsyncClient(transport=transport, base_url="http://testserver") as client:
        response = await client.get("/boom")

    return response.status_code, response.json()


class TestAnUnregisteredDomainErrorIsStillAnswered:
    """The root handler, which is the one nobody remembers to add."""

    async def test_it_answers_five_hundred_instead_of_crashing(self) -> None:
        """A rule nobody translated is a wiring mistake, and 500 is what a mistake is."""
        status_code, _ = await _get(_app_that_raises(RuleNobodyTranslated()))

        assert status_code == 500

    async def test_the_body_says_nothing_about_the_exception(self) -> None:
        """Its message was written for a log, not for an API: it is not a contract."""
        _, body = await _get(_app_that_raises(RuleNobodyTranslated("the symbol is locked")))

        assert body == {"detail": "internal error"}

    async def test_it_is_logged_with_the_type_that_is_missing_a_handler(
        self, captured_logs: list[str]
    ) -> None:
        """Answering quietly would hide the missing line, which is the whole failure."""
        await _get(_app_that_raises(RuleNobodyTranslated()))

        assert any("RuleNobodyTranslated" in line for line in captured_logs)


class TestTheRootDoesNotShadowTheHandlersThatExist:
    """Registering the root must not turn a 404 into a 500."""

    @pytest.mark.parametrize(
        ("raised", "expected"),
        [(UnknownSymbolError(), 404), (RuleNobodyTranslated(), 500)],
    )
    async def test_the_exact_handler_wins_over_the_root(
        self, raised: DomainError, expected: int
    ) -> None:
        """Starlette walks the MRO, so the registered subclass is found before its base."""
        status_code, _ = await _get(_app_that_raises(raised))

        assert status_code == expected
