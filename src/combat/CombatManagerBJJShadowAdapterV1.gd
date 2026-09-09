class_name CombatManagerBJJShadowAdapterV1
extends RefCounted

const LoaderScript = preload("res://src/combat/BJJGraphLoader.gd")
const ReducerScript = preload("res://src/combat/BJJGraphReducerV2.gd")

const SLICE_PATH := "res://data/bjj/bjj_kg_slice_ruan_davi_v1.json"
const RULES_PATH := "res://data/combat/bjj_rulesets_verified_v1.json"
const TIMING_PATH := "res://data/combat/bjj_timing_windows_v1.json"
const MAP_PATH := "res://data/combat/combat_manager_bjj_shadow_map_v1.json"

var reducer
var shadow_state: Dictionary = {}
var mapping: Dictionary = {}
var validation_errors: Array[String] = []
var initialized := false

func initialize(
	seed: int = 260909,
	ruleset: String = "ibjjf_v6",
	gi: bool = true,
	input_profile: String = "touch"
) -> Dictionary:
	validation_errors.clear()
	mapping = _load_json(MAP_PATH)
	if mapping.is_empty():
		validation_errors.append("shadow_map_missing_or_invalid")
		return _status()
	var authority: Dictionary = mapping.get("authority", {})
	if bool(authority.get("shadow_may_change_live_combat", true)):
		validation_errors.append("shadow_adapter_must_not_change_live_combat")
	if bool(authority.get("shadow_may_award_score", true)):
		validation_errors.append("shadow_adapter_must_not_award_live_score")
	if bool(authority.get("shadow_may_finish_combat", true)):
		validation_errors.append("shadow_adapter_must_not_finish_live_combat")

	var graph_result: Dictionary = LoaderScript.load_from_path(SLICE_PATH, false)
	if not bool(graph_result.get("ok", false)):
		for value in graph_result.get("errors", []):
			validation_errors.append(str(value))
		return _status()
	var rules_data := _load_json(RULES_PATH)
	var timing_data := _load_json(TIMING_PATH)
	if rules_data.is_empty():
		validation_errors.append("rules_data_missing_or_invalid")
	if timing_data.is_empty():
		validation_errors.append("timing_data_missing_or_invalid")
	if not validation_errors.is_empty():
		return _status()

	reducer = ReducerScript.new(graph_result.get("kg", {}), rules_data, timing_data)
	if not reducer.is_ready():
		validation_errors.append("reducer_not_ready")
		return _status()
	shadow_state = reducer.new_state(ruleset, gi, seed, "slice_any", "adult", input_profile)
	initialized = true
	return _status()

func is_ready() -> bool:
	return initialized and validation_errors.is_empty() and reducer != null and reducer.is_ready()

func reset(seed: int = 260909, ruleset: String = "ibjjf_v6", gi: bool = true, input_profile: String = "touch") -> Dictionary:
	initialized = false
	shadow_state = {}
	reducer = null
	return initialize(seed, ruleset, gi, input_profile)

func sync_from_legacy_state(legacy_state: String) -> Dictionary:
	if not is_ready():
		return {"ok": false, "error": "shadow_not_ready"}
	var row: Dictionary = mapping.get("legacy_state_map", {}).get(legacy_state, {})
	if row.is_empty():
		return {"ok": false, "error": "legacy_state_unmapped", "legacy_state": legacy_state}
	var canonical = row.get("canonical", null)
	var confidence := str(row.get("confidence", "UNKNOWN"))
	if canonical == null or confidence == "AMBIGUOUS":
		return {
			"ok": false,
			"error": "legacy_state_ambiguous",
			"legacy_state": legacy_state,
			"confidence": confidence,
			"reason": str(row.get("reason", ""))
		}
	shadow_state["pos"] = str(canonical)
	match legacy_state:
		"PLAYER_TOP_SIDE", "PLAYER_TOP_MOUNT", "PLAYER_BACK_ATTACK":
			shadow_state["top"] = 1
		"PLAYER_BOTTOM_SIDE", "PLAYER_BOTTOM_MOUNT", "PLAYER_BACK_DEFENSE":
			shadow_state["top"] = 2
		_:
			shadow_state["top"] = 0
	shadow_state["pending_score"] = {}
	return {
		"ok": true,
		"legacy_state": legacy_state,
		"canonical_position": str(canonical),
		"confidence": confidence,
		"top": int(shadow_state.get("top", 0))
	}

