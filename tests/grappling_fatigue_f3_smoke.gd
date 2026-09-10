extends SceneTree

const RuntimeScript = preload("res://src/combat/CriaGrapplingRuntimeV1.gd")

var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		push_error("[FatigueF3] " + label)

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

func _runtime(with_fatigue: bool = true):
	var args := [
		_load_json("res://data/bjj/bjj_kg_slice_ruan_davi_v1.json"),
		_load_json("res://data/combat/bjj_rulesets_verified_v1.json"),
		_load_json("res://data/combat/bjj_timing_windows_v1.json"),
		_load_json("res://data/visual/golden_chain_motion_requirements_v1.json"),
		_load_json("res://data/combat/grappling_physical_bindings_slice_v1.json"),
		_load_json("res://data/combat/golden_chain_ruan_davi_v1.json")
	]
	if with_fatigue:
		return RuntimeScript.new(
			args[0], args[1], args[2], args[3], args[4], args[5],
			_load_json("res://data/combat/grappling_fatigue_contract_v1.json"),
			_load_json("res://data/combat/grappling_fatigue_profiles_slice_v1.json")
		)
	return RuntimeScript.new(args[0], args[1], args[2], args[3], args[4], args[5])

func _run() -> void:
	var runtime = _runtime(true)
	var baseline = _runtime(false)
	_check(runtime.is_ready(), "grappling runtime remains ready")
	_check(runtime.fatigue_shadow_ready(), "fatigue shadow initializes")
	var coverage: Dictionary = runtime.fatigue_coverage()
	_check(bool(coverage.get("ok", false)), "golden chain has fatigue authoring profiles")

	var state: Dictionary = runtime.new_match("ibjjf_v6", true, 4)
	_check(state.has("fatigue"), "fatigue state is present only when configured")
	_check(float(state.get("fatigue", {}).get("p1", {}).get("systemic", -1.0)) == 0.0, "new match starts with zero shadow fatigue")
	var baseline_state: Dictionary = baseline.new_match("ibjjf_v6", true, 4)
	_check(not baseline_state.has("fatigue"), "legacy constructor remains compatible without fatigue config")

	var action := {"atk":"t001", "def":"", "atk_player":1}
	var observed: Dictionary = runtime.step(state, action)
	var baseline_result: Dictionary = baseline.step(baseline_state, action)
	_check(observed.get("state", {}).get("combat", {}) == baseline_result.get("state", {}).get("combat", {}), "fatigue observation does not change reducer result")
	_check(not bool(observed.get("authoritative_state_changed_by_fatigue", true)), "fatigue is explicitly non-authoritative")
	var p1_fatigue: Dictionary = observed.get("state", {}).get("fatigue", {}).get("p1", {})
	_check(float(p1_fatigue.get("systemic", 0.0)) > 0.0, "accepted technique records systemic load")
	_check(float(p1_fatigue.get("lower_body", 0.0)) > float(p1_fatigue.get("forearm_grip", 0.0)), "double-leg qualitative profile differentiates local load")
	_check(int(p1_fatigue.get("actions_observed", 0)) == 1, "attack action is counted once")
	var effect: Dictionary = observed.get("fatigue_effect", {})
	_check(not bool(effect.get("active", true)), "F3 effect remains inactive")
	_check(float(effect.get("success_multiplier", 0.0)) == 1.0, "success multiplier remains neutral")
	_check(float(effect.get("cost_multiplier", 0.0)) == 1.0, "cost multiplier remains neutral")

	var after_action: Dictionary = observed.get("state", {})
	var before_rest_combat: Dictionary = after_action.get("combat", {}).duplicate(true)
	var before_rest_lower := float(after_action.get("fatigue", {}).get("p1", {}).get("lower_body", 0.0))
	var rested: Dictionary = runtime.rest_fatigue(after_action, 120.0)
	_check(rested.get("combat", {}) == before_rest_combat, "recovery event cannot change combat state")
	_check(float(rested.get("fatigue", {}).get("p1", {}).get("lower_body", 1.0)) < before_rest_lower, "explicit rest reduces local fatigue")
	_check(int(rested.get("fatigue", {}).get("rest_events", 0)) == 1, "rest event is counted")

	var carried: Dictionary = runtime.new_match("ibjjf_v6", true, 9, "slice_any", "adult", "touch", rested.get("fatigue", {}))
	_check(float(carried.get("fatigue", {}).get("p1", {}).get("systemic", 0.0)) > 0.0, "residual fatigue can carry into next match")
	_check(int(carried.get("combat", {}).get("p1", {}).get("score", -1)) == 0, "residual fatigue does not carry score")
	_check(float(carried.get("combat", {}).get("p1", {}).get("gas", -1.0)) == 100.0, "V1 residual fatigue does not silently rewrite reducer gas")

	# Counter branch records both the attempted attack and the successful defensive technique.
	var counter_state: Dictionary = runtime.new_match("ibjjf_v6", true, 12345)
	var counter_result: Dictionary = runtime.step(counter_state, {"atk":"t001", "def":"slice_sprawl", "atk_player":1, "defense_elapsed_ms":250.0})
	_check(str(counter_result.get("outcome_event", {}).get("ev", "")) == "counter", "known seed produces counter branch")
	_check(int(counter_result.get("state", {}).get("fatigue", {}).get("p1", {}).get("actions_observed", 0)) == 1, "attacker load persists on countered attempt")
	_check(int(counter_result.get("state", {}).get("fatigue", {}).get("p2", {}).get("actions_observed", 0)) == 1, "successful defender profile is observed")

	# Rejected actions must not create fatigue evidence.
	var invalid_state: Dictionary = runtime.new_match("ibjjf_v6", true, 4)
	var invalid: Dictionary = runtime.step(invalid_state, {"atk":"does_not_exist", "def":"", "atk_player":1})
	_check(not bool(invalid.get("accepted", true)), "invalid action is rejected by reducer")
	_check(int(invalid.get("state", {}).get("fatigue", {}).get("events_observed", -1)) == 0, "rejected action creates no fatigue event")
	_check(float(invalid.get("state", {}).get("fatigue", {}).get("p1", {}).get("systemic", -1.0)) == 0.0, "rejected action creates no load")

	# Same seed/action sequence must reproduce both combat and fatigue state exactly.
	var replay_a: Dictionary = runtime.new_match("ibjjf_v6", true, 4)
	var replay_b: Dictionary = runtime.new_match("ibjjf_v6", true, 4)
	replay_a = runtime.step(replay_a, action).get("state", {})
	replay_b = runtime.step(replay_b, action).get("state", {})
	_check(replay_a == replay_b, "fatigue shadow is deterministic under replay")

	if failures.is_empty():
		print("GRAPPLING_FATIGUE_F3_SMOKE PASS %d/%d" % [checks, checks])
		quit(0)
	else:
		print("GRAPPLING_FATIGUE_F3_SMOKE FAIL %d checks / %d failures" % [checks, failures.size()])
		quit(1)
