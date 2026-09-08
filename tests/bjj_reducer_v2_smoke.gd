extends SceneTree

const LoaderScript = preload("res://src/combat/BJJGraphLoader.gd")
const ReducerScript = preload("res://src/combat/BJJGraphReducerV2.gd")
const UtilityScript = preload("res://src/ai/BJJUtilityScorerV2.gd")

var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _assert(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("[BJJReducerV2Smoke] " + message)

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

func _run() -> void:
	var loaded: Dictionary = LoaderScript.load_from_path("res://data/bjj/bjj_kg_slice_ruan_davi_v1.json", false)
	_assert(bool(loaded.get("ok", false)), "slice fixture should validate: %s" % str(loaded.get("errors", [])))
	var full_attempt: Dictionary = LoaderScript.load_from_path("res://data/bjj/bjj_kg_slice_ruan_davi_v1.json", true)
	_assert(not bool(full_attempt.get("ok", true)), "slice fixture must fail the full 40/120/10 gate")
	var kg: Dictionary = loaded.get("kg", {})
	var rules := _load_json("res://data/combat/bjj_rulesets_verified_v1.json")
	var reducer = ReducerScript.new(kg, rules)
	_assert(reducer.is_ready(), "reducer should initialize with validated slice fixture")

	var state: Dictionary = reducer.new_state("ibjjf", true, 12345)
	_assert(str(state.get("pos", "")) == "standing_neutral", "new_state must start standing_neutral")
	_assert(int(state.get("top", -1)) == 0, "new_state must start neutral top=0")
	var standing_actions: Array = reducer.available_actions(state, 1)
	_assert(standing_actions.has("t001"), "standing actions must include t001")
	_assert(standing_actions.has("t005"), "standing actions must include t005")

	var counter_state: Dictionary = reducer.reduce(state, {"atk":"t001", "def":"slice_sprawl", "atk_player":1})
	_assert(str(counter_state.get("pos", "")) == "front_headlock", "successful sprawl counter must redirect to front_headlock")
	_assert(int(counter_state.get("top", 0)) == 2, "countering defender must become top")
	_assert(float(counter_state.get("p1", {}).get("gas", 100.0)) == 80.0, "attacker must pay gas on countered attempt")
	_assert(float(counter_state.get("p2", {}).get("gas", 100.0)) == 92.0, "defender must pay gas for attempted counter")

	var deterministic_a: Dictionary = reducer.reduce(state, {"atk":"t005", "def":"", "atk_player":1})
	var deterministic_b: Dictionary = reducer.reduce(state, {"atk":"t005", "def":"", "atk_player":1})
	_assert(deterministic_a == deterministic_b, "same seed and same action must produce identical state")

	var score_state := reducer.new_state("ibjjf", true, 99)
	score_state["pos"] = "side_control"
	score_state["top"] = 1
	score_state = reducer.reduce(score_state, {"atk":"slice_side_to_mount", "def":"", "atk_player":1})
	_assert(str(score_state.get("pos", "")) == "mount_high", "mount transition should move to mount_high")
	_assert(int(score_state.get("p1", {}).get("score", -1)) == 0, "points must not be awarded before stabilization")
	_assert(not score_state.get("pending_score", {}).is_empty(), "mount should create pending score event")
	score_state = reducer.reduce(score_state, {"kind":"stabilize", "player":1, "seconds":3.0})
	_assert(int(score_state.get("p1", {}).get("score", -1)) == 4, "IBJJF mount must score 4 after stabilization")

	var adcc_state := reducer.new_state("adcc", false, 99)
	adcc_state["pos"] = "side_control"
	adcc_state["top"] = 1
	adcc_state = reducer.reduce(adcc_state, {"atk":"slice_side_to_mount", "def":"", "atk_player":1})
	adcc_state = reducer.reduce(adcc_state, {"kind":"stabilize", "player":1, "seconds":3.0})
	_assert(int(adcc_state.get("p1", {}).get("score", -1)) == 2, "ADCC mount must score 2 after stabilization")

	var submission_state := reducer.new_state("ibjjf", true, 77)
	submission_state["pos"] = "mount_high"
	submission_state["top"] = 1
	submission_state = reducer.reduce(submission_state, {"atk":"t057", "def":"", "atk_player":1})
	_assert(int(submission_state.get("winner", 0)) == 1, "successful submission must set winner")

	var gi_leg_state := reducer.new_state("ibjjf", true, 77)
	gi_leg_state["pos"] = "inside_ashi_garami"
	gi_leg_state["top"] = 1
	_assert(not reducer.available_actions(gi_leg_state, 1).has("slice_heel_hook"), "restricted heel hook must be filtered in gi/IBJJF slice")
	var adcc_leg_state := reducer.new_state("adcc", false, 77)
	adcc_leg_state["pos"] = "inside_ashi_garami"
	adcc_leg_state["top"] = 1
	_assert(reducer.available_actions(adcc_leg_state, 1).has("slice_heel_hook"), "heel hook fixture should be available in no-gi ADCC slice")

	var tired_state := reducer.new_state("ibjjf", true, 13)
	tired_state["p1"]["gas"] = 0.0
	_assert(not reducer.available_actions(tired_state, 1).has("t001"), "technique must be blocked when gas is insufficient")
	var before_tick := int(tired_state.get("tick", 0))
	var after_invalid: Dictionary = reducer.reduce(tired_state, {"atk":"t001", "def":"", "atk_player":1})
	_assert(int(after_invalid.get("tick", -1)) == before_tick, "invalid/unaffordable action must not advance replay tick")

	var utility = UtilityScript.new()
	var candidates: Array = reducer.query(state, 1)
	var first_choice := utility.choose(candidates, {})
	var second_choice := utility.choose(candidates, {})
	_assert(first_choice != "", "utility scorer must choose an available technique")
	_assert(first_choice == second_choice, "utility scorer tie-breaking must be deterministic")

	if failures.is_empty():
		print("BJJ REDUCER V2 SMOKE PASS: %d checks" % checks)
		quit(0)
	else:
		push_error("BJJ REDUCER V2 SMOKE FAIL: %d/%d failed" % [failures.size(), checks])
		quit(1)
