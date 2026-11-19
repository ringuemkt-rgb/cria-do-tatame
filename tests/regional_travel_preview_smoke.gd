extends SceneTree

# Destination preflight is read-only, including when funds are insufficient.
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("[TravelPreview] " + message)

func _run() -> void:
	await process_frame
	var manager := root.get_node_or_null("WorldMapManager")
	var world := root.get_node_or_null("WorldState")
	var registry := root.get_node_or_null("DataRegistry")
	_check(manager != null and world != null and registry != null, "canonical autoloads available")
	if manager == null or world == null or registry == null:
		_finish()
		return
	var original_map: Dictionary = manager.call("to_dict").duplicate(true)
	var original_world: Dictionary = world.call("to_dict").duplicate(true)
	var hubs: Dictionary = registry.get("hubs_dense")
	var original_hubs: Dictionary = hubs.duplicate(true)
	# Preflight an existing canonical destination; never fabricate map routes.
	manager.call("load_from_dict", {"current_hub": "itubera", "unlocked_hubs": ["itubera", "zambiapunga"]})
	world.set("money", 0)
	var before_map: Dictionary = manager.call("to_dict").duplicate(true)
	var before_money := int(world.get("money"))
	var current: Dictionary = manager.call("preview_travel_to", "itubera")
	_check(bool(current.get("ok", false)) and bool(current.get("already_here", false)), "current hub is a free no-op")
	_check(int(current.get("cost", -1)) == 0 and not bool(current.get("advances_day", true)), "current hub has zero preview cost and time")
	var destination: Dictionary = manager.call("preview_travel_to", "zambiapunga")
	_check(bool(destination.get("ok", false)) and not bool(destination.get("affordable", true)), "preview reports insufficient funds without rejecting the destination")
	_check(int(destination.get("cost", -1)) == 40 and int(destination.get("hours", -1)) == 2, "preview uses canonical cost and time")
	_check(not bool(destination.get("advances_day", true)), "two-hour trip does not advance the day")
	_check(not bool(manager.call("preview_travel_to", "salvador").get("ok", false)), "Salvador is not playable")
	_check(not bool(manager.call("preview_travel_to", "itacare").get("ok", false)), "Itacare is not playable")
	_check(manager.call("to_dict") == before_map and int(world.get("money")) == before_money, "preview never mutates campaign state")
	world.set("money", 40)
	_check(bool(manager.call("preview_travel_to", "zambiapunga").get("affordable", false)), "affordability updates when balance changes")
	# Corrupt candidate data fails closed; restore the registry before finishing.
	var altered: Dictionary = original_hubs.duplicate(true)
	var altered_dest: Dictionary = altered.get("hubs", {}).get("zambiapunga", {}).duplicate(true)
	altered_dest["travel_cost"] = -40
	altered["hubs"]["zambiapunga"] = altered_dest
	registry.set("hubs_dense", altered)
	_check(str(manager.call("preview_travel_to", "zambiapunga").get("reason", "")) == "invalid_travel_data", "negative travel cost fails closed")
	registry.set("hubs_dense", original_hubs)
	world.call("load_from_dict", original_world)
	manager.call("load_from_dict", original_map)
	_finish()

func _finish() -> void:
	print("[TravelPreview] checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
