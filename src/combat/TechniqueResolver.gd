extends Node
class_name TechniqueResolver

## Juiz de aresta. Nao substitui CombatManager.
## Fatia ouro: deny na janela, fake antes do commit, chain_id +0.08.

const CHAIN_BONUS := 0.08
const FAKE_COST_RATIO := 0.5
const OVERLAY_PATH := "res://data/techniques/technique_slice_ouro_v1.json"
const SliceStateMapperScript = preload("res://src/combat/SliceStateMapper.gd")

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _mapper = SliceStateMapperScript.new()
var _overlay_by_id: Dictionary = {}
var _overlay_loaded: bool = false

func _ready() -> void:
	rng.randomize()
	_ensure_overlay()

func resolver_tecnica(technique_id: String, actor: Dictionary, defender: Dictionary, state_machine: Node, context: Dictionary = {}) -> Dictionary:
	var registry: Node = get_node_or_null("/root/DataRegistry")
	if registry == null or not registry.has_method("get_technique"):
		return _erro(technique_id, "data_registry_indisponivel")
	var technique: Dictionary = registry.call("get_technique", technique_id)
	if technique.is_empty():
		return _erro(technique_id, "tecnica_nao_encontrada")
	return resolve_technique(technique, actor, defender, _contexto_com_estado(state_machine, context))

func resolve_technique(technique: Dictionary, actor: Dictionary, defender: Dictionary, context: Dictionary = {}) -> Dictionary:
	_ensure_overlay()
	var merged: Dictionary = _merge_overlay(technique)
	var technique_id: String = str(merged.get("id", "unknown"))
	var current_state: String = _mapper.to_runtime(str(context.get("state", context.get("estado", "PLAYER_STANDING_NEUTRAL"))))
	var entry_state: String = _mapper.to_runtime(str(merged.get("entry_state", merged.get("estado_entrada", ""))))
	var exit_state: String = _mapper.to_runtime(str(merged.get("exit_state", merged.get("estado_saida", current_state))))
	var defended_state: String = _mapper.to_runtime(str(merged.get("state_to_defended", current_state)))
	var state_allowed: bool = entry_state == "" or entry_state == current_state
	var cost: Dictionary = _custo(merged)
	var can_pay: bool = _pode_pagar(actor, cost)
	var commit_frame: int = int(merged.get("commit_frame", 0))
	var defense_window: float = float(merged.get("defense_window", 0.0))
	var defense_response: String = SliceStateMapperScript.canonical_technique_id(str(merged.get("defense_response", "")))
	var input_frame: float = float(context.get("frame", context.get("input_frame", 999.0)))
	var defender_input: String = SliceStateMapperScript.canonical_technique_id(str(context.get("defense_input", context.get("defender_input", context.get("defense_response", "")))))
	var released_early: bool = bool(context.get("released_before_commit", context.get("fake", false)))
	var faked: bool = released_early and commit_frame > 0 and input_frame < float(commit_frame)
	if faked:
		var fake_cost: Dictionary = {"gas": cost["gas"] * FAKE_COST_RATIO, "focus": cost["focus"] * FAKE_COST_RATIO, "moral": 0.0}
		return _pack_result(merged, technique_id, current_state, entry_state, current_state, defended_state, state_allowed, can_pay, fake_cost, 0.0, false, false, true, "", 0.0, commit_frame, defense_window, defense_response, context, "fake_cancel")
	var window_frames: float = float(commit_frame) * defense_window
	var in_window: bool = defense_window > 0.0 and commit_frame > 0 and input_frame <= window_frames
	var denied: bool = state_allowed and can_pay and defense_response != "" and defender_input == defense_response and in_window
	if denied:
		return _pack_result(merged, technique_id, current_state, entry_state, defended_state, defended_state, state_allowed, can_pay, cost, 0.0, false, true, false, "", 0.0, commit_frame, defense_window, defense_response, context, "denied")
	var chance: float = _calcular_chance(merged, actor, defender, state_allowed, can_pay)
	var clash: Dictionary = context.get("deck_clash", {})
	var clash_mod: float = float(context.get("chance_modifier", clash.get("modifier", clash.get("m", 0.0))))
	clash_mod = clampf(clash_mod, -0.30, 0.35)
	var chain_id: String = str(merged.get("chain_id", ""))
	var prev_exit: String = _mapper.to_runtime(str(context.get("prev_exit_state", context.get("previous_exit_state", ""))))
	var prev_chain: String = str(context.get("prev_chain_id", ""))
	var chain_bonus: float = 0.0
	if chain_id != "" and prev_chain == chain_id and prev_exit == entry_state:
		chain_bonus = CHAIN_BONUS
	chance = clampf(chance + clash_mod + chain_bonus, 0.05, 0.95)
	var success: bool = state_allowed and can_pay and rng.randf() <= chance
	var state_to: String = current_state
	if success:
		state_to = exit_state
	elif defended_state != "" and defended_state != current_state:
		state_to = defended_state
	var score_event: String = str(merged.get("score_event", "")) if success else ""
	return _pack_result(merged, technique_id, current_state, entry_state, state_to, defended_state, state_allowed, can_pay, cost, chance, success, false, false, score_event, chain_bonus, commit_frame, defense_window, defense_response, context, _mensagem(merged, success, state_allowed, can_pay))

