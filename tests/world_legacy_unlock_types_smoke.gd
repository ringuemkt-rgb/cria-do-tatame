extends SceneTree

# Malformed legacy saves must not unlock noncanonical destinations.
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		push_error("[WorldUnlockTypes] " + label)

func _run() -> void:
	await process_frame
	var manager := root.get_node_or_null("WorldMapManager")
	var state := root.get_node_or_null("WorldState")
	_check(manager != null and state != null, "canonical world autoloads exist")
	if manager == null or state == null:
		_finish()
		return
	var old_map: Dictionary = manager.to_dict().duplicate(true)
	var old_hub: String = str(state.current_hub)
	manager.load_from_dict({
		"current_hub": "salvador",
		"visited_hubs": ["salvador", "itubera"],
		"travel_log": [{"hub": "salvador", "week": 1}],
		"unlocked_hubs": [null, 12, [], {}, "salvador", "itacare", "zambiapunga", "zambiapunga", "itubera"]
	})
	var unlocked: Array = manager.unlocked_hubs
	_check(unlocked == ["itubera", "zambiapunga"], "only unique canonical string hub IDs survive")
	_check(str(manager.current_hub) == "itubera", "legacy Salvador current hub recovers to Itubera")
	_check(str(state.current_hub) == "itubera", "world state synchronizes recovered hub")
	_check(manager.visited_hubs.has("salvador"), "legacy visit history is retained")
	_check(manager.travel_log.size() == 1, "legacy travel history remains readable")
	_check(not manager.can_travel_to("salvador"), "Salvador remains outside playable region")
	_check(not manager.can_travel_to("itacare"), "Itacare remains outside playable region")
	manager.load_from_dict({"unlocked_hubs": "zambiapunga"})
	_check(manager.unlocked_hubs == ["itubera"], "non-array unlocked payload falls back to safe hub")
	manager.load_from_dict(old_map)
	state.current_hub = old_hub
	_finish()

func _finish() -> void:
	print("[WorldUnlockTypes] checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