func compare_action_availability(legacy_action_id: String, actor_player: int = 1) -> Dictionary:
	if not is_ready():
		return {"ok": false, "error": "shadow_not_ready"}
	var row: Dictionary = mapping.get("legacy_action_map", {}).get(legacy_action_id, {})
	if row.is_empty():
		return {
			"ok": true,
			"mapped": false,
			"legacy_action_id": legacy_action_id,
			"policy": "REPORT_UNMAPPED_AND_DO_NOT_GUESS"
		}
	var canonical_id := str(row.get("canonical", ""))
	var available: Array = reducer.available_actions(shadow_state, actor_player)
	return {
		"ok": true,
		"mapped": true,
		"legacy_action_id": legacy_action_id,
		"canonical_action_id": canonical_id,
		"canonical_available": available.has(canonical_id),
		"canonical_position_before": str(shadow_state.get("pos", "")),
		"known_delta": str(row.get("known_delta", "")),
		"mapping_confidence": str(row.get("confidence", "UNKNOWN"))
	}

func observe_legacy_action(
	legacy_action_id: String,
	actor_player: int = 1,
	legacy_state_before: String = "",
	defense_legacy_action_id: String = "",
	defense_elapsed_ms: float = 0.0
) -> Dictionary:
	if not is_ready():
		return {"ok": false, "error": "shadow_not_ready"}
	var row: Dictionary = mapping.get("legacy_action_map", {}).get(legacy_action_id, {})
	if row.is_empty():
		return {
			"ok": true,
			"observed": false,
			"reason": "legacy_action_unmapped",
			"legacy_action_id": legacy_action_id
		}
	if legacy_state_before != "":
		var expected_legacy_from := str(row.get("legacy_from", ""))
		if expected_legacy_from != "" and expected_legacy_from != legacy_state_before:
			return {
				"ok": true,
				"observed": false,
				"reason": "legacy_entry_state_mismatch",
				"legacy_action_id": legacy_action_id,
				"expected_legacy_from": expected_legacy_from,
				"actual_legacy_from": legacy_state_before
			}
	var canonical_id := str(row.get("canonical", ""))
	var available: Array = reducer.available_actions(shadow_state, actor_player)
	if not available.has(canonical_id):
		return {
			"ok": true,
			"observed": false,
			"reason": "canonical_action_not_available",
			"legacy_action_id": legacy_action_id,
			"canonical_action_id": canonical_id,
			"shadow_position": str(shadow_state.get("pos", "")),
			"available": available
		}

	var defense_canonical := ""
	if defense_legacy_action_id != "":
		var defense_row: Dictionary = mapping.get("legacy_action_map", {}).get(defense_legacy_action_id, {})
		defense_canonical = str(defense_row.get("canonical", ""))
	var before := shadow_state.duplicate(true)
	var action := {
		"kind": "technique",
		"atk": canonical_id,
		"atk_player": actor_player,
		"def": defense_canonical,
		"defense_elapsed_ms": maxf(0.0, defense_elapsed_ms)
	}
	var after: Dictionary = reducer.reduce(shadow_state, action)
	shadow_state = after.duplicate(true)
	var log: Array = after.get("log", [])
	var last_event: Dictionary = log[-1] if not log.is_empty() and typeof(log[-1]) == TYPE_DICTIONARY else {}
	return {
		"ok": true,
		"observed": true,
		"authoritative": false,
		"legacy_action_id": legacy_action_id,
		"canonical_action_id": canonical_id,
		"defense_canonical_action_id": defense_canonical,
		"shadow_before": _compact_state(before),
		"shadow_after": _compact_state(after),
		"last_event": last_event,
		"known_delta": str(row.get("known_delta", "")),
		"legacy_expected_to": str(row.get("legacy_to", "")),
		"canonical_expected_to": str(row.get("canonical_to", ""))
	}

func snapshot() -> Dictionary:
	return shadow_state.duplicate(true)

func _compact_state(value: Dictionary) -> Dictionary:
	return {
		"pos": str(value.get("pos", "")),
		"top": int(value.get("top", 0)),
		"tick": int(value.get("tick", 0)),
		"winner": int(value.get("winner", 0)),
		"pending_score": value.get("pending_score", {}).duplicate(true),
		"p1": value.get("p1", {}).duplicate(true),
		"p2": value.get("p2", {}).duplicate(true)
	}

func _status() -> Dictionary:
	return {
		"ok": validation_errors.is_empty() and initialized,
		"initialized": initialized,
		"authoritative": false,
		"errors": validation_errors.duplicate()
	}

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}
