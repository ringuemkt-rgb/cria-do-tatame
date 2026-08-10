extends Node
class_name SubmissionExchange

signal exchange_changed(snapshot: Dictionary)
signal exchange_resolved(result: Dictionary)

var config: Dictionary = {}
var anatomy_data: Dictionary = {}
var active: bool = false
var technique_id: String = ""
var attacker_id: String = ""
var defender_id: String = ""
var source_player_state: String = "PLAYER_STANDING_NEUTRAL"
var phase: String = "setup"
var technical_control: float = 0.0
var escape_progress: float = 0.0
var turn_count: int = 0
var outcome: String = ""
var anatomy_record: Dictionary = {}
var rules_context: Dictionary = {}
var safety_profile: Dictionary = {}

func configure(exchange_data: Dictionary, submissions_data: Dictionary) -> void:
	config = exchange_data.duplicate(true)
	anatomy_data = submissions_data.duplicate(true)

func start_exchange(
	p_technique_id: String,
	p_attacker_id: String,
	p_defender_id: String,
	p_source_player_state: String,
	initial_advantage: float,
	context: Dictionary
) -> Dictionary:
	if config.is_empty() or anatomy_data.is_empty():
		return {"ok": false, "error": "submission_data_unavailable"}
	var record := get_anatomy_for_technique(p_technique_id)
	if record.is_empty() or not bool(record.get("runtime_enabled", false)):
		return {"ok": false, "error": "submission_not_runtime_enabled"}
	if not _rules_allow(record, context):
		return {"ok": false, "error": "submission_blocked_by_ruleset"}
	technique_id = p_technique_id
	attacker_id = p_attacker_id
	defender_id = p_defender_id
	source_player_state = p_source_player_state
	anatomy_record = record.duplicate(true)
	rules_context = context.duplicate(true)
	safety_profile = _safety_profile_for(str(context.get("arena_id", "")))
	var rules: Dictionary = config.get("rules", {})
	var initial_min := float(rules.get("initial_control_min", 28.0))
	var initial_max := float(rules.get("initial_control_max", 54.0))
	technical_control = lerpf(initial_min, initial_max, clampf(initial_advantage, 0.0, 1.0))
	escape_progress = 0.0
	turn_count = 0
	outcome = ""
	active = true
	_update_phase()
	_emit_snapshot()
	var snapshot := get_snapshot()
	snapshot["ok"] = true
	return snapshot

func reset_exchange(emit_update: bool = true) -> void:
	active = false
	technique_id = ""
	attacker_id = ""
	defender_id = ""
	source_player_state = "PLAYER_STANDING_NEUTRAL"
	phase = "setup"
	technical_control = 0.0
	escape_progress = 0.0
	turn_count = 0
	outcome = ""
	anatomy_record = {}
	rules_context = {}
	safety_profile = {}
	if emit_update:
		_emit_snapshot()

func get_anatomy_for_technique(p_technique_id: String) -> Dictionary:
	for record_value in anatomy_data.get("records", []):
		if typeof(record_value) != TYPE_DICTIONARY:
			continue
		var record: Dictionary = record_value
		if record.get("technique_ids", []).has(p_technique_id):
			return record.duplicate(true)
	return {}

func get_available_actions(actor_id: String) -> Array:
	if not active:
		return []
	var role := _role_for_actor(actor_id)
	if role == "":
		return []
	var available: Array = []
	for action_value in config.get("actions", []):
		if typeof(action_value) != TYPE_DICTIONARY:
			continue
		var action: Dictionary = action_value
		if str(action.get("role", "")) != role:
			continue
		if not _phase_requirement_met(str(action.get("min_phase", "setup"))):
			continue
		var item: Dictionary = action.duplicate(true)
		item["family"] = "submission_exchange"
		item["category"] = "submission_exchange"
		item["actor_state"] = "PLAYER_SUBMISSION_ATTACK" if role == "attacker" else "PLAYER_SUBMISSION_DEFENSE"
		item["affordable"] = true
		item["ai_priority"] = _ai_priority(str(action.get("id", "")), role)
		available.append(item)
	return available

