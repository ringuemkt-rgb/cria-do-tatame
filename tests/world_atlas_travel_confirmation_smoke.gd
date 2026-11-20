extends SceneTree

# Atlas confirmation must not mutate money, save, calendar, or travel log
# merely because a destination button was pressed.
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("[AtlasConfirm] " + message)

func _run() -> void:
	await process_frame
	var manager := root.get_node_or_null("WorldMapManager")
	var world := root.get_node_or_null("WorldState")
	var packed := load("res://scenes/world/WorldMapScreen.tscn") as PackedScene
	_check(manager != null and world != null and packed != null, "autoloads and atlas scene load")
	if manager == null or world == null or packed == null:
		_finish()
		return
	var saved_map: Dictionary = manager.call("to_dict").duplicate(true)
	var saved_world: Dictionary = world.call("to_dict").duplicate(true)
	manager.call("load_from_dict", {"current_hub": "itubera", "unlocked_hubs": ["itubera", "zambiapunga"]})
	world.set("money", 100)
	var atlas: Control = packed.instantiate()
	root.add_child(atlas)
	await process_frame
	var before_map: Dictionary = manager.call("to_dict").duplicate(true)
	var before_money := int(world.get("money"))
	var before_week := int(world.get("week"))
	var before_day := int(world.get("day_index"))
	atlas.call("_on_travel_pressed", "salvador")
	_check(not bool(atlas.get("_confirmation_open")), "Salvador cannot open a travel confirmation")
	atlas.call("_on_travel_pressed", "itubera")
	_check(not bool(atlas.get("_confirmation_open")), "current hub cannot open a paid travel confirmation")
	atlas.call("_on_travel_pressed", "zambiapunga")
	_check(bool(atlas.get("_confirmation_open")), "valid affordable destination requires confirmation")
	_check(str(atlas.get("_selected_destination")) == "zambiapunga", "confirmation targets canonical hub ID")
	_check(manager.call("to_dict") == before_map and int(world.get("money")) == before_money, "opening confirmation has no travel side effects")
	_check(int(world.get("week")) == before_week and int(world.get("day_index")) == before_day, "opening confirmation does not advance time")
	atlas.call("_on_travel_pressed", "itubera")
	_check(str(atlas.get("_selected_destination")) == "zambiapunga", "second tap cannot replace pending confirmation")
	atlas.call("_cancel_travel")
	_check(not bool(atlas.get("_confirmation_open")) and str(atlas.get("_selected_destination")) == "", "cancel clears pending selection")
	_check(manager.call("to_dict") == before_map and int(world.get("money")) == before_money, "cancel does not charge or travel")
	atlas.call("_confirm_travel")
	_check(manager.call("to_dict") == before_map, "stale confirmation cannot commit travel")
	world.set("money", 0)
	atlas.call("_on_travel_pressed", "zambiapunga")
	_check(not bool(atlas.get("_confirmation_open")), "insufficient funds cannot open confirmation")
	atlas.queue_free()
	await process_frame
	world.call("load_from_dict", saved_world)
	manager.call("load_from_dict", saved_map)
	_finish()

func _finish() -> void:
	print("[AtlasConfirm] checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
