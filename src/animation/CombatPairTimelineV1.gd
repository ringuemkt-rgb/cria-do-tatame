extends Node
class_name CombatPairTimelineV1

signal phase_started(technique_id: String, actor_id: String, phase_name: String, success: bool)
signal paired_motion_finished(technique_id: String, actor_id: String)

## Shared six-phase animation clock for the existing CombatArenaBase.
## VISUAL ONLY: CombatManager decides actions, positions, score and winner.
## Procedural poses are preview placeholders and never count as final BJJ art.

const CONTRACT_PATH := "res://data/animation/combat_pair_preview_v1.json"
const PHASES := ["anticipation", "entry", "establish", "stabilize", "response", "recovery"]
const POSES := ["idle", "stance", "guard", "grip", "shot", "sprawl", "top", "bottom", "pass", "mount", "submission", "defense", "impact", "victory"]
var ruan: Node2D
var davi: Node2D
var config: Dictionary = {}
var busy := false
var last_sequence: Array[Dictionary] = []
var playback_count := 0

func _ready() -> void:
	var file := FileAccess.open(CONTRACT_PATH, FileAccess.READ)
	if file == null:
		push_warning("[CombatPairTimeline] Motion preview contract unavailable.")
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) == TYPE_DICTIONARY and _validate_contract(parsed):
		config = parsed
	else:
		push_error("[CombatPairTimeline] Invalid paired visual preview contract.")

func configure_views(player_view: Node2D, opponent_view: Node2D) -> bool:
	ruan = player_view
	davi = opponent_view
	return is_ready()

func is_ready() -> bool:
	return not config.is_empty() and is_instance_valid(ruan) and is_instance_valid(davi)

func is_busy() -> bool:
	return busy

func _validate_contract(raw: Dictionary) -> bool:
	if bool(raw.get("shipping", true)) or str(raw.get("authority", "")) != "VISUAL_ONLY_NON_AUTHORITATIVE":
		return false
	var steps: Array = raw.get("phases", [])
	if steps.size() != PHASES.size():
		return false
	var last_fraction := -1.0
	for i in range(PHASES.size()):
		if typeof(steps[i]) != TYPE_DICTIONARY:
			return false
		var step: Dictionary = steps[i]
		var fraction := float(step.get("interpolation", -1.0))
		if str(step.get("name", "")) != PHASES[i] or int(step.get("duration_ms", 0)) < 20 or fraction <= last_fraction or fraction > 1.0:
			return false
		last_fraction = fraction
	if not is_equal_approx(last_fraction, 1.0):
		return false
	var profiles: Dictionary = raw.get("profiles", {})
	if profiles.is_empty() or not profiles.has(str(raw.get("fallback_profile", ""))):
		return false
	for value in profiles.values():
		if typeof(value) != TYPE_DICTIONARY:
			return false
		for role in ["attacker", "defender"]:
			var seq: Array = value.get(role, [])
			if seq.size() != PHASES.size():
				return false
			for pose in seq:
				if not POSES.has(str(pose)):
					return false
	for profile_name in raw.get("technique_profiles", {}).values():
		if not profiles.has(str(profile_name)):
			return false
	return true

func _positions_for_state(state: String) -> Dictionary:
	# State is already resolved by CombatManager, relative to Ruan.
	var positions := {"ruan": Vector2(435.0, 385.0), "davi": Vector2(845.0, 385.0)}
	if state.contains("CLINCH"):
		positions = {"ruan": Vector2(573.0, 387.0), "davi": Vector2(708.0, 387.0)}
	elif state.contains("GUARD") or state.contains("SIDE") or state.contains("MOUNT") or state.contains("BACK") or state.contains("SUBMISSION"):
		positions = {"ruan": Vector2(587.0, 388.0), "davi": Vector2(685.0, 388.0)}
	return positions

func _final_poses(state: String) -> Dictionary:
	var result := {"ruan": "stance", "davi": "guard"}
	if state.contains("PLAYER_TOP_") or state == "PLAYER_BACK_ATTACK" or state == "PLAYER_SUBMISSION_ATTACK":
		result = {"ruan": "top", "davi": "bottom"}
	elif state.contains("PLAYER_BOTTOM_") or state == "PLAYER_BACK_DEFENSE" or state == "PLAYER_SUBMISSION_DEFENSE":
		result = {"ruan": "bottom", "davi": "top"}
	if state.contains("MOUNT"):
		if result["ruan"] == "top":
			result["ruan"] = "mount"
		else:
			result["davi"] = "mount"
	if state == "PLAYER_SUBMISSION_ATTACK":
		result["ruan"] = "submission"
	elif state == "PLAYER_SUBMISSION_DEFENSE":
		result["davi"] = "submission"
	return result

func set_stage_state(state: String) -> void:
	if busy or not is_ready():
		return
	var target := _positions_for_state(state)
	ruan.position = target["ruan"]
	davi.position = target["davi"]
	_apply_poses(_final_poses(state))

