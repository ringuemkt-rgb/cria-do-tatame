"""Schemas para motor de análise técnica."""

from typing import Literal

from pydantic import BaseModel, Field

Modalidade = Literal["boxe", "mma", "bjj_gi", "bjj_nogi", "unknown"]


class ModalityResult(BaseModel):
    modality: Modalidade
    confidence: float = Field(ge=0.0, le=1.0)
    requires_manual: bool = False


class GrapplingAction(BaseModel):
    atleta: Literal["azul", "branco"]
    acao: Literal[
        "takedown",
        "sweep",
        "guard_pass",
        "knee_on_belly",
        "mount",
        "back_control",
        "near_pass",
        "near_back",
        "near_mount",
        "illegal_grip",
        "stalling",
    ]
    duracao_ms: int = Field(ge=0)
    confianca: float = Field(ge=0.0, le=1.0)


class FightEvent(BaseModel):
    tipo: str
    confianca: float = Field(ge=0.0, le=1.0)
    atleta: Literal["azul", "branco"]
    biomecanica_flags: list[str] = Field(default_factory=list)


class MatchContext(BaseModel):
    modalidade: Modalidade
    biomecanica: dict[str, float] = Field(default_factory=dict)


class SimulateAnalysisRequest(BaseModel):
    modalidade: Literal["bjj_gi", "bjj_nogi"]
    eventos: list[GrapplingAction]


class SimulateAnalysisResponse(BaseModel):
    placar: dict[str, int]
    vantagens: dict[str, int]
    penalidades: dict[str, int]
    insights: list[str]
