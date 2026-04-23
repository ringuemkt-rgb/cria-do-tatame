"""Rotas de saúde e readiness."""

import time

from fastapi import APIRouter, status
from fastapi.responses import JSONResponse

from app.core.config import get_settings
from app.schemas.health import HealthLiveResponse, HealthReadyResponse
from app.services.health_checks import run_readiness_checks

router = APIRouter(prefix="/health", tags=["health"])

_READY_CACHE: dict[str, object] = {"expires_at": 0.0, "payload": None, "status_code": 503}
_READY_TTL_SECONDS = 2.0


@router.get("/live", response_model=HealthLiveResponse)
@router.get("", response_model=HealthLiveResponse, include_in_schema=False)
async def liveness() -> HealthLiveResponse:
    """Valida se o processo da API está ativo."""

    settings = get_settings()
    return HealthLiveResponse(servico=settings.app_name, ambiente=settings.app_env)


@router.get("/ready", response_model=HealthReadyResponse)
async def readiness() -> JSONResponse:
    """Valida prontidão de dependências antes de receber tráfego pesado."""

    now = time.monotonic()
    if _READY_CACHE["payload"] is not None and now < float(_READY_CACHE["expires_at"]):
        return JSONResponse(status_code=int(_READY_CACHE["status_code"]), content=_READY_CACHE["payload"])  # type: ignore[arg-type]

    settings = get_settings()
    checks = await run_readiness_checks(settings)
    ready = all(item.status == "ok" for item in checks)
    payload = HealthReadyResponse(
        status="ok" if ready else "degradado",
        servico=settings.app_name,
        ambiente=settings.app_env,
        dependencias=checks,
    ).model_dump()

    status_code = status.HTTP_200_OK if ready else status.HTTP_503_SERVICE_UNAVAILABLE
    _READY_CACHE.update({"expires_at": now + _READY_TTL_SECONDS, "payload": payload, "status_code": status_code})

    return JSONResponse(status_code=status_code, content=payload)
