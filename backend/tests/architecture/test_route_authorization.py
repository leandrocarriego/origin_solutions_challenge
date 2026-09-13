"""Every route decides who may call it, and says so out loud (PY-08, Article III).

There are two halves, and neither replaces the other.

`TestRoutesDeclareAuthorization` reads the application: either the endpoint depends on
something from `app.security` --`get_current_user`, directly or through `require_roles(...)`--
or it is listed below in `PUBLIC_ROUTES` **with the reason written**. The list is the point: a
public endpoint is a decision, and a decision nobody wrote down is an oversight that looks like
one.

`TestRoutesEnforceAuthorization` calls them. A declared dependency that is never reached --
because the router forgot to include it, because a middleware short-circuits earlier-- declares
an authorization that does not happen, and only a request finds that out.

`TestNoRouteAcceptsAUserId` is the static half of Article III: the id of the user whose data is
being touched never arrives in the request. The other half --two users, real rows, one of them
trying to read the other's-- needs endpoints and a database, and belongs to the feature that
builds them (`GEN-09`, `tests/integration/test_user_isolation.py`).
"""

from collections.abc import Iterator
from typing import Any

import pytest
from fastapi import Depends, FastAPI
from fastapi.routing import APIRoute
from httpx import ASGITransport, AsyncClient
from starlette.routing import Route

from app.main import app

# Where the authorization primitives live. `get_current_user` is consumed by the routers of
# every module, so it is not the property of any of them (GEN-03).
SECURITY_MODULE = "app.security"

# FastAPI mounts these on every application it builds, this project's and the throwaway ones
# the checks below are run against. They are a list of their own so both can use them.
DOCUMENTATION_ROUTES: dict[str, str] = {
    "GET /openapi.json": "The contract the frontend generates its types from.",
    "GET /docs": "Swagger UI, which is the OpenAPI document rendered.",
    "GET /docs/oauth2-redirect": "Part of Swagger UI, mounted by FastAPI with it.",
    "GET /redoc": "The same document, rendered by the other viewer FastAPI mounts.",
}

# The routes that answer without asking who is calling, each with the reason it may.
#
# Adding a line here is the act of making an endpoint public. It is meant to be visible in a
# diff, and it is meant to be uncomfortable.
PUBLIC_ROUTES: dict[str, str] = {
    **DOCUMENTATION_ROUTES,
    "GET /api/health": (
        "Traefik and the deploy ask it whether to route traffic here, before there is any "
        "session to authenticate. It answers three fields and none of them come from "
        "configuration (Article I)."
    ),
    "GET /metrics": (
        "Prometheus scrapes it and has no credentials to offer. It is never published through "
        "Traefik: it stays on the internal Docker network, because it names observed symbols "
        "(ADR-009)."
    ),
}

# Names that must never arrive from the path, the query string or the body. The frontend is the
# attacker's: "it always sends its own id" is not a control, it is a hope (Article III).
#
# It is a list of spellings, so `uid` or `id_usuario` would walk past it. This catches the
# obvious shapes; the guarantee is the two-user isolation test that comes with 002.
IDENTITY_PARAMETERS = frozenset({"user_id", "userid", "owner_id", "account_id", "sub"})

# HEAD and OPTIONS are mounted by Starlette alongside GET; they are not decisions anyone made.
IGNORED_METHODS = frozenset({"HEAD", "OPTIONS"})


def _routes(application: FastAPI) -> list[tuple[str, Route | APIRoute]]:
    """Every mounted route as "METHOD /path", one entry per method that is a decision."""
    mounted: list[tuple[str, Route | APIRoute]] = []

    for route in application.routes:
        if not isinstance(route, Route | APIRoute):
            continue
        for method in sorted((route.methods or set()) - IGNORED_METHODS):
            mounted.append((f"{method} {route.path}", route))

    return mounted


def _dependency_calls(dependant: Any) -> Iterator[Any]:
    """Every callable in the dependency tree of an endpoint, however deeply nested."""
    for sub in dependant.dependencies:
        if sub.call is not None:
            yield sub.call
        yield from _dependency_calls(sub)


