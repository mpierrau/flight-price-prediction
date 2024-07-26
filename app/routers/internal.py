"""
Routes for checking status.
"""

from http import HTTPStatus

from fastapi import APIRouter

router = APIRouter()


@router.get("/ping", status_code=HTTPStatus.NO_CONTENT)
async def ping() -> None:
    """
    Service alive check by SageMaker
    """


@router.get("/internal/ready", status_code=HTTPStatus.NO_CONTENT)
async def ready() -> None:
    """
    Service ready after startup check by Kubernetes
    """


@router.get("/internal/live", status_code=HTTPStatus.NO_CONTENT)
async def live() -> None:
    """
    Service still alive check by Kubernetes
    """
