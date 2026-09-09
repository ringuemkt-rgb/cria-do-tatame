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
		push_error("[GoldenChain] " + label)

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

func _runtime():
	return RuntimeScript.new(
		_load_json("res://data/bjj/bjj_kg_slice_ruan_davi_v1.json"),
		_load_json("res://data/combat/bjj_rulesets_verified_v1.json"),
		_load_json("res://data/combat/bjj_timing_windows_v1.json"),
		_load_json("res://data/visual/golden_chain_motion_requirements_v1.json"),
		_load_json("res://data/combat/grappling_physical_bindings_slice_v1.json"),
		_load_json("res://data/combat/golden_chain_ruan_davi_v1.json")
	)

func _run() -> void:
	var runtime = _runtime()
	_check(runtime.is_ready(), "runtime initializes from current reducer authorities")
	var coverage: Dictionary = runtime.motion_coverage()
	_check(bool(coverage.get("ok", false)), "every golden technique has a motion requirement")

	# Main deterministic golden chain. Seed 4 is contractually selected for the two probabilistic P1 edges.
	var state: Dictionary = runtime.new_match("ibjjf_v6", true, 4)
	_check(str(state.get("combat", {}).get("pos", "")) == "standing_neutral", "match starts standing neutral")
	_check(str(state.get("physical", {}).get("authority", "")) == "DERIVED_FROM_DETERMINISTIC_REDUCER", "physical state derives from reducer")
	_check(str(state.get("physical", {}).get("athletes", {}).get("p1", {}).get("head_position", "")) == "UNKNOWN", "unobserved biomechanical detail remains UNKNOWN")

	var take_down: Dictionary = runtime.step(state, {"atk":"t001", "def":"", "atk_player":1})
	_check(bool(take_down.get("accepted", false)), "double-leg action is accepted")
	state = take_down.get("state", {})
	_check(str(state.get("combat", {}).get("pos", "")) == "half_guard_top", "double-leg reaches half_guard_top")
	_check(int(state.get("combat", {}).get("p1", {}).get("score", -1)) == 0, "takedown score waits for stabilization")
	var take_down_motion: Dictionary = take_down.get("motion_request", {})
	_check(str(take_down_motion.get("technique_id", "")) == "t001", "motion request identifies reducer technique")
	_check(not bool(take_down_motion.get("authoritative", true)), "motion request is non-authoritative")
	_check(not bool(take_down_motion.get("may_mutate_combat", true)), "motion cannot mutate combat")
	_check(str(take_down_motion.get("asset_status", "")) == "MISSING_APPROVED_FINAL", "missing final paired animation remains explicit")
	_check(not bool(take_down_motion.get("ready_to_play", true)), "unapproved motion cannot be promoted")

	var stabilized: Dictionary = runtime.step(state, {"kind":"stabilize", "player":1, "seconds":3.0})
	state = stabilized.get("state", {})
	_check(int(state.get("combat", {}).get("p1", {}).get("score", -1)) == 2, "IBJJF takedown awards 2 only after stabilization")
	_check(str(stabilized.get("motion_request", {}).get("visual_event", "")) == "stabilization", "stabilization produces event-only visual request")

	var pass_result: Dictionary = runtime.step(state, {"atk":"t025", "def":"", "atk_player":1})
	state = pass_result.get("state", {})
	_check(str(state.get("combat", {}).get("pos", "")) == "side_control", "body-lock pass reaches side control")
	_check(int(state.get("combat", {}).get("p1", {}).get("score", -1)) == 2, "guard-pass points remain pending")
	state = runtime.step(state, {"kind":"stabilize", "player":1, "seconds":3.0}).get("state", {})
	_check(int(state.get("combat", {}).get("p1", {}).get("score", -1)) == 5, "guard pass adds 3 after stabilization")

	var mount_result: Dictionary = runtime.step(state, {"atk":"slice_side_to_mount", "def":"", "atk_player":1})
	state = mount_result.get("state", {})
	_check(str(state.get("combat", {}).get("pos", "")) == "mount_high", "side control transitions to mount")
	state = runtime.step(state, {"kind":"stabilize", "player":1, "seconds":3.0}).get("state", {})
	_check(int(state.get("combat", {}).get("p1", {}).get("score", -1)) == 9, "mount adds 4 after stabilization")

	var submission: Dictionary = runtime.step(state, {"atk":"t057", "def":"", "atk_player":1})
	state = submission.get("state", {})
	_check(str(state.get("combat", {}).get("pos", "")) == "submission", "mount armbar reaches terminal submission")
	_check(int(state.get("combat", {}).get("winner", 0)) == 1, "submission sets winner through reducer")
	_check(str(submission.get("motion_request", {}).get("technique_id", "")) == "t057", "submission exposes paired motion obligation")
	_check(not bool(submission.get("authoritative_state_changed_by_renderer", true)), "renderer never changes authoritative state")

	# Counter branch: existing reducer contract proves this seed/window redirects double leg to front headlock.
	var defense_state: Dictionary = runtime.new_match("ibjjf_v6", true, 12345)
	var sprawl: Dictionary = runtime.step(defense_state, {"atk":"t001", "def":"slice_sprawl", "atk_player":1, "defense_elapsed_ms":250.0})
	_check(str(sprawl.get("state", {}).get("combat", {}).get("pos", "")) == "front_headlock", "in-window sprawl redirects to front headlock")
	_check(str(sprawl.get("motion_request", {}).get("technique_id", "")) == "slice_sprawl", "counter outcome requests counter animation")

	# Pass-defense branch. Physical state is positioned by reducer truth; no hidden contacts are invented.
	var pass_defense_state: Dictionary = runtime.new_match("ibjjf_v6", true, 1)
	pass_defense_state["combat"]["pos"] = "half_guard_top"
	pass_defense_state["combat"]["top"] = 1
	pass_defense_state["physical"] = preload("res://src/combat/GrapplingPhysicalStateV1.gd").from_reducer_state(pass_defense_state["combat"])
	var knee_shield: Dictionary = runtime.step(pass_defense_state, {"atk":"t025", "def":"t049", "atk_player":1, "defense_elapsed_ms":250.0})
	_check(str(knee_shield.get("state", {}).get("combat", {}).get("pos", "")) == "knee_shield_half", "knee-shield counter redirects pass")
	_check(str(knee_shield.get("motion_request", {}).get("technique_id", "")) == "t049", "pass counter requests t049 motion")

	# Alternate branch and invalid-action invariants.
	var guard_state: Dictionary = runtime.new_match("ibjjf_v6", true, 1)
	var pull_guard: Dictionary = runtime.step(guard_state, {"atk":"t005", "def":"", "atk_player":1})
	_check(str(pull_guard.get("state", {}).get("combat", {}).get("pos", "")) == "closed_guard", "guard pull reaches explicit closed_guard")

	var invalid_state: Dictionary = runtime.new_match("ibjjf_v6", true, 4)
	var before_tick := int(invalid_state.get("combat", {}).get("tick", -1))
	var invalid: Dictionary = runtime.step(invalid_state, {"atk":"unknown_technique", "def":"", "atk_player":1})
	_check(not bool(invalid.get("accepted", true)), "unknown technique is rejected")
	_check(int(invalid.get("state", {}).get("combat", {}).get("tick", -2)) == before_tick, "rejected action does not advance deterministic tick")
	_check(str(invalid.get("motion_request", {}).get("asset_status", "")) == "NO_COMMITTED_TRANSITION", "rejected action cannot create committed animation")

	# Replay equivalence.
	var replay_a: Dictionary = runtime.new_match("ibjjf_v6", true, 4)
	var replay_b: Dictionary = runtime.new_match("ibjjf_v6", true, 4)
	var action := {"atk":"t001", "def":"", "atk_player":1}
	replay_a = runtime.step(replay_a, action).get("state", {})
	replay_b = runtime.step(replay_b, action).get("state", {})
	_check(replay_a == replay_b, "same seed and action produce identical grappling runtime state")

	if failures.is_empty():
		print("GRAPPLING_GOLDEN_CHAIN_SMOKE PASS %d/%d" % [checks, checks])
		quit(0)
	else:
		print("GRAPPLING_GOLDEN_CHAIN_SMOKE FAIL %d checks / %d failures" % [checks, failures.size()])
		quit(1)
