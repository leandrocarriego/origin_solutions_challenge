"""The health endpoint: what the reverse proxy and the deploy ask the process about itself.

It is a router of the kernel and not a module, and the distinction is the one of Article IV: a
module is justified when a capability of the business appears with a language of its own, and
"health" is not one. Nobody trades it, nobody owns it, and it has no tables.

It is its own file rather than part of `main.py` because it is the only *endpoint* the
application serves outside a module: mixed into the composition root it read as if assembling the
app and answering a request were the same kind of work.
"""

from fastapi import APIRouter, Response, status
from pydantic import BaseModel

from app.db import database_is_up
from app.settings import get_settings

router = APIRouter(tags=["operations"])


class HealthStatus(BaseModel):
    """What health answers.

    Three fields, and none of them derived from configuration: no DSN, no host, no database
    name. A health endpoint that explains how it connects is a map for whoever reads it
    (Article I).
    """

    status: str
    database: str
    version: str


@router.get("/api/health", summary="Process and dependency status")
async def health(response: Response) -> HealthStatus:
    """Answer 200 when the database replies, and 503 when it does not.

    The 503 matters as much as the 200: answering 200 with the database down would keep the
    proxy sending traffic to an instance that can serve nothing.

    The settings are read here and not held at import: this endpoint runs once per probe, the
    lookup is cached, and a module-level copy would be one more thing to keep in step with the
    process it describes.
    """
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
