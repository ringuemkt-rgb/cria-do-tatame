extends SceneTree

const RotaScene = preload("res://scenes/world/Rota101Travel.tscn")

var failures: Array[String] = []
var checks := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var map_manager: Node = root.get_node_or_null("WorldMapManager")
	var world_state: Node = root.get_node_or_null("WorldState")
	var progression: Node = root.get_node_or_null("ProgressionOS")
	_check(map_manager != null, "WorldMapManager autoload is available")
	_check(world_state != null, "WorldState autoload is available")
	_check(progression != null, "ProgressionOS autoload is available")
	if map_manager == null or world_state == null or progression == null:
		_finish()
		return

	map_manager.call("reset")
	progression.call("reset")
	world_state.set("money", 500)
	world_state.set("energy", 100.0)
	world_state.set("act", 3)
	world_state.set("story_flags", {})
	world_state.set("completed_missions", [])
	world_state.set("current_hub", "itubera")
	world_state.call("_sync_aliases")

	var prepared: Dictionary = map_manager.call(
		"prepare_travel",
		"pancada_grande",
		"kombi_terreiro",
		{"act": 3, "flags": {}, "route_unlocks": [], "weather": "nublado_quente"}
	)
	_check(bool(prepared.get("ok", false)), "scene smoke can prepare a ROTA 101 trip")
	if not bool(prepared.get("ok", false)):
		_finish()
		return

	var plan: Dictionary = prepared.get("plan", {})
	_check(str(plan.get("mode", "")) == "rota_101" or str(plan.get("minigame", "")) == "rota_101", "prepared plan requests ROTA 101")
	var plan_id := str(plan.get("plan_id", ""))
	_check(plan_id != "", "prepared plan has id")

	var money_before := int(world_state.get("money"))
	var energy_before := float(world_state.get("energy"))
	var hub_before := str(map_manager.get("current_hub"))
	var node_before := str(map_manager.get("current_node"))
	var log_before := int(map_manager.get("travel_log").size())

	var scene = RotaScene.instantiate()
	root.add_child(scene)
	await process_frame

	_check(scene != null, "ROTA 101 scene instantiates")
	_check(scene.get_node_or_null("HUD") != null, "scene has HUD")
	_check(scene.get_node_or_null("HUD/Controls/Left") != null, "scene has left touch control")
	_check(scene.get_node_or_null("HUD/Controls/Right") != null, "scene has right touch control")
	_check(scene.get_node_or_null("HUD/Controls/Accelerate") != null, "scene has accelerate control")
	_check(scene.get_node_or_null("HUD/Controls/Brake") != null, "scene has brake control")
	_check(scene.get_node_or_null("HUD/Controls/Horn") != null, "scene has horn control")
	_check(scene.get_node_or_null("HUD/Accessibility/AutoAccelerate") != null, "scene exposes auto accelerate")
	_check(scene.get_node_or_null("HUD/Accessibility/LaneAssist") != null, "scene exposes lane assist")
	_check(scene.get_node_or_null("HUD/Accessibility/ReducedShake") != null, "scene exposes reduced shake")
	_check(bool(scene.get("_running")), "scene enters running state with a valid pending plan")
	_check(not bool(scene.get("_committed")), "scene does not commit on load")
	_check(scene.get("simulation").get_snapshot().get("plan_id", "") == plan_id, "scene simulation consumes the pending plan")

	_check(int(world_state.get("money")) == money_before, "scene load does not spend money")
	_check(is_equal_approx(float(world_state.get("energy")), energy_before), "scene load does not spend energy")
	_check(str(map_manager.get("current_hub")) == hub_before, "scene load does not move hub")
	_check(str(map_manager.get("current_node")) == node_before, "scene load does not move current node")
	_check(int(map_manager.get("travel_log").size()) == log_before, "scene load does not append completed travel")
	_check(str(map_manager.call("get_pending_travel_plan").get("plan_id", "")) == plan_id, "pending plan remains pending before terminal outcome")

	scene.set_process(false)
	scene.queue_free()
	await process_frame
	var cancel_result: Dictionary = map_manager.call("cancel_pending_travel", plan_id)
	_check(bool(cancel_result.get("ok", false)), "scene smoke cleanup cancels pending plan")
	_check(map_manager.call("get_pending_travel_plan").is_empty(), "pending plan cleared after cleanup")
	_finish()

func _finish() -> void:
	print("ROTA_101_SCENE_SMOKE checks=%d failures=%d" % [checks, failures.size()])
	for failure in failures:
		push_error(failure)
	quit(0 if failures.is_empty() else 1)

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
