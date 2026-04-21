"""Schemas para override manual de modalidade."""

from typing import Literal

from pydantic import BaseModel


class ModalityOverrideRequest(BaseModel):
    """Payload para forçar modalidade quando detecção inicial for incerta."""

    modality: Literal["boxe", "mma", "bjj_gi", "bjj_nogi"]


class ModalityOverrideResponse(BaseModel):
    """Resposta para override aceito."""

    mensagem: str
    modalidade_aplicada: str
