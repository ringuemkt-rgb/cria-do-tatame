class_name GrapplingFatigueModelV1
extends RefCounted

const DIMENSIONS := [
	"systemic",
	"forearm_grip",
	"upper_body_isometric",
	"trunk_isometric",
	"lower_body",
	"recovery_debt"
]

var contract: Dictionary = {}
var profiles: Dictionary = {}
var by_technique: Dictionary = {}
var load_scale: Dictionary = {}
var step_scale := 0.0
var gas_delta_systemic_scale := 0.0
var stabilization_systemic_per_second := 0.0
var stabilization_recovery_debt_per_second := 0.0
var recovery_per_minute: Dictionary = {}

func _init(contract_data: Dictionary = {}, profile_data: Dictionary = {}):
	contract = contract_data.duplicate(true)
	profiles = profile_data.duplicate(true)
	load_scale = contract.get("load_scale", {}).duplicate(true)
	var update: Dictionary = contract.get("shadow_update", {})
	step_scale = float(update.get("authoring_step_scale", 0.0))
	gas_delta_systemic_scale = float(update.get("gas_delta_systemic_scale", 0.0))
	stabilization_systemic_per_second = float(update.get("stabilization_systemic_per_second", 0.0))
	stabilization_recovery_debt_per_second = float(update.get("stabilization_recovery_debt_per_second", 0.0))
	recovery_per_minute = contract.get("recovery_authoring_prior", {}).get("per_minute", {}).duplicate(true)
	for raw_profile in profiles.get("profiles", []):
		if typeof(raw_profile) != TYPE_DICTIONARY:
			continue
		var profile: Dictionary = raw_profile
		var technique_id := str(profile.get("technique_id", ""))
		if technique_id != "":
			by_technique[technique_id] = profile.duplicate(true)

func is_ready() -> bool:
	if str(contract.get("version", "")) != "1.0.0":
		return false
	if str(contract.get("status", "")) != "SHADOW_CALIBRATION_ONLY":
		return false
	if contract.get("dimensions", []) != DIMENSIONS:
		return false
	return step_scale >= 0.0

func new_state(residual_state: Dictionary = {}) -> Dictionary:
	var state := {
		"version": "1.0.0",
		"status": "SHADOW_ONLY",
		"authoritative": false,
		"F3_effect_active": false,
		"p1": _new_athlete_state(),
		"p2": _new_athlete_state(),
		"events_observed": 0,
		"rest_events": 0
	}
	for player_key in ["p1", "p2"]:
		if residual_state.has(player_key) and typeof(residual_state[player_key]) == TYPE_DICTIONARY:
			state[player_key] = _sanitize_athlete_state(residual_state[player_key])
	return state

func observe_step(fatigue_state: Dictionary, before_combat: Dictionary, after_combat: Dictionary, action: Dictionary, outcome_event: Dictionary) -> Dictionary:
	var next := _sanitize_state(fatigue_state)
	if not is_ready():
		return next
	var tick_advanced := int(after_combat.get("tick", 0)) > int(before_combat.get("tick", 0))
	if not tick_advanced:
		return next

	if str(action.get("kind", "technique")) == "stabilize":
		var stabilizing_player := int(action.get("player", 0))
		var seconds := maxf(0.0, float(action.get("seconds", 0.0)))
		if stabilizing_player in [1, 2] and seconds > 0.0:
			_apply_scalar_load(next, stabilizing_player, "systemic", seconds * stabilization_systemic_per_second)
			_apply_scalar_load(next, stabilizing_player, "recovery_debt", seconds * stabilization_recovery_debt_per_second)
			_increment_action_count(next, stabilizing_player)
		next["events_observed"] = int(next.get("events_observed", 0)) + 1
		return next

	var attack_player := int(action.get("atk_player", 0))
	var attack_id := str(action.get("atk", ""))
	if attack_player in [1, 2] and attack_id != "":
		_apply_technique_profile(next, attack_player, attack_id)

	if str(outcome_event.get("ev", "")) == "counter":
		var counter_player := int(outcome_event.get("by", 0))
		var counter_id := str(outcome_event.get("t", ""))
		if counter_player in [1, 2] and counter_id != "":
			_apply_technique_profile(next, counter_player, counter_id)

	# Gas remains reducer authority. The shadow model only observes the paid delta as
	# an additional broad systemic-load signal; it never writes gas back to combat.
	for player in [1, 2]:
		var key := _fighter_key(player)
		var before_fighter: Dictionary = before_combat.get(key, {})
		var after_fighter: Dictionary = after_combat.get(key, {})
		var gas_delta := maxf(0.0, float(before_fighter.get("gas", 0.0)) - float(after_fighter.get("gas", 0.0)))
		if gas_delta > 0.0:
			_apply_scalar_load(next, player, "systemic", gas_delta * gas_delta_systemic_scale)

	next["events_observed"] = int(next.get("events_observed", 0)) + 1
	return next

