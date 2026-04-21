"""Rotas de saúde e readiness."""

from fastapi import APIRouter

from app.core.config import get_settings
from app.schemas.health import HealthResponse

router = APIRouter(prefix="/health", tags=["health"])


@router.get("", response_model=HealthResponse)
async def healthcheck() -> HealthResponse:
    """Verifica se a API está de pé."""

    settings = get_settings()
    return HealthResponse(status="ok", servico=settings.app_name, ambiente=settings.app_env)
