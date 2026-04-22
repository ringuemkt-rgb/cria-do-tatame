"""Schemas para monitoramento de saúde da aplicação."""

from pydantic import BaseModel, Field


class DependencyStatus(BaseModel):
    """Estado de uma dependência externa."""

    nome: str
    status: str
    detalhe: str | None = None


class HealthLiveResponse(BaseModel):
    """Resposta de liveness check."""

    status: str = "ok"
    servico: str
    ambiente: str


class HealthReadyResponse(BaseModel):
    """Resposta de readiness check com dependências."""

    status: str
    servico: str
    ambiente: str
    dependencias: list[DependencyStatus] = Field(default_factory=list)
