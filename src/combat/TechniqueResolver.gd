extends Node
class_name TechniqueResolver

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

func resolver_tecnica(technique_id: String, actor: Dictionary, defender: Dictionary, state_machine: Node, context: Dictionary = {}) -> Dictionary:
	var technique: Dictionary = DataRegistry.get_technique(technique_id)
	if technique.is_empty():
		return _erro(technique_id, "tecnica_nao_encontrada")
	return resolve_technique(technique, actor, defender, _contexto_com_estado(state_machine, context))

func resolve_technique(technique: Dictionary, actor: Dictionary, defender: Dictionary, context: Dictionary = {}) -> Dictionary:
	var technique_id: String = str(technique.get("id", "unknown"))
	var current_state: String = str(context.get("state", context.get("estado", "PLAYER_STANDING_NEUTRAL")))
	var entry_state: String = str(technique.get("entry_state", technique.get("estado_entrada", "")))
	var exit_state: String = str(technique.get("exit_state", technique.get("estado_saida", current_state)))
	var state_allowed: bool = entry_state == "" or entry_state == current_state
	var cost: Dictionary = _custo(technique)
	var can_pay: bool = _pode_pagar(actor, cost)
	var chance: float = _calcular_chance(technique, actor, defender, state_allowed, can_pay)
	var success: bool = state_allowed and can_pay and rng.randf() <= chance
	var effects: Dictionary = _efeitos(technique, success)
	return {
		"technique_id": technique_id,
		"nome": technique.get("nome", technique.get("name", technique_id)),
		"success": success,
		"state_allowed": state_allowed,
		"can_pay": can_pay,
		"entry_state": entry_state,
		"current_state": current_state,
		"state_from": current_state,
		"state_to": exit_state if success else current_state,
		"exit_state": exit_state if success else current_state,
		"chance": chance,
		"cost": cost,
		"effects": effects,
		"family": technique.get("family", technique.get("familia", "geral")),
		"message": _mensagem(technique, success, state_allowed, can_pay)
	}

func aplicar_resultado(actor: Dictionary, defender: Dictionary, result: Dictionary) -> Dictionary:
	var actor_out: Dictionary = actor.duplicate(true)
	var defender_out: Dictionary = defender.duplicate(true)
	var cost: Dictionary = result.get("cost", {})
	_actor_delta(actor_out, "gas", -float(cost.get("gas", 0)))
	_actor_delta(actor_out, "focus", -float(cost.get("focus", 0)))
	_actor_delta(actor_out, "moral", -float(cost.get("moral", 0)))
	if bool(result.get("success", false)):
		var effects: Dictionary = result.get("effects", {})
		_actor_delta(actor_out, "control", float(effects.get("actor_control", 0)))
		_actor_delta(actor_out, "guard", float(effects.get("actor_guard", 0)))
		_actor_delta(defender_out, "grip_integrity", float(effects.get("defender_grip_integrity", 0)))
		_actor_delta(defender_out, "gas", float(effects.get("defender_gas", 0)))
		_actor_delta(defender_out, "focus", float(effects.get("defender_focus", 0)))
		_actor_delta(defender_out, "guard", float(effects.get("defender_guard", 0)))
		_actor_delta(defender_out, "health", float(effects.get("defender_health", 0)))
		_actor_delta(defender_out, "control", float(effects.get("defender_control", 0)))
	return {"actor": actor_out, "defender": defender_out}

func _contexto_com_estado(state_machine: Node, context: Dictionary) -> Dictionary:
	var copy: Dictionary = context.duplicate(true)
	if state_machine != null and state_machine.has_method("get_current_state_name"):
		copy["state"] = state_machine.call("get_current_state_name")
	return copy

func _custo(technique: Dictionary) -> Dictionary:
	var cost: Dictionary = technique.get("cost", technique.get("custo", {}))
	return {
		"gas": maxf(0.0, float(cost.get("gas", technique.get("gas_cost", 0)))),
		"focus": maxf(0.0, float(cost.get("focus", cost.get("foco", technique.get("focus_cost", 0))))),
		"moral": maxf(0.0, float(cost.get("moral", technique.get("moral_cost", 0))))
	}