def _declares_authorization(route: Route | APIRoute) -> bool:
    """Whether anything in the route's dependency tree comes from `app.security`.

    By module and not by name, because `require_roles("admin")` returns a closure whose name is
    not `require_roles`. What matters is where the primitive came from.
    """
    dependant = getattr(route, "dependant", None)
    if dependant is None:
        return False

    return any(
        getattr(call, "__module__", "") == SECURITY_MODULE for call in _dependency_calls(dependant)
    )


def _request_parameters(route: Route | APIRoute) -> set[str]:
    """Every name the route accepts from the path, the query string, the body or a header."""
    dependant = getattr(route, "dependant", None)
    if dependant is None:
        return set()

    names: set[str] = set()
    pending = [dependant]
    while pending:
        current = pending.pop()
        for group in ("path_params", "query_params", "body_params", "header_params"):
            names.update(field.name for field in getattr(current, group, []))
        pending.extend(sub for sub in current.dependencies)

    return names


def _protected_routes(
    application: FastAPI, public: dict[str, str]
) -> list[tuple[str, Route | APIRoute]]:
    """The routes that are supposed to ask who is calling."""
    return [(name, route) for name, route in _routes(application) if name not in public]


def _undeclared(application: FastAPI, public: dict[str, str]) -> list[str]:
    """Routes that neither depend on `app.security` nor appear in the public list."""
    return [
        name
        for name, route in _protected_routes(application, public)
        if not _declares_authorization(route)
    ]


async def _answers_without_credentials(
    application: FastAPI, public: dict[str, str]
) -> dict[str, int]:
    """Call every protected route with no token, and report the ones that answered anyway."""
    answers: dict[str, int] = {}

    transport = ASGITransport(app=application)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        for name, _ in _protected_routes(application, public):
            method, path = name.split(" ", 1)
            response = await client.request(method, path.replace("{", "1").replace("}", ""))
            answers[name] = response.status_code

    return {name: code for name, code in answers.items() if code not in (401, 403)}


class TestRoutesDeclareAuthorization:
    """Every route either depends on `app.security` or is listed public with its reason."""

    def test_every_route_declares_authorization_or_is_listed_public(self) -> None:
        """An endpoint that decides nothing about its caller has decided to trust everyone."""
        undeclared = _undeclared(app, PUBLIC_ROUTES)

        assert undeclared == [], (
            f"these routes neither depend on app.security nor appear in PUBLIC_ROUTES: {undeclared}"
        )

    @pytest.mark.parametrize("name", sorted(PUBLIC_ROUTES))
    def test_every_public_route_carries_a_written_reason(self, name: str) -> None:
        """A blank reason is an endpoint nobody decided to publish."""
        assert PUBLIC_ROUTES[name].strip(), f"{name} is public with no reason written"

    @pytest.mark.parametrize("name", sorted(PUBLIC_ROUTES))
    def test_the_public_list_names_no_route_that_is_gone(self, name: str) -> None:
        """A stale entry silently pre-approves the next route that takes the same path."""
        assert name in dict(_routes(app)), f"{name} is listed public and is not mounted"


class TestRoutesEnforceAuthorization:
    """The declared dependency is actually reached when a request arrives without credentials.

    Vacuous today, and it has to be said: phase 0 has no protected route, so this loop runs
    over an empty list. It stops being vacuous with the first endpoint of `001-authentication`,
    which is the point of having it written before that endpoint exists.
    """

    async def test_a_protected_route_answers_401_or_403_without_a_token(self) -> None:
        """A dependency that is declared and never reached protects nothing."""
        unprotected = await _answers_without_credentials(app, PUBLIC_ROUTES)

        assert unprotected == {}, (
            "these routes declare authorization and answered anyway, with no credentials: "
            f"{unprotected}"
        )


