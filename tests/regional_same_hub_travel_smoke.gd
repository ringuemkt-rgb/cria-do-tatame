extends SceneTree

# Regression: tapping the current Baixo Sul hub must not charge, advance time,
# append travel history, emit a travel signal or trigger a save.
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("[SameHubTravel] " + message)

func _run() -> void:
	await process_frame
	var world_map := root.get_node_or_null("WorldMapManager")
	var world := root.get_node_or_null("WorldState")
	var bus := root.get_node_or_null("SignalBus")
	_check(world_map != null and world != null and bus != null, "canonical autoloads available")
	if world_map == null or world == null or bus == null:
		_finish()
		return
	var original_map: Dictionary = world_map.call("to_dict")
	var original_world: Dictionary = world.call("to_dict")
	var current := str(world_map.get("current_hub"))
	var before_money := int(world.get("money"))
	var before_week := int(world.get("week"))
	var before_day := int(world.get("day_index"))
	var before_travel: Array = world_map.get("travel_log").duplicate(true)
	var emitted := [0]
	var listener: Callable = func(_hub, _first_visit, _entry): emitted[0] += 1
	if bus.has_signal("world_travel_completed"):
		bus.connect("world_travel_completed", listener)
	var result: Dictionary = world_map.call("travel_to", current)
	_check(bool(result.get("ok", false)) and bool(result.get("already_here", false)), "same hub is acknowledged without travel")
	_check(int(world.get("money")) == before_money, "same hub does not debit money")
	_check(int(world.get("week")) == before_week and int(world.get("day_index")) == before_day, "same hub does not advance calendar")
	_check(world_map.get("travel_log") == before_travel, "same hub does not append history")
	_check(str(world_map.get("current_hub")) == current, "same hub remains current")
	_check(emitted[0] == 0, "same hub emits no travel completion")
	_check(not bool(world_map.call("travel_to", "salvador").get("ok", false)), "Salvador remains non-playable")
	_check(not bool(world_map.call("travel_to", "itacare").get("ok", false)), "Itacare remains non-playable")
	# A legacy save may retain Salvador in historical visits, but cannot
	# make it the current playable hub or an unlocked destination.
	world_map.call("load_from_dict", {
		"current_hub": "salvador",
		"visited_hubs": ["salvador", "itubera"],
		"unlocked_hubs": ["salvador", "itubera"],
		"travel_log": [{"hub": "salvador", "week": 1, "day": "segunda", "cost": 0}]
	})
	_check(str(world_map.get("current_hub")) == "itubera", "legacy Salvador current hub recovers to Itubera")
	_check(str(world.get("current_hub")) == "itubera", "WorldState follows recovered Itubera hub")
	_check(world_map.get("visited_hubs").has("salvador"), "legacy Salvador visit history remains readable")
	_check(not world_map.get("unlocked_hubs").has("salvador"), "legacy Salvador unlock is removed")
	_check(world_map.get("travel_log").size() == 1, "historical travel log is retained")
	_check(not bool(world_map.call("travel_to", "salvador").get("ok", false)), "legacy history never authorizes Salvador travel")
	# Resetting the map for a new campaign must synchronize both autoloads.
	world.set("current_hub", "salvador")
	world_map.call("reset")
	_check(str(world_map.get("current_hub")) == "itubera", "reset restores regional hub to Itubera")
	_check(str(world.get("current_hub")) == "itubera", "reset synchronizes WorldState to Itubera")
	_check(world_map.get("visited_hubs") == ["itubera"], "reset clears legacy visit history")
	_check(world_map.get("travel_log").is_empty(), "reset clears previous campaign travel log")
	_check(not world_map.get("unlocked_hubs").has("salvador"), "reset never unlocks external Salvador")
	if bus.has_signal("world_travel_completed"):
		bus.disconnect("world_travel_completed", listener)
	world.call("load_from_dict", original_world)
	world_map.call("load_from_dict", original_map)
	_finish()

func _finish() -> void:
	print("[SameHubTravel] checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