func _apply_poses(roles: Dictionary) -> void:
	if is_instance_valid(ruan):
		ruan.call("set_preview_pose", str(roles.get("ruan", "stance")))
	if is_instance_valid(davi):
		davi.call("set_preview_pose", str(roles.get("davi", "guard")))

func plan_for(technique_id: String, actor_id: String, accepted: bool, success: bool, from_state: String, to_state: String) -> Dictionary:
	if not is_ready() or not accepted:
		return {}
	var is_player := actor_id == "ruan_macacao"
	if not is_player and actor_id != "davi_relampago":
		return {}
	var profiles: Dictionary = config["profiles"]
	var chosen := str(config.get("technique_profiles", {}).get(technique_id, config.get("fallback_profile", "grip")))
	if not success:
		chosen = "defended"
	var profile: Dictionary = profiles.get(chosen, {})
	if profile.is_empty():
		return {}
	var first: Vector2 = ruan.position
	var second: Vector2 = davi.position
	var finish: Dictionary = _positions_for_state(to_state if success else from_state)
	# Combat may legitimately transition following a defense or counter.
	if to_state != from_state:
		finish = _positions_for_state(to_state)
	var final_poses: Dictionary = _final_poses(to_state)
	# CombatManager resets its state machine as soon as the match ends.
	# Keep the visual closure on the mat and let the winner celebrate instead
	# of teleporting both fighters to standing before ResultScreen appears.
	if success and technique_id == "encerramento_tecnico":
		finish = _positions_for_state("PLAYER_SUBMISSION_ATTACK")
		final_poses = {"ruan": "victory" if is_player else "bottom", "davi": "bottom" if is_player else "victory"}
	var steps: Array[Dictionary] = []
	for i in range(PHASES.size()):
		var step: Dictionary = config["phases"][i]
		var amount := float(step["interpolation"])
		var attack_pose := str(profile["attacker"][i])
		var defense_pose := str(profile["defender"][i])
		var ruan_frame: Vector2 = first.lerp(finish["ruan"], amount)
		var davi_frame: Vector2 = second.lerp(finish["davi"], amount)
		# A defended standing entry still approaches contact and retreats;
		# when start=end, a plain lerp would make the two fighters shadowbox
		# 400 px apart with no readable defensive exchange.
		if from_state == to_state and from_state == "PLAYER_STANDING_NEUTRAL":
			var clinch: Dictionary = _positions_for_state("PLAYER_TOP_CLINCH")
			var approach := sin(PI * amount) * 0.88
			ruan_frame = ruan_frame.lerp(clinch["ruan"], approach)
			davi_frame = davi_frame.lerp(clinch["davi"], approach)
		var p := {
			"name": PHASES[i],
			"duration": float(step["duration_ms"]) / 1000.0,
			"ruan_pos": ruan_frame,
			"davi_pos": davi_frame,
			"ruan_pose": attack_pose if is_player else defense_pose,
			"davi_pose": defense_pose if is_player else attack_pose
		}
		if i == PHASES.size() - 1:
			p["ruan_pose"] = final_poses["ruan"]
			p["davi_pose"] = final_poses["davi"]
		steps.append(p)
	return {
		"technique_id": technique_id, "actor_id": actor_id, "profile": chosen,
		"accepted": true, "success": success, "authoritative": false,
		"shipping": false, "phases": steps
	}

func play_resolution(technique_id: String, actor_id: String, result: Dictionary, from_state: String, to_state: String) -> bool:
	if busy or not is_ready():
		return false
	var accepted := bool(result.get("accepted", not result.has("error")))
	var success := bool(result.get("success", false))
	var planned: Dictionary = plan_for(technique_id, actor_id, accepted, success, from_state, to_state)
	if planned.is_empty():
		return false
	busy = true
	playback_count += 1
	last_sequence.clear()
	ruan.call("begin_visual_action", technique_id)
	davi.call("begin_visual_action", technique_id)
	for raw_step in planned["phases"]:
		if not is_inside_tree() or not is_instance_valid(ruan) or not is_instance_valid(davi):
			busy = false
			return false
		var step: Dictionary = raw_step
		last_sequence.append(step.duplicate(true))
		phase_started.emit(technique_id, actor_id, str(step["name"]), success)
		_apply_poses({"ruan": step["ruan_pose"], "davi": step["davi_pose"]})
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(ruan, "position", step["ruan_pos"], float(step["duration"])).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(davi, "position", step["davi_pos"], float(step["duration"])).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await tween.finished
	if is_instance_valid(ruan) and is_instance_valid(davi):
		var final_step: Dictionary = planned["phases"][-1]
		ruan.call("end_visual_action", str(final_step["ruan_pose"]))
		davi.call("end_visual_action", str(final_step["davi_pose"]))
	busy = false
	paired_motion_finished.emit(technique_id, actor_id)
	return true
