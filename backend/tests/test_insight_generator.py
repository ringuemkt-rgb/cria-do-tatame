from app.analysis.insight_generator import TechnicalInsightEngine
from app.schemas.analysis import FightEvent, MatchContext


def test_insight_gera_saida_em_ptbr_com_referencia():
    engine = TechnicalInsightEngine()

    insight = engine.generate(
        FightEvent(
            tipo="submission_attempt",
            confianca=0.9,
            atleta="azul",
            biomecanica_flags=["base estreita"],
        ),
        MatchContext(modalidade="bjj_gi"),
    )

    assert "Referência CBJJ/IBJJF" in insight
    assert "🦴" in insight
