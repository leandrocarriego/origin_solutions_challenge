"""HTTP for `auth`: it translates between the transport and the service."""

from typing import Annotated

from fastapi import APIRouter, Depends, Request

from app.db import SessionDep
from app.modules.auth.schemas import CurrentUserResponse, LoginRequest, LoginResponse
from app.modules.auth.service import authenticate
from app.security import ACCESS_TOKEN_TTL, CurrentUser, create_access_token, get_current_user

router = APIRouter(prefix="/api/auth", tags=["auth"])


@router.post("/login", summary="Exchange a username and a password for a session token")
async def log_in(credential: LoginRequest, request: Request, session: SessionDep) -> LoginResponse:
    """Answer a session token, or let the service's refusal."""
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
    """Answer the identity the token carries, without reading anything."""
    return CurrentUserResponse(id=current_user.id, full_name=current_user.full_name)


def _client_address(request: Request) -> str:
    """Where the request came from, read in one place and never out of a header."""
    return request.client.host if request.client else "unknown"
