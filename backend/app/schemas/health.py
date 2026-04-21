"""Schemas da API de saúde."""

from pydantic import BaseModel


class HealthResponse(BaseModel):
    """Resposta padrão para endpoint de saúde."""

    status: str
    servico: str
    ambiente: str
