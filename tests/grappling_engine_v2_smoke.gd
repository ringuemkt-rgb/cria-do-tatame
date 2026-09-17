extends SceneTree

const GripGraphScript = preload("res://src/combat/GrapplingGripGraphV1.gd")
const MicroStateScript = preload("res://src/combat/GrapplingMicroStateV1.gd")
const ReactionSelectorScript = preload("res://src/combat/GrapplingReactionSelectorV1.gd")
const MotionMatcherScript = preload("res://src/animation/GrapplingMotionMatcherV1.gd")
const EngineV2Script = preload("res://src/combat/CriaGrapplingEngineV2.gd")

func _init() -> void:
	var topology := _load_json("res://data/combat/grip_topology_v1.json")
	var reaction_policy := _load_json("res://data/combat/grappling_reaction_policy_v1.json")
	var motion_profile := _load_json("res://data/animation/grappling_motion_matching_profile_v1.json")
	if topology.is_empty() or reaction_policy.is_empty() or motion_profile.is_empty():
		_fail("failed_to_load_contracts")
		return

	var grip_graph = GripGraphScript.new(topology)
	if not grip_graph.is_ready():
		_fail("grip_graph_not_ready")
		return

	var gi_state: Dictionary = grip_graph.new_state(true)
	var gi_result := grip_graph.apply_event(gi_state, {
		"kind": "establish",
		"actor": 1,
		"source_hand": "hand_r",
		"target_player": 2,
		"target_node": "sleeve_l",
		"grip_type": "sleeve_grip",
		"integrity": 0.9,
		"tick": 1
	})
	if not bool(gi_result.get("ok", false)):
		_fail("gi_sleeve_grip_rejected")
		return
	gi_state = gi_result.get("state", {})
	if int(gi_state.get("edges", []).size()) != 1:
		_fail("gi_grip_edge_count_wrong")
		return

	var replace_result := grip_graph.apply_event(gi_state, {
		"kind": "establish",
		"actor": 1,
		"source_hand": "hand_r",
		"target_player": 2,
		"target_node": "collar_l",
		"grip_type": "cross_collar",
		"integrity": 1.0,
		"tick": 2
	})
	if not bool(replace_result.get("ok", false)) or int(replace_result.get("state", {}).get("edges", []).size()) != 1:
		_fail("one_grip_per_hand_invariant_failed")
		return

	var nogi_state: Dictionary = grip_graph.new_state(false)
	var illegal_gi := grip_graph.apply_event(nogi_state, {
		"kind": "establish",
		"actor": 1,
		"source_hand": "hand_l",
		"target_player": 2,
		"target_node": "collar_r",
		"grip_type": "cross_collar"
	})
	if bool(illegal_gi.get("ok", false)):
		_fail("gi_grip_allowed_in_nogi")
		return

	var wrist_result := grip_graph.apply_event(nogi_state, {
		"kind": "establish",
		"actor": 1,
		"source_hand": "hand_l",
		"target_player": 2,
		"target_node": "wrist_r",
		"grip_type": "wrist_control",
		"tick": 1
	})
	if not bool(wrist_result.get("ok", false)):
		_fail("nogi_wrist_control_rejected")
		return
	nogi_state = wrist_result.get("state", {})

	var base_runtime_state := {
		"combat": {
			"pos": "standing_neutral",
			"top": 0,
			"gi": false,
			"p1": {"gas": 82.0, "score": 0},
			"p2": {"gas": 25.0, "score": 0}
		},
		"physical": {}
	}
	var microstate := MicroStateScript.from_runtime(
		base_runtime_state,
		nogi_state,
		grip_graph,
		{"technique_id": "double_leg", "technique_type": "takedown"},
		{},
		""
	)
	var micro_check := MicroStateScript.validate(microstate)
	if not bool(micro_check.get("ok", false)):
		_fail("microstate_invalid:%s" % str(micro_check.get("errors", [])))
		return
	if str(microstate.get("players", {}).get("p2", {}).get("gas_bucket", "")) != "fatigued":
		_fail("gas_bucket_projection_failed")
		return
	if "wrist_control" not in microstate.get("players", {}).get("p1", {}).get("grip_signature", []):
		_fail("grip_signature_projection_failed")
		return

	var reaction_selector = ReactionSelectorScript.new(reaction_policy)
	var reactions := reaction_selector.rank(microstate, {"attack_type": "takedown"}, 2, 4)
	if reactions.is_empty() or str(reactions[0].get("reaction_id", "")) != "sprawl_frame":
		_fail("reaction_ranking_failed:%s" % str(reactions))
		return

	var matcher = MotionMatcherScript.new(motion_profile)
	var query := MicroStateScript.motion_query(microstate, 1, "sprawl_frame")
	var exact_features := query.duplicate(true)
	var wrong_features := query.duplicate(true)
	wrong_features["mode"] = "gi"
	wrong_features["reaction_id"] = "whizzer_balance"
	var clips := [
		{"clip_id": "clip_b_exact", "features": exact_features, "sync_map_ref": "sync/b.json"},
		{"clip_id": "clip_wrong", "features": wrong_features, "sync_map_ref": "sync/wrong.json"},
		{"clip_id": "clip_a_exact", "features": exact_features, "sync_map_ref": "sync/a.json"}
	]
	var match_result := matcher.select(query, clips)
	if not bool(match_result.get("ok", false)) or str(match_result.get("clip_id", "")) != "clip_a_exact":
		_fail("motion_matching_failed:%s" % str(match_result))
		return

	# Loading the facade here forces Godot to parse its complete dependency surface.
	if EngineV2Script == null:
		_fail("engine_v2_preload_failed")
		return

	print("GRAPPLING_ENGINE_V2_SMOKE_OK")
	quit(0)

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

func _fail(message: String) -> void:
	push_error("GRAPPLING_ENGINE_V2_SMOKE_FAIL: %s" % message)
	quit(1)
