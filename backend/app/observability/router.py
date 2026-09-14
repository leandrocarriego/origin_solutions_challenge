"""The endpoint Prometheus scrapes."""

from fastapi import APIRouter
from prometheus_client import CONTENT_TYPE_LATEST, generate_latest
from starlette.responses import PlainTextResponse, Response

# No prefix and no tag: `/metrics` is not part of our API, and `include_in_schema=False` below
# keeps it out of the OpenAPI so it never reaches the generated frontend types.
router = APIRouter()


@router.get("/metrics", include_in_schema=False)
async def metrics_endpoint() -> Response:
    """Expose the registry in Prometheus text format.

    A `Response` already built, which FastAPI hands back untouched: what Prometheus reads is a
    text format of its own, and there is no model to serialise.
    """
    return PlainTextResponse(generate_latest(), media_type=CONTENT_TYPE_LATEST)