class TestNoRouteAcceptsAUserId:
    """Article III, the half that can be read off the signatures."""

    def test_no_route_takes_the_identity_of_the_user_from_the_request(self) -> None:
        """The id comes from the `sub` of the token, never from the path, query or body."""
        offenders = {
            name: sorted(_request_parameters(route) & IDENTITY_PARAMETERS)
            for name, route in _routes(app)
            if _request_parameters(route) & IDENTITY_PARAMETERS
        }

        assert offenders == {}, (
            "these routes accept the identity of a user as input, which is API1:2023 (BOLA): "
            f"{offenders}"
        )


def _a_primitive_from_the_security_module() -> str:
    """Stand in for `get_current_user`, which phase 0 has not written yet.

    The check asks where a dependency came from, not what it is called, so what makes this a
    stand-in is its `__module__` and nothing else.
    """
    return "someone"


_a_primitive_from_the_security_module.__module__ = SECURITY_MODULE


class TestTheChecksCatchARealViolation:
    """The three checks, run against an application built on purpose to break them.

    Phase 0 mounts two endpoints and both are public, so every assertion above runs over a list
    that is empty or nearly so. These are what say the checks work.
    """

    def test_a_route_that_asks_nobody_anything_is_caught(self) -> None:
        """The failure mode is silence: the endpoint simply answers, to whoever asked."""
        application = FastAPI()

        @application.get("/favorites")
        async def _favorites() -> list[str]:
            """Someone's favourites, handed to anyone who asks."""
            return []

        assert _undeclared(application, DOCUMENTATION_ROUTES) == ["GET /favorites"]

    def test_a_route_that_declares_the_primitive_is_not_reported(self) -> None:
        """The rule is about deciding, not about a particular spelling of the dependency."""
        application = FastAPI()

        @application.get("/favorites")
        async def _favorites(
            who: str = Depends(_a_primitive_from_the_security_module),
        ) -> list[str]:
            """Someone's favourites, for the someone the token names."""
            return []

        assert _undeclared(application, DOCUMENTATION_ROUTES) == []

    def test_a_nested_dependency_still_counts(self) -> None:
        """`require_roles("admin")` wraps the primitive, and wrapping is not evading."""

        def require_roles(who: str = Depends(_a_primitive_from_the_security_module)) -> str:
            """A dependency that depends on the primitive, the way role checks do."""
            return who

        application = FastAPI()

        @application.delete("/users/{identifier}")
        async def _delete(who: str = Depends(require_roles)) -> None:
            """A write under /users, which needs a role and not just a session."""
            return None

        assert _undeclared(application, DOCUMENTATION_ROUTES) == []

    async def test_a_declared_dependency_that_never_refuses_is_caught(self) -> None:
        """Declaring authorization and enforcing it are two different things."""
        application = FastAPI()

        @application.get("/favorites")
        async def _favorites(
            who: str = Depends(_a_primitive_from_the_security_module),
        ) -> list[str]:
            """Declares the dependency, and the dependency lets everyone through."""
            return []

        unprotected = await _answers_without_credentials(application, DOCUMENTATION_ROUTES)

        assert unprotected == {"GET /favorites": 200}

    def test_a_user_id_in_the_path_is_caught(self) -> None:
        """API1:2023, and the easiest one to write without noticing."""
        application = FastAPI()

        @application.get("/users/{user_id}/favorites")
        async def _favorites(user_id: int) -> list[str]:
            """Whoever asks picks whose favourites they get."""
            return []

        found = {
            name: sorted(_request_parameters(route) & IDENTITY_PARAMETERS)
            for name, route in _routes(application)
            if _request_parameters(route) & IDENTITY_PARAMETERS
        }

        assert found == {"GET /users/{user_id}/favorites": ["user_id"]}

    def test_a_user_id_in_the_query_string_is_caught_too(self) -> None:
        """The path is the obvious place; the query string is the one that gets forgotten."""
        application = FastAPI()

        @application.get("/favorites")
        async def _favorites(user_id: int = 0) -> list[str]:
            """Same hole, one layer less visible."""
            return []

        found = _request_parameters(dict(_routes(application))["GET /favorites"])

        assert found & IDENTITY_PARAMETERS == {"user_id"}
