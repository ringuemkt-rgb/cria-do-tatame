from app.analysis.scoring_engine import ScoringEngine
from app.schemas.analysis import GrapplingAction


def test_scoring_engine_soma_pontos_vantagens_e_penalidades():
    engine = ScoringEngine("bjj_gi")

    engine.process_event(GrapplingAction(atleta="azul", acao="guard_pass", duracao_ms=3500, confianca=0.92))
    engine.process_event(GrapplingAction(atleta="azul", acao="near_pass", duracao_ms=3200, confianca=0.8))
    engine.process_event(GrapplingAction(atleta="branco", acao="stalling", duracao_ms=1000, confianca=0.6))

    snapshot = engine.snapshot()

    assert snapshot["placar"]["azul"] == 3
    assert snapshot["vantagens"]["azul"] == 1
    assert snapshot["penalidades"]["branco"] == 1
