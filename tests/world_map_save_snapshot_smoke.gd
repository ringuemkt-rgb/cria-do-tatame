extends SceneTree

# Serialization must not leak live regional arrays into saved dictionaries.
# This test never writes a save or changes the playable map permanently.
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("[WorldSnapshot] " + message)

func _run() -> void:
	await process_frame
	var world_map := root.get_node_or_null("WorldMapManager")
	_check(world_map != null, "canonical WorldMapManager autoload exists")
	if world_map == null:
		_finish()
		return
	var original: Dictionary = world_map.call("to_dict").duplicate(true)
	var snapshot: Dictionary = world_map.call("to_dict")
	var original_visits: Array = world_map.get("visited_hubs").duplicate(true)
	var original_unlocks: Array = world_map.get("unlocked_hubs").duplicate(true)
	var original_log: Array = world_map.get("travel_log").duplicate(true)
	# Mutate returned data, including a nested travel entry, not the manager.
	snapshot["visited_hubs"].append("salvador")
	snapshot["unlocked_hubs"].append("itacare")
	snapshot["travel_log"].append({"hub": "salvador", "meta": {"note": "history only"}})
	snapshot["travel_log"][-1]["meta"]["note"] = "changed"
	_check(world_map.get("visited_hubs") == original_visits, "snapshot visit edits do not mutate runtime")
	_check(world_map.get("unlocked_hubs") == original_unlocks, "snapshot unlock edits do not mutate runtime")
	_check(world_map.get("travel_log") == original_log, "snapshot log edits do not mutate runtime")
	# Test the inverse direction: live changes must not rewrite the snapshot.
	var stable: Dictionary = world_map.call("to_dict")
	var live_visits: Array = world_map.get("visited_hubs")
	var live_unlocks: Array = world_map.get("unlocked_hubs")
	var live_log: Array = world_map.get("travel_log")
	live_visits.append("temporary_test_visit")
	live_unlocks.append("temporary_test_unlock")
	live_log.append({"hub": "temporary_test_log"})
	_check(not stable["visited_hubs"].has("temporary_test_visit"), "runtime visit edits do not rewrite snapshot")
	_check(not stable["unlocked_hubs"].has("temporary_test_unlock"), "runtime unlock edits do not rewrite snapshot")
	_check(stable["travel_log"].size() == original_log.size(), "runtime log edits do not rewrite snapshot")
	# Restore without saving or emitting travel.
	world_map.call("load_from_dict", original)
	_finish()

func _finish() -> void:
	print("[WorldSnapshot] checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
