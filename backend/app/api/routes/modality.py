"""Rotas de modalidade (fallback manual na etapa 2)."""

from fastapi import APIRouter

from app.schemas.modality import ModalityOverrideRequest, ModalityOverrideResponse

router = APIRouter(prefix="/modality", tags=["modality"])


@router.post("/override", response_model=ModalityOverrideResponse)
async def override_modality(payload: ModalityOverrideRequest) -> ModalityOverrideResponse:
    """Registra uma modalidade manualmente quando a confiança automática for baixa."""

    return ModalityOverrideResponse(
        mensagem="Modalidade manual aplicada com sucesso.",
        modalidade_aplicada=payload.modality,
    )
