"""
Routes for checking status.
"""

from http import HTTPStatus

from fastapi import APIRouter

router = APIRouter()


@router.get("/internal/ready", status_code=HTTPStatus.NO_CONTENT)
async def ready() -> None:
    """
    Service ready after startup
    """


@router.get("/internal/live", status_code=HTTPStatus.NO_CONTENT)
async def live() -> None:
    """
    Service still alive
    """