func _pack_result(merged: Dictionary, technique_id: String, current_state: String, entry_state: String, state_to: String, defended_state: String, state_allowed: bool, can_pay: bool, cost: Dictionary, chance: float, success: bool, denied: bool, faked: bool, score_event: String, chain_bonus: float, commit_frame: int, defense_window: float, defense_response: String, context: Dictionary, message: String) -> Dictionary:
	var clash = context.get("deck_clash", {})
	return {
		"technique_id": technique_id,
		"nome": merged.get("nome", merged.get("name", technique_id)),
		"success": success,
		"denied": denied,
		"faked": faked,
		"state_allowed": state_allowed,
		"can_pay": can_pay,
		"entry_state": entry_state,
		"current_state": current_state,
		"state_from": current_state,
		"state_to": state_to,
		"exit_state": state_to,
		"state_to_defended": defended_state,
		"chance": chance,
		"cost": cost,
		"effects": _efeitos(merged, success),
		"family": merged.get("family", merged.get("familia", "geral")),
		"chain_id": str(merged.get("chain_id", "")),
		"chain_bonus": chain_bonus,
		"score_event": score_event,
		"stabilization_seconds": float(merged.get("stabilization_seconds", 0.0)),
		"commit_frame": commit_frame,
		"defense_window": defense_window,
		"defense_response": defense_response,
		"deck_clash": clash.duplicate(true) if typeof(clash) == TYPE_DICTIONARY else {},
		"frame_data": context.get("frame_data", {}).duplicate(true) if typeof(context.get("frame_data", {})) == TYPE_DICTIONARY else {},
		"message": message
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

func _ensure_overlay() -> void:
	if _overlay_loaded:
		return
	_overlay_loaded = true
	if not FileAccess.file_exists(OVERLAY_PATH):
		return
	var file := FileAccess.open(OVERLAY_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	for raw in parsed.get("techniques", []):
		if typeof(raw) != TYPE_DICTIONARY or not raw.has("id"):
			continue
		var tid := str(raw.get("id"))
		_overlay_by_id[tid] = raw
		var alias := str(raw.get("slice_alias", ""))
		if alias != "":
			_overlay_by_id[alias] = raw

func _merge_overlay(technique: Dictionary) -> Dictionary:
	var merged: Dictionary = technique.duplicate(true)
	var tid: String = SliceStateMapperScript.canonical_technique_id(str(technique.get("id", "")))
	var overlay: Dictionary = _overlay_by_id.get(tid, _overlay_by_id.get(str(technique.get("id", "")), {}))
	if overlay.is_empty():
		return merged
	for key in overlay.keys():
		merged[key] = overlay[key]
	return merged

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
		"denied": false,
		"faked": false,
		"error": reason,
		"message": reason,
		"state_to": "PLAYER_STANDING_NEUTRAL",
		"cost": {},
		"effects": {}
	}