func apply_action(actor_id: String, action_id: String) -> Dictionary:
	if not active:
		return _action_error(action_id, actor_id, "submission_exchange_inactive")
	var role := _role_for_actor(actor_id)
	if role == "":
		return _action_error(action_id, actor_id, "submission_actor_invalid")
	var action := _find_available_action(actor_id, action_id)
	if action.is_empty():
		return _action_error(action_id, actor_id, "submission_action_unavailable")
	var terminal_outcome := str(action.get("terminal_outcome", ""))
	if terminal_outcome != "":
		return _resolve(terminal_outcome, action_id, actor_id)
	technical_control = clampf(
		technical_control + float(action.get("control_delta", 0.0)),
		0.0,
		float(config.get("rules", {}).get("control_max", 100.0))
	)
	escape_progress = clampf(
		escape_progress + float(action.get("escape_delta", 0.0)),
		0.0,
		float(config.get("rules", {}).get("escape_max", 100.0))
	)
	turn_count += 1
	_update_phase()
	var rules: Dictionary = config.get("rules", {})
	if escape_progress >= float(rules.get("escape_threshold", 100.0)):
		return _resolve("escape", action_id, actor_id)
	if technical_control >= float(rules.get("technical_stop_threshold", 100.0)):
		var safe_outcome := "technical_stop" if bool(safety_profile.get("intervention_enabled", true)) else "tap"
		return _resolve(safe_outcome, action_id, actor_id)
	if turn_count >= int(rules.get("max_turns", 10)):
		return _resolve("time_or_points", action_id, actor_id)
	_emit_snapshot()
	return _build_action_result(action, actor_id, false)

func get_snapshot() -> Dictionary:
	return {
		"active": active,
		"technique_id": technique_id,
		"display_name": str(anatomy_record.get("display_name", technique_id)),
		"attacker_id": attacker_id,
		"defender_id": defender_id,
		"source_player_state": source_player_state,
		"phase": phase,
		"technical_control": technical_control,
		"escape_progress": escape_progress,
		"turn_count": turn_count,
		"outcome": outcome,
		"target_region": str(anatomy_record.get("target_region", "")),
		"mechanism_summary": str(anatomy_record.get("mechanism_summary", "")),
		"response_family": str(anatomy_record.get("gameplay_response_family", "")),
		"intervention_role": str(safety_profile.get("intervention_role", "corner_mediator")),
		"safety_copy": str(anatomy_data.get("safety_contract", {}).get("hud_copy", "Respeite o tap."))
	}

func _find_available_action(actor_id: String, action_id: String) -> Dictionary:
	for action_value in get_available_actions(actor_id):
		if typeof(action_value) == TYPE_DICTIONARY and str(action_value.get("id", "")) == action_id:
			return action_value
	return {}

func _role_for_actor(actor_id: String) -> String:
	if actor_id == attacker_id:
		return "attacker"
	if actor_id == defender_id:
		return "defender"
	return ""

func _update_phase() -> void:
	var next_phase := "setup"
	for phase_value in config.get("phases", []):
		if typeof(phase_value) != TYPE_DICTIONARY:
			continue
		var phase_data: Dictionary = phase_value
		if bool(phase_data.get("terminal", false)):
			continue
		if technical_control >= float(phase_data.get("min_control", 0.0)):
			next_phase = str(phase_data.get("id", next_phase))
	if phase != next_phase:
		phase = next_phase
		SignalBus.submission_phase_changed.emit(StringName(phase))

func _phase_requirement_met(min_phase: String) -> bool:
	return _phase_rank(phase) >= _phase_rank(min_phase)

func _phase_rank(value: String) -> int:
	var order := ["setup", "lock", "technical_pressure", "tap_or_escape", "referee_or_recovery"]
	var index := order.find(value)
	return index if index >= 0 else 0

