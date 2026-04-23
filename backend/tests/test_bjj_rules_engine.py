from app.analysis.rules.bjj_rules_engine import BJJRulesEngine
from app.schemas.analysis import GrapplingAction


def test_deve_pontuar_queda_no_gi():
    engine = BJJRulesEngine("gi")
    action = GrapplingAction(atleta="azul", acao="takedown", duracao_ms=1200, confianca=0.9)

    result = engine.validate_action(action)

    assert result["valid"] is True
    assert result["points"] == 2
    assert result["penalty"] is None


def test_deve_penalizar_pegada_irregular_no_nogi():
    engine = BJJRulesEngine("nogi")
    action = GrapplingAction(atleta="branco", acao="illegal_grip", duracao_ms=500, confianca=0.8)

    result = engine.validate_action(action)

    assert result["valid"] is False
    assert result["penalty"] == "pegada irregular"
