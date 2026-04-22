"""Schemas para override manual de modalidade."""

from datetime import datetime, timezone
from typing import Literal

from pydantic import BaseModel, Field


class ModalityOverrideRequest(BaseModel):
    """Payload para forçar modalidade quando detecção inicial for incerta."""

    modality: Literal["boxe", "mma", "bjj_gi", "bjj_nogi"]
    motivo: str = Field(default="confiança baixa na detecção automática")


class ModalityOverrideResponse(BaseModel):
    """Resposta para override aceito."""

    mensagem: str
    modalidade_aplicada: str
    origem: str
    timestamp_utc: datetime


def utcnow() -> datetime:
    return datetime.now(timezone.utc)
