extends Node
class_name TechniqueResolver

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

func resolver_tecnica(technique_id: String, actor: Dictionary, defender: Dictionary, state_machine: CombatStateMachine, context := {}) -> Dictionary:
	var technique := DataRegistry.get_technique(technique_id)
	if technique.is_empty():
		return _erro(technique_id, "tecnica_nao_encontrada")
	return resolve_technique(technique, actor, defender, _contexto_com_estado(state_machine, context))

func resolve_technique(technique: Dictionary, actor: Dictionary, defender: Dictionary, context: Dictionary = {}) -> Dictionary:
	rng.randomize()
	var technique_id := str(technique.get("id", "unknown"))
	var current_state := str(context.get("state", context.get("estado", "PLAYER_STANDING_NEUTRAL")))
	var entry_state := str(technique.get("entry_state", technique.get("estado_entrada", "")))
	var exit_state := str(technique.get("exit_state", technique.get("estado_saida", current_state)))
	var state_allowed := entry_state == "" or entry_state == current_state
	var cost := _custo(technique)
	var can_pay := _pode_pagar(actor, cost)
	var chance := _calcular_chance(technique, actor, defender, state_allowed, can_pay)
	var success := state_allowed and can_pay and rng.randf() <= chance
	var effects := _efeitos(technique, success)
	return {
		"technique_id": technique_id,
		"nome": technique.get("nome", technique_id),
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
	var actor_out := actor.duplicate(true)
	var defender_out := defender.duplicate(true)
	var cost: Dictionary = result.get("cost", {})
	_actor_delta(actor_out, "gas", -float(cost.get("gas", 0)))
	_actor_delta(actor_out, "focus", -float(cost.get("focus", 0)))
	_actor_delta(actor_out, "moral", -float(cost.get("moral", 0)))
	if result.get("success", false):
		for key in result.get("effects", {}).keys():
			var value := float(result["effects"][key])
			match key:
				"self_control_meter", "self_control_bonus", "control_gain": _actor_delta(actor_out, "control", value)
				"self_guarda", "self_guard_bonus": _actor_delta(actor_out, "guard", value)
				"opponent_grip_integrity", "opponent_grip_reduction", "grip_damage": _actor_delta(defender_out, "grip_integrity", value)
				"opponent_gas", "opponent_gas_reduction": _actor_delta(defender_out, "gas", value)
				"opponent_foco", "opponent_focus_reduction": _actor_delta(defender_out, "focus", value)
				"opponent_guarda", "opponent_guard_reduction": _actor_delta(defender_out, "guard", value)
				"opponent_hp", "opponent_hp_reduction": _actor_delta(defender_out, "health", value)
				"opponent_control_meter", "opponent_control_reduction": _actor_delta(defender_out, "control", value)
	return {"actor": actor_out, "defender": defender_out}

func _contexto_com_estado(state_machine: CombatStateMachine, context: Dictionary) -> Dictionary:
	var c := context.duplicate(true)
	if state_machine != null:
		c["state"] = state_machine.get_current_state_name()
	return c

func _custo(technique: Dictionary) -> Dictionary:
	var cost: Dictionary = technique.get("cost", technique.get("custo", {}))
	return {
		"gas": float(cost.get("gas", technique.get("gas_cost", 0))),
		"focus": float(cost.get("focus", cost.get("foco", technique.get("focus_cost", 0)))),
		"moral": float(cost.get("moral", technique.get("moral_cost", 0)))
	}

func _efeitos(technique: Dictionary, success: bool) -> Dictionary:
	if not success:
		return {}
	var effects: Dictionary = technique.get("effects", technique.get("efeitos", {})).duplicate(true)
	if technique.has("grip_damage"):
		effects["grip_damage"] = -abs(float(technique.get("grip_damage", 0)))
	if technique.has("control_gain"):
		effects["control_gain"] = float(technique.get("control_gain", 0))
	return effects

func _pode_pagar(actor: Dictionary, cost: Dictionary) -> bool:
	return float(actor.get("gas", 0)) >= float(cost.get("gas", 0)) and float(actor.get("focus", 0)) >= float(cost.get("focus", 0)) and float(actor.get("moral", 100)) >= float(cost.get("moral", 0))

func _calcular_chance(technique: Dictionary, actor: Dictionary, defender: Dictionary, state_allowed: bool, can_pay: bool) -> float:
	var score := float(technique.get("base_chance", technique.get("chance_sucesso", 0.55)))
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
	return clamp(score, 0.05, 0.95)

func _actor_delta(target: Dictionary, key: String, delta: float) -> void:
	var current := float(target.get(key, 0.0))
	target[key] = clamp(current + delta, 0.0, 100.0)

func _mensagem(technique: Dictionary, success: bool, state_allowed: bool, can_pay: bool) -> String:
	if not state_allowed:
		return "estado_posicional_incorreto"
	if not can_pay:
		return "recurso_insuficiente"
	if success:
		return str(technique.get("success_text", "%s encaixou." % technique.get("nome", "Tecnica")))
	return str(technique.get("defended_text", "%s foi defendida." % technique.get("nome", "Tecnica")))

func _erro(technique_id: String, reason: String) -> Dictionary:
	return {"technique_id": technique_id, "success": false, "error": reason, "message": reason, "state_to": "PLAYER_STANDING_NEUTRAL", "cost": {}, "effects": {}}
