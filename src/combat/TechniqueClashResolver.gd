extends Node
class_name TechniqueClashResolver

const OUTCOME_UNMODIFIED := "unmodified"
const OUTCOME_CRITICAL_ADVANTAGE := "critical_advantage"
const OUTCOME_ADVANTAGE := "advantage"
const OUTCOME_CONTESTED := "contested"
const OUTCOME_COUNTER_WINDOW := "counter_window"

# Resolve especialização técnica sem substituir posição, custo ou timing.
# O resultado altera probabilidade e janela de pressão; nunca força lesão ou vitória.
func resolve_clash(
	attack_card: Dictionary,
	defense_card: Dictionary,
	attacker: Dictionary,
	defender: Dictionary,
	technique: Dictionary,
	context: Dictionary = {}
) -> Dictionary:
	if attack_card.is_empty():
		return _unmodified()

	var attack_level: int = clampi(int(attack_card.get("level", 1)), 1, 5)
	var defense_level: int = clampi(int(defense_card.get("level", 1)), 1, 5)
	var attack_score := _attack_score(attack_card, attacker, context)
	var defense_score := _defense_score(defense_card, defender, context)
	var level_gap := attack_level - defense_level
	var defense_efficiency := 1.0
	if level_gap >= 2:
		defense_efficiency = 0.50
		defense_score *= defense_efficiency
	elif level_gap <= -2:
		defense_efficiency = 1.15
		defense_score *= defense_efficiency

	var delta := attack_score - defense_score
	var outcome := OUTCOME_CONTESTED
	var chance_modifier := 0.03
	var submission_advantage := 0.50
	var counter_opening := false

	if delta > 15.0:
		outcome = OUTCOME_CRITICAL_ADVANTAGE
		chance_modifier = 0.25
		submission_advantage = 0.75
	elif delta >= 5.0:
		outcome = OUTCOME_ADVANTAGE
		chance_modifier = 0.12
		submission_advantage = 0.62
	elif delta < 0.0:
		outcome = OUTCOME_COUNTER_WINDOW
		chance_modifier = -0.18
		submission_advantage = 0.42
		counter_opening = true

	# A diferença de estudo é relevante, mas permanece limitada pelo estado real.
	if level_gap >= 2:
		chance_modifier += 0.10
	elif level_gap <= -2:
		chance_modifier -= 0.08

	return {
		"enabled": true,
		"attack_card_id": str(attack_card.get("id", "")),
		"defense_card_id": str(defense_card.get("id", "baseline_defense")),
		"attack_level": attack_level,
		"defense_level": defense_level,
		"level_gap": level_gap,
		"attack_score": snappedf(attack_score, 0.01),
		"defense_score": snappedf(defense_score, 0.01),
		"defense_efficiency": defense_efficiency,
		"delta": snappedf(delta, 0.01),
		"outcome": outcome,
		"chance_modifier": clampf(chance_modifier, -0.30, 0.35),
		"submission_advantage": submission_advantage,
		"counter_opening": counter_opening,
		"technical_finish_allowed": _is_submission_context(technique, context),
		"instant_finish": false
	}

func build_baseline_defense(technique: Dictionary, defender: Dictionary) -> Dictionary:
	var control := float(defender.get("control", 50.0))
	var guard := float(defender.get("guard", 50.0))
	var estimated_level := clampi(1 + int(maxf(control, guard) / 35.0), 1, 3)
	return {
		"id": "baseline_defense_%s" % str(technique.get("id", "technique")),
		"level": estimated_level,
		"base_power": 8.0,
		"kind": "passive",
		"category": "defesa"
	}

func _attack_score(card: Dictionary, actor: Dictionary, context: Dictionary) -> float:
	return (
		float(card.get("base_power", 10.0))
		+ float(card.get("level", 1)) * 4.0
		+ float(actor.get("control", 50.0)) * 0.20
		+ float(actor.get("focus", 50.0)) * 0.08
		+ float(actor.get("grip", 50.0)) * 0.06
		+ clampf(float(context.get("input_quality", 0.5)), 0.0, 1.0) * 4.0
	)

func _defense_score(card: Dictionary, defender: Dictionary, context: Dictionary) -> float:
	return (
		float(card.get("base_power", 8.0))
		+ float(card.get("level", 1)) * 4.0
		+ float(defender.get("guard", 50.0)) * 0.18
		+ float(defender.get("focus", 50.0)) * 0.08
		+ float(defender.get("control", 50.0)) * 0.08
		+ clampf(float(context.get("defense_timing", 0.5)), 0.0, 1.0) * 4.0
	)

func _is_submission_context(technique: Dictionary, context: Dictionary) -> bool:
	var family := str(technique.get("family", technique.get("familia", "")))
	var state := str(context.get("state", ""))
	return family == "finalizacao" and state in ["PLAYER_SUBMISSION_ATTACK", "PLAYER_BACK_ATTACK", "PLAYER_TOP_MOUNT", "PLAYER_BOTTOM_GUARD"]

func _unmodified() -> Dictionary:
	return {
		"enabled": false,
		"outcome": OUTCOME_UNMODIFIED,
		"delta": 0.0,
		"chance_modifier": 0.0,
		"submission_advantage": 0.50,
		"counter_opening": false,
		"technical_finish_allowed": false,
		"instant_finish": false
	}
