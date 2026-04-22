"""Rotas de modalidade (fallback manual na etapa 2)."""

from fastapi import APIRouter

from app.schemas.modality import ModalityOverrideRequest, ModalityOverrideResponse, utcnow

router = APIRouter(prefix="/modality", tags=["modality"])


@router.post("/override", response_model=ModalityOverrideResponse)
async def override_modality(payload: ModalityOverrideRequest) -> ModalityOverrideResponse:
    """Registra uma modalidade manualmente quando a confiança automática for baixa."""

    return ModalityOverrideResponse(
        mensagem=f"Modalidade manual aplicada com sucesso. Motivo: {payload.motivo}",
        modalidade_aplicada=payload.modality,
        origem="operador_humano",
        timestamp_utc=utcnow(),
    )
