"""The health endpoint: what the reverse proxy and the deploy ask the process about itself."""

from fastapi import APIRouter, Response, status
from pydantic import BaseModel

from app.db import database_is_up
from app.settings import get_settings

router = APIRouter(tags=["operations"])


class HealthStatus(BaseModel):
    """What health answers."""

    status: str
    database: str
    version: str


@router.get("/api/health", summary="Process and dependency status")
async def health(response: Response) -> HealthStatus:
    database_up = await database_is_up()

    response.status_code = (
        status.HTTP_200_OK if database_up else status.HTTP_503_SERVICE_UNAVAILABLE
    )
    return HealthStatus(
        status="ok" if database_up else "degraded",
        database="ok" if database_up else "unavailable",
        version=get_settings().version,
    )


__all__ = ["HealthStatus", "router"]
