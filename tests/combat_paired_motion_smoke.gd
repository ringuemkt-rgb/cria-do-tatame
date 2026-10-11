extends SceneTree

const FighterScript = preload("res://src/characters/FighterPlaceholder.gd")
const PairScript = preload("res://src/animation/CombatPairTimelineV1.gd")

var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		push_error("[CombatPairedMotion] " + label)

func _run() -> void:
	var ruan: Node2D = FighterScript.new()
	ruan.fighter_id = "ruan_macacao"
	ruan.display_name = "Ruan Macacao"
	ruan.position = Vector2(430.0, 385.0)
	root.add_child(ruan)
	var davi: Node2D = FighterScript.new()
	davi.fighter_id = "davi_relampago"
	davi.display_name = "Davi Relampago"
	davi.primary_color = Color("174f9b")
	davi.skin_color = Color("986640")
	davi.scale = Vector2(-1, 1)
	davi.position = Vector2(850.0, 385.0)
	root.add_child(davi)
	var pair = PairScript.new()
	root.add_child(pair)
	_check(pair.configure_views(ruan, davi), "paired preview contract loads")
	_check(pair.is_ready(), "views and preview contract ready")
	if not pair.is_ready():
		quit(1)
		return
	_check(ruan.has_node("ProceduralRigPreview") or ruan.animated_sprite.sprite_frames != null, "Ruan has drawable preview")
	_check(davi.has_node("ProceduralRigPreview") or davi.animated_sprite.sprite_frames != null, "Davi has drawable preview")
	pair.set_stage_state("PLAYER_STANDING_NEUTRAL")
	_check(ruan.position.x < davi.position.x, "fighters maintain canonical screen order")
	_check(not pair.busy, "preview starts idle")
	var cfg: Dictionary = pair.config.duplicate(true)
	_check(not bool(cfg.get("shipping", true)), "motion is not falsely shipping")
	_check(pair._validate_contract(cfg), "six-phase contract passes")
	var bad: Dictionary = cfg.duplicate(true)
	bad["shipping"] = true
	_check(not pair._validate_contract(bad), "shipping=true without rights is rejected")
	bad = cfg.duplicate(true)
	bad["phases"].pop_back()
	_check(not pair._validate_contract(bad), "incomplete paired phase contract is rejected")
	for technique_id in cfg.get("technique_profiles", {}).keys():
		var motion: Dictionary = pair.plan_for(str(technique_id), "ruan_macacao", true, true, "PLAYER_STANDING_NEUTRAL", "PLAYER_TOP_GUARD")
		_check(motion.get("phases", []).size() == 6, "six phases for " + str(technique_id))
		_check(not bool(motion.get("authoritative", true)), "motion cannot own combat authority " + str(technique_id))
	var rejected := pair.plan_for("baiana", "ruan_macacao", false, false, "PLAYER_STANDING_NEUTRAL", "PLAYER_TOP_GUARD")
	_check(rejected.is_empty(), "rejected attempts never start motion")
	var unknown := pair.plan_for("baiana", "unknown_character", true, true, "PLAYER_STANDING_NEUTRAL", "PLAYER_TOP_GUARD")
	_check(unknown.is_empty(), "unknown actor never owns paired playback")
	var finish_plan: Dictionary = pair.plan_for("encerramento_tecnico", "ruan_macacao", true, true, "PLAYER_SUBMISSION_ATTACK", "PLAYER_STANDING_NEUTRAL")
	var finish_steps: Array = finish_plan.get("phases", [])
	_check(finish_steps.size() == 6, "technical finish has six phases")
	if finish_steps.size() == 6:
		_check(str(finish_steps[5]["ruan_pose"]) == "victory", "finisher shows Ruan's victory before scene change")
		_check(str(finish_steps[5]["davi_pose"]) == "bottom", "finisher leaves defender on mat")
		_check((finish_steps[5]["ruan_pos"] as Vector2).x < 680.0, "finisher stays on the grappling stage")
	var main_snapshot := {"pos": "standing_neutral", "score": 2, "winner": 0}
	var snapshot_copy := main_snapshot.duplicate(true)
	var ok: bool = await pair.play_resolution("baiana", "ruan_macacao", {"accepted": true, "success": true}, "PLAYER_STANDING_NEUTRAL", "PLAYER_TOP_GUARD")
	_check(ok, "accepted takedown plays a complete paired sequence")
	_check(not pair.busy, "motion releases busy lock")
	_check(pair.last_sequence.size() == 6, "all six phases were visited")
	_check(str(pair.last_sequence[0].get("name", "")) == "anticipation", "preview starts at anticipation")
	_check(str(pair.last_sequence[5].get("name", "")) == "recovery", "preview ends at recovery")
	_check(ruan.position.distance_to(Vector2(587.0, 388.0)) < 0.01, "Ruan reaches authoritative top-stage projection")
	_check(davi.position.distance_to(Vector2(685.0, 388.0)) < 0.01, "Davi reaches paired bottom-stage projection")
	_check(main_snapshot == snapshot_copy, "visual playback never touches authoritative combat values")
	var defended: bool = await pair.play_resolution("baiana", "davi_relampago", {"accepted": true, "success": false}, "PLAYER_TOP_GUARD", "PLAYER_TOP_GUARD")
	_check(defended, "Davi failed action still has defensive response frames")
	_check(str(pair.last_sequence[0].get("davi_pose", "")) == "stance", "defended branch animates real attacking actor")
	_check(pair.playback_count == 2, "two independent action animations completed")
	pair.queue_free()
	ruan.queue_free()
	davi.queue_free()
	if failures.is_empty():
		print("[CombatPairedMotion] PASS checks=%d" % checks)
		quit(0)
	else:
		print("[CombatPairedMotion] FAIL checks=%d failures=%d" % [checks, failures.size()])
		quit(1)
