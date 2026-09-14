"""HTTP for `auth`: it translates between the transport and the service, and decides nothing."""

from typing import Annotated

from fastapi import APIRouter, Depends, Request

from app.db import SessionDep
from app.modules.auth.schemas import CurrentUserResponse, LoginRequest, LoginResponse
from app.modules.auth.service import authenticate
from app.security import ACCESS_TOKEN_TTL, CurrentUser, create_access_token, get_current_user

router = APIRouter(prefix="/api/auth", tags=["auth"])


@router.post("/login", summary="Exchange a username and a password for a session token")
async def log_in(credential: LoginRequest, request: Request, session: SessionDep) -> LoginResponse:
    """Answer a session token, or let the service's refusal become a 401 or a 429.

    The username and the password travel to the service exactly as they arrived: normalising them
    is a decision, and decisions are not made here. The address is the exception, and it is not a
    decision either -- it is a property of the transport, so this is the layer that can read it.
    """
    authenticated = await authenticate(
        session,
        username=credential.username,
        password=credential.password,
        client_ip=_client_address(request),
    )

    return LoginResponse(
        access_token=create_access_token(
            user_id=authenticated.id, full_name=authenticated.full_name
        ),
        expires_in=int(ACCESS_TOKEN_TTL.total_seconds()),
        full_name=authenticated.full_name,
    )


@router.get("/me", summary="Who the presented session token identifies")
async def read_current_user(
    current_user: Annotated[CurrentUser, Depends(get_current_user)],
) -> CurrentUserResponse:
    """Answer the identity the token carries, without reading anything.

    A reloaded page calls this to find out whether the token it kept is still good, so it runs
    once per navigation: the claims were already verified, and looking `users` up again would add
    a round trip to confirm what the signature confirmed. A row that changed underneath is not a
    risk worth a query -- the token expires in an hour either way.

    It takes no parameter, so there is no id to substitute.
    """
    return CurrentUserResponse(id=current_user.id, full_name=current_user.full_name)


def _client_address(request: Request) -> str:
    """Where the request came from, read in one place and never out of a header.

    `request.client.host` is the peer of the connection, already resolved by uvicorn from the
    proxy headers it was told to trust and rewritten by nginx to a single value. Reading
    `X-Forwarded-For` here instead would let the caller choose its own key in the attempt
    counter, which is opting out of the limit with a header.

    The fallback covers the case with no peer at all. One shared bucket over-counts rather than
    under-counts, which is the safe direction.
    """
    return request.client.host if request.client else "unknown"