func _efeitos(technique: Dictionary, success: bool) -> Dictionary:
	var normalized: Dictionary = {
		"actor_control": 0.0,
		"actor_guard": 0.0,
		"defender_grip_integrity": 0.0,
		"defender_gas": 0.0,
		"defender_focus": 0.0,
		"defender_guard": 0.0,
		"defender_health": 0.0,
		"defender_control": 0.0
	}
	if not success:
		return normalized
	var raw: Dictionary = technique.get("effects", technique.get("efeitos", {}))
	for key_value in raw.keys():
		var key: String = str(key_value)
		var value: float = float(raw[key_value])
		match key:
			"self_control_meter", "self_control_bonus", "control_gain":
				normalized["actor_control"] += absf(value)
			"self_guarda", "self_guard_bonus":
				normalized["actor_guard"] += absf(value)
			"opponent_grip_integrity", "opponent_grip_reduction", "grip_damage":
				normalized["defender_grip_integrity"] -= absf(value)
			"opponent_gas", "opponent_gas_reduction":
				normalized["defender_gas"] -= absf(value)
			"opponent_foco", "opponent_focus_reduction":
				normalized["defender_focus"] -= absf(value)
			"opponent_guarda", "opponent_guard_reduction":
				normalized["defender_guard"] -= absf(value)
			"opponent_hp", "opponent_hp_reduction":
				normalized["defender_health"] -= absf(value)
			"opponent_control_meter", "opponent_control_reduction":
				normalized["defender_control"] -= absf(value)
	if is_zero_approx(float(normalized["defender_grip_integrity"])) and technique.has("grip_damage"):
		normalized["defender_grip_integrity"] = -absf(float(technique.get("grip_damage", 0)))
	if is_zero_approx(float(normalized["actor_control"])) and technique.has("control_gain"):
		normalized["actor_control"] = absf(float(technique.get("control_gain", 0)))
	return normalized

func _pode_pagar(actor: Dictionary, cost: Dictionary) -> bool:
	return (
		float(actor.get("gas", 0)) >= float(cost.get("gas", 0))
		and float(actor.get("focus", 0)) >= float(cost.get("focus", 0))
		and float(actor.get("moral", 100)) >= float(cost.get("moral", 0))
	)

func _calcular_chance(technique: Dictionary, actor: Dictionary, defender: Dictionary, state_allowed: bool, can_pay: bool) -> float:
	var score: float = float(technique.get("base_chance", technique.get("chance_sucesso", 0.55)))
	score += (float(actor.get("focus", 50)) - 50.0) * 0.004
	score += (float(actor.get("grip", 50)) - 50.0) * 0.003
	score += (float(actor.get("control", 50)) - 50.0) * 0.003
	score += (float(actor.get("gas", 50)) - 50.0) * 0.002
	score -= (float(defender.get("focus", 50)) - 50.0) * 0.003
	score -= (float(defender.get("guard", 50)) - 50.0) * 0.002
	if not state_allowed:
		score -= 0.30
	if not can_pay:
		score -= 0.35
	return clampf(score, 0.05, 0.95)

func _actor_delta(target: Dictionary, key: String, delta: float) -> void:
	var current: float = float(target.get(key, 0.0))
	target[key] = clampf(current + delta, 0.0, 100.0)

func _mensagem(technique: Dictionary, success: bool, state_allowed: bool, can_pay: bool) -> String:
	if not state_allowed:
		return "estado_posicional_incorreto"
	if not can_pay:
		return "recurso_insuficiente"
	if success:
		return str(technique.get("success_text", "%s encaixou." % technique.get("nome", technique.get("name", "Tecnica"))))
	return str(technique.get("defended_text", "%s foi defendida." % technique.get("nome", technique.get("name", "Tecnica"))))

func _erro(technique_id: String, reason: String) -> Dictionary:
	return {
		"technique_id": technique_id,
		"success": false,
		"error": reason,
		"message": reason,
		"state_to": "PLAYER_STANDING_NEUTRAL",
		"cost": {},
		"effects": {}
	}