func _ai_priority(action_id: String, role: String) -> float:
	if action_id == "submission_tap":
		return 95.0 if technical_control >= 86.0 else -45.0
	if role == "defender":
		return 28.0 + escape_progress * 0.25 - technical_control * 0.08
	if action_id == "submission_release":
		return -35.0
	if action_id == "submission_pressure" and _phase_rank(phase) >= _phase_rank("lock"):
		return 38.0
	return 24.0

func _rules_allow(record: Dictionary, context: Dictionary) -> bool:
	var uniform := str(context.get("uniform", "gi"))
	if not record.get("uniforms", []).has(uniform):
		return false
	if str(record.get("competition_gate", "")) == "adult_brown_black_no_gi_only":
		return (
			uniform == "no_gi"
			and str(context.get("age_division", "adult")) == "adult"
			and ["brown", "black"].has(str(context.get("belt", "white")))
		)
	return true

func _safety_profile_for(arena_id: String) -> Dictionary:
	var profiles: Dictionary = config.get("arena_safety_profiles", {})
	return profiles.get(arena_id, profiles.get("default", {"intervention_enabled": true, "intervention_role": "corner_mediator"})).duplicate(true)

func _resolve(resolved_outcome: String, action_id: String, actor_id: String) -> Dictionary:
	outcome = resolved_outcome
	active = false
	phase = "referee_or_recovery"
	SignalBus.submission_phase_changed.emit(StringName(phase))
	var result := {
		"success": true,
		"terminal": true,
		"action_id": action_id,
		"technique_id": technique_id,
		"actor_id": actor_id,
		"attacker_id": attacker_id,
		"defender_id": defender_id,
		"source_player_state": source_player_state,
		"outcome": outcome,
		"message": _outcome_message(outcome),
		"phase": phase,
		"technical_control": technical_control,
		"escape_progress": escape_progress,
		"cost": _action_cost(action_id)
	}
	_emit_snapshot()
	exchange_resolved.emit(result.duplicate(true))
	SignalBus.submission_resolved.emit(result.duplicate(true))
	return result

func _build_action_result(action: Dictionary, actor_id: String, terminal: bool) -> Dictionary:
	return {
		"success": true,
		"terminal": terminal,
		"action_id": str(action.get("id", "")),
		"technique_id": technique_id,
		"name": str(action.get("name", "")),
		"actor_id": actor_id,
		"attacker_id": attacker_id,
		"defender_id": defender_id,
		"message": "troca_tecnica_em_andamento",
		"phase": phase,
		"technical_control": technical_control,
		"escape_progress": escape_progress,
		"cost": action.get("cost", {}).duplicate(true)
	}

func _action_cost(action_id: String) -> Dictionary:
	for action_value in config.get("actions", []):
		if typeof(action_value) == TYPE_DICTIONARY and str(action_value.get("id", "")) == action_id:
			return action_value.get("cost", {}).duplicate(true)
	return {}

func _action_error(action_id: String, actor_id: String, reason: String) -> Dictionary:
	return {"success": false, "action_id": action_id, "actor_id": actor_id, "error": reason, "message": reason}

func _outcome_message(resolved_outcome: String) -> String:
	match resolved_outcome:
		"tap": return "Tap reconhecido. Soltura imediata e respeitosa."
		"escape": return "Defesa criou espaco e recuperou uma posicao segura."
		"release": return "Controle liberado com seguranca."
		"technical_stop": return "Mediacao encerrou a troca por seguranca."
		"time_or_points": return "Tempo da troca encerrado; combate retorna ao controle posicional."
	return "Troca encerrada com seguranca."

func _emit_snapshot() -> void:
	var snapshot := get_snapshot()
	exchange_changed.emit(snapshot.duplicate(true))
	SignalBus.submission_exchange_changed.emit(snapshot.duplicate(true))
