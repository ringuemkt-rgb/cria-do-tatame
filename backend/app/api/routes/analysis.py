"""Rotas de simulação para validação rápida de análise técnica."""

from fastapi import APIRouter

from app.analysis.insight_generator import TechnicalInsightEngine
from app.analysis.scoring_engine import ScoringEngine
from app.schemas.analysis import (
    FightEvent,
    MatchContext,
    SimulateAnalysisRequest,
    SimulateAnalysisResponse,
)

router = APIRouter(prefix="/analysis", tags=["analysis"])


@router.post("/simulate", response_model=SimulateAnalysisResponse)
async def simulate_analysis(payload: SimulateAnalysisRequest) -> SimulateAnalysisResponse:
    """Simula pontuação e insights a partir de eventos de grappling enviados pela API."""

    scoring = ScoringEngine(modalidade=payload.modalidade)
    insight_engine = TechnicalInsightEngine()
    insights: list[str] = []

    for evento in payload.eventos:
        scoring.process_event(evento)

        tipo = "submission_attempt" if "mount" in evento.acao else "sweep_success"
        insight = insight_engine.generate(
            FightEvent(tipo=tipo, confianca=evento.confianca, atleta=evento.atleta),
            MatchContext(modalidade=payload.modalidade),
        )
        insights.append(insight)

    snapshot = scoring.snapshot()
    return SimulateAnalysisResponse(
        placar=snapshot["placar"],
        vantagens=snapshot["vantagens"],
        penalidades=snapshot["penalidades"],
        insights=insights,
    )
