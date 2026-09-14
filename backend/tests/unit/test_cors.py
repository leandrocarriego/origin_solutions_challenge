"""What CORS announces, and the one value it must never announce.

Two things are fixed here, and they are different in kind.

`TestTheOriginListRefusesAnyOrigin` is about a value that cannot be configured. Starlette does
not refuse `"*"` together with credentials -- it answers the asking origin instead of `"*"`,
which is precisely what a browser needs in order to hand somebody else's session to another
site -- so the refusal has to be ours, and it lives in `Settings`.

`TestTheMiddlewareAnnouncesOnlyWhatExists` is about what the running application answers. It is
written against a preflight and not against the middleware's arguments: reading the arguments
back would assert that the call says what the call says, and would stay green if somebody added
a second `CORSMiddleware` that overrode the first.

Nothing in this application is cross-origin today -- nginx proxies `/api` in production, Vite
proxies it in development -- and that is the reason these exist rather than a reason to skip
them: a setting nobody exercises is a setting nobody notices being widened.
"""

import pytest
from httpx import ASGITransport, AsyncClient, Response
from pydantic import ValidationError

from app.main import app
from app.settings import Settings

_ALLOWED_ORIGIN = "http://localhost:5173"


class TestTheOriginListRefusesAnyOrigin:
    """`"*"` is not a configuration of this project, at any value of any other setting."""

    def test_a_wildcard_origin_is_refused(self) -> None:
        """With credentials enabled it would let any site call the API as the visitor."""
        with pytest.raises(ValidationError):
            Settings(cors_origins=["*"])

    def test_a_wildcard_among_real_origins_is_refused_too(self) -> None:
        """Hidden in a list it reads as one more entry, and it is not: it is all of them."""
        with pytest.raises(ValidationError):
            Settings(cors_origins=["https://origin-solutions-challenge.example", "*"])

    def test_a_named_origin_is_accepted(self) -> None:
        """The rule is about `"*"` and nothing else: a real list is what the setting is for."""
        assert Settings(cors_origins=[_ALLOWED_ORIGIN]).cors_origins == [_ALLOWED_ORIGIN]


class TestTheMiddlewareAnnouncesOnlyWhatExists:
    """A preflight is answered with the three methods the API has, and without credentials."""

    @pytest.fixture
    async def preflight(self) -> Response:
        """What a browser asks before a cross-origin POST.

        Through the ASGI transport and not `TestClient`, which would run the lifespan and start
        the catalogue refresher: this asks the middleware a question, and the answer never
        reaches a route.
        """
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            return await client.options(
                "/api/auth/login",
                headers={
                    "Origin": _ALLOWED_ORIGIN,
                    "Access-Control-Request-Method": "POST",
                    "Access-Control-Request-Headers": "content-type",
                },
            )

    def test_the_asking_origin_is_allowed(self, preflight: Response) -> None:
        """The configured origin is the one the answer names, never `"*"`."""
        assert preflight.headers["access-control-allow-origin"] == _ALLOWED_ORIGIN

    def test_credentials_are_not_allowed(self, preflight: Response) -> None:
        """The session is a bearer token, so no cookie has any business crossing an origin."""
        assert "access-control-allow-credentials" not in preflight.headers

    def test_only_the_methods_the_api_has_are_announced(self, preflight: Response) -> None:
        """PUT and PATCH exist nowhere: announcing them advertises surface that is not there."""
        announced = preflight.headers["access-control-allow-methods"]

        assert {method.strip() for method in announced.split(",")} == {"GET", "POST", "DELETE"}
