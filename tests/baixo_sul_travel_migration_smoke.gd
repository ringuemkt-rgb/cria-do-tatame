extends SceneTree

var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("[BaixoSulTravel] " + message)

func _run() -> void:
	await process_frame
	var wm: Node = root.get_node_or_null("WorldMapManager")
	var world: Node = root.get_node_or_null("WorldState")
	_check(wm != null and world != null, "WorldMapManager and WorldState available")
	if wm == null or world == null:
		_finish()
		return
	var original_map: Dictionary = wm.call("to_dict")
	var original_world_hub := str(world.get("current_hub"))
	var original_money := int(world.get("money"))
	wm.call("reset")
	_check(not wm.call("can_travel_to", "salvador"), "external Salvador not a playable destination")
	_check(wm.call("can_travel_to", "itubera"), "Itubera main hub remains playable")
	_check(wm.call("can_travel_to", "zambiapunga"), "Zambiapunga route remains playable")
	_check(wm.call("can_travel_to", "camamu_manguezal"), "Camamu region remains playable")
	var historical: Dictionary = {
		"current_hub": "salvador",
		"visited_hubs": ["itubera", "salvador", "zambiapunga"],
		"unlocked_hubs": ["itubera", "salvador", "zambiapunga", "camamu_manguezal"],
		"travel_log": [{"hub": "salvador", "week": 1, "day": "segunda", "cost": 80}]
	}
	wm.call("load_from_dict", historical)
	_check(str(wm.get("current_hub")) == "itubera", "legacy location migrated to Itubera")
	_check(str(world.get("current_hub")) == "itubera", "WorldState hub matches migrated map")
	_check(wm.get("visited_hubs").has("salvador"), "historical visited city retained without travel authority")
	_check(wm.get("travel_log").size() == 1, "historical travel history kept intact")
	_check(not wm.get("unlocked_hubs").has("salvador"), "legacy external unlock removed from playable routes")
	_check(not wm.call("can_travel_to", "salvador"), "legacy unlocked state cannot bypass region boundary")
	world.set("money", 100)
	var before_money := int(world.get("money"))
	var denied: Dictionary = wm.call("travel_to", "salvador")
	_check(not denied.get("ok", false), "external travel rejected before charging money")
	_check(int(world.get("money")) == before_money, "rejected external travel does not debit currency")
	_check(wm.get("travel_log").size() == 1, "rejected external travel does not change history")
	var snapshot: Dictionary = wm.call("to_dict")
	wm.call("reset")
	wm.call("load_from_dict", snapshot)
	_check(str(wm.get("current_hub")) == "itubera", "regional hub persists on state roundtrip")
	_check(not wm.get("unlocked_hubs").has("salvador"), "external location stays excluded on roundtrip")
	_check(wm.get("visited_hubs").has("salvador"), "read-only history survives state roundtrip")
	wm.call("load_from_dict", original_map)
	world.set("current_hub", original_world_hub)
	world.set("money", original_money)
	_finish()

func _finish() -> void:
	print("[BaixoSulTravel] checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