func rest(fatigue_state: Dictionary, seconds: float) -> Dictionary:
	var next := _sanitize_state(fatigue_state)
	if not is_ready() or seconds <= 0.0:
		return next
	var minutes := seconds / 60.0
	for player_key in ["p1", "p2"]:
		var athlete: Dictionary = next.get(player_key, {}).duplicate(true)
		for dimension in DIMENSIONS:
			var current := clampf(float(athlete.get(dimension, 0.0)), 0.0, 1.0)
			var rate := maxf(0.0, float(recovery_per_minute.get(dimension, 0.0)))
			athlete[dimension] = clampf(current - rate * minutes, 0.0, 1.0)
		next[player_key] = athlete
	next["rest_events"] = int(next.get("rest_events", 0)) + 1
	return next

func projected_effect(_fatigue_state: Dictionary, _player: int) -> Dictionary:
	return {
		"active": false,
		"success_multiplier": 1.0,
		"cost_multiplier": 1.0,
		"reason": "F3_NOT_APPROVED",
		"may_mutate_reducer": false
	}

func profile_for(technique_id: String) -> Dictionary:
	if not by_technique.has(technique_id):
		return {}
	return by_technique[technique_id].duplicate(true)

func coverage(technique_ids: Array) -> Dictionary:
	var missing: Array[String] = []
	for raw_id in technique_ids:
		var technique_id := str(raw_id)
		if technique_id != "" and not by_technique.has(technique_id):
			missing.append(technique_id)
	return {
		"ok": missing.is_empty(),
		"required": technique_ids.size(),
		"mapped": technique_ids.size() - missing.size(),
		"missing": missing
	}

func _apply_technique_profile(state: Dictionary, player: int, technique_id: String) -> void:
	if not by_technique.has(technique_id):
		_record_unresolved_profile(state, player, technique_id)
		_increment_action_count(state, player)
		return
	var profile: Dictionary = by_technique[technique_id]
	var performer_load = profile.get("performer_load", {})
	if typeof(performer_load) != TYPE_DICTIONARY:
		_record_unresolved_profile(state, player, technique_id)
		_increment_action_count(state, player)
		return
	for dimension in DIMENSIONS:
		var level = performer_load.get(dimension, "UNKNOWN")
		if typeof(level) != TYPE_STRING:
			continue
		var level_name := str(level)
		if level_name == "UNKNOWN" or not load_scale.has(level_name) or load_scale[level_name] == null:
			continue
		_apply_scalar_load(state, player, dimension, float(load_scale[level_name]) * step_scale)
	_increment_action_count(state, player)

func _apply_scalar_load(state: Dictionary, player: int, dimension: String, delta: float) -> void:
	if dimension not in DIMENSIONS or player not in [1, 2]:
		return
	var key := _fighter_key(player)
	var athlete: Dictionary = state.get(key, _new_athlete_state()).duplicate(true)
	athlete[dimension] = clampf(float(athlete.get(dimension, 0.0)) + maxf(0.0, delta), 0.0, 1.0)
	state[key] = athlete

func _increment_action_count(state: Dictionary, player: int) -> void:
	var key := _fighter_key(player)
	var athlete: Dictionary = state.get(key, _new_athlete_state()).duplicate(true)
	athlete["actions_observed"] = int(athlete.get("actions_observed", 0)) + 1
	state[key] = athlete

func _record_unresolved_profile(state: Dictionary, player: int, technique_id: String) -> void:
	var key := _fighter_key(player)
	var athlete: Dictionary = state.get(key, _new_athlete_state()).duplicate(true)
	var unresolved: Array = athlete.get("unresolved_profiles", []).duplicate(true)
	if technique_id != "" and technique_id not in unresolved:
		unresolved.append(technique_id)
	athlete["unresolved_profiles"] = unresolved
	state[key] = athlete

func _sanitize_state(value: Dictionary) -> Dictionary:
	var next := new_state()
	if typeof(value) != TYPE_DICTIONARY:
		return next
	for player_key in ["p1", "p2"]:
		if value.has(player_key) and typeof(value[player_key]) == TYPE_DICTIONARY:
			next[player_key] = _sanitize_athlete_state(value[player_key])
	next["events_observed"] = maxi(0, int(value.get("events_observed", 0)))
	next["rest_events"] = maxi(0, int(value.get("rest_events", 0)))
	return next

func _sanitize_athlete_state(value: Dictionary) -> Dictionary:
	var out := _new_athlete_state()
	for dimension in DIMENSIONS:
		out[dimension] = clampf(float(value.get(dimension, 0.0)), 0.0, 1.0)
	out["actions_observed"] = maxi(0, int(value.get("actions_observed", 0)))
	var unresolved = value.get("unresolved_profiles", [])
	out["unresolved_profiles"] = unresolved.duplicate(true) if typeof(unresolved) == TYPE_ARRAY else []
	return out

func _new_athlete_state() -> Dictionary:
	return {
		"systemic": 0.0,
		"forearm_grip": 0.0,
		"upper_body_isometric": 0.0,
		"trunk_isometric": 0.0,
		"lower_body": 0.0,
		"recovery_debt": 0.0,
		"actions_observed": 0,
		"unresolved_profiles": []
	}

func _fighter_key(player: int) -> String:
	return "p1" if player == 1 else "p2"
