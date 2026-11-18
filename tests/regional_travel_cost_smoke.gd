extends SceneTree

# Reject corrupted destination costs before touching the campaign or save.
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("[TravelCost] " + message)

func _run() -> void:
	await process_frame
	var world_map := root.get_node_or_null("WorldMapManager")
	var world := root.get_node_or_null("WorldState")
	var registry := root.get_node_or_null("DataRegistry")
	_check(world_map != null and world != null and registry != null, "canonical autoloads exist")
	if world_map == null or world == null or registry == null:
		_finish()
		return
	var original_map: Dictionary = world_map.call("to_dict").duplicate(true)
	var original_world: Dictionary = world.call("to_dict").duplicate(true)
	var hubs: Dictionary = registry.get("hubs_dense").get("hubs", {})
	var destination := ""
	for candidate in world_map.PLAYABLE_HUB_IDS:
		if candidate != str(world_map.get("current_hub")) and hubs.has(candidate):
			destination = candidate
			break
	_check(destination != "", "another approved Baixo Sul destination exists")
	if destination != "":
		var original_hub: Dictionary = hubs[destination].duplicate(true)
		var unlocked: Array = world_map.get("unlocked_hubs")
		if not unlocked.has(destination):
			unlocked.append(destination)
		for bad_cost in [-25, "10", null, 2.5]:
			var mutated: Dictionary = original_hub.duplicate(true)
			mutated["travel_cost"] = bad_cost
			hubs[destination] = mutated
			var before_money: int = int(world.get("money"))
			var before_day: int = int(world.get("day_index"))
			var before_week: int = int(world.get("week"))
			var before_hub: String = str(world_map.get("current_hub"))
			var before_log: Array = world_map.get("travel_log").duplicate(true)
			var result: Dictionary = world_map.call("travel_to", destination)
			_check(not bool(result.get("ok", false)), "invalid cost %s rejected" % str(bad_cost))
			_check(int(world.get("money")) == before_money, "invalid cost cannot alter money")
			_check(int(world.get("day_index")) == before_day and int(world.get("week")) == before_week, "invalid cost cannot advance calendar")
			_check(str(world_map.get("current_hub")) == before_hub and world_map.get("travel_log") == before_log, "invalid cost cannot alter location or history")
		hubs[destination] = original_hub
	world.call("load_from_dict", original_world)
	world_map.call("load_from_dict", original_map)
	_finish()

func _finish() -> void:
	print("[TravelCost] checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
