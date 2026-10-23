extends SceneTree

# Isolated regression: migration must normalize playable map and retain history.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var save := root.get_node_or_null("SaveManager")
	var world := root.get_node_or_null("WorldState")
	var map := root.get_node_or_null("WorldMapManager")
	var progression := root.get_node_or_null("ProgressionOS")
	if save == null or world == null or map == null or progression == null:
		_fail("canonical autoload missing")
		return
	var original_world: Dictionary = world.to_dict()
	var original_map: Dictionary = map.to_dict()
	var original_progression: Dictionary = progression.to_dict()
	var failed := false
	for version in [5, 6]:
		var slot: int = -int(Time.get_ticks_usec()) - int(version)
		var path: String = save.get_slot_path(slot)
		var backup := path + ".bak"
		var temp := path + ".tmp"
		if FileAccess.file_exists(path) or FileAccess.file_exists(backup) or FileAccess.file_exists(temp):
			push_error("QA fixture collision; refusing overwrite")
			failed = true
			break
		var history := {"current_hub": "salvador", "visited_hubs": ["itubera", "salvador", "itacare"], "unlocked_hubs": ["itubera", "salvador", "itacare", "zambiapunga"], "travel_log": [{"hub": "salvador", "week": 1}], "historical_note": "preserve"}
		var fixture: Dictionary = world.to_dict()
		fixture["save_version"] = version
		fixture["progression_state"] = progression.to_dict()
		fixture["world_map_state"] = history
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			push_error("cannot create QA slot")
			failed = true
			break
		file.store_string(JSON.stringify(fixture))
		file.close()
		var loaded: bool = save.load_game(slot)
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		var valid := loaded and typeof(parsed) == TYPE_DICTIONARY
		if valid:
			var disk: Dictionary = parsed
			var regional: Dictionary = disk.get("world_map_state", {})
			valid = int(disk.get("save_version", 0)) == 6 and str(regional.get("current_hub", "")) == "itubera"
			valid = valid and not regional.get("unlocked_hubs", []).has("salvador") and not regional.get("unlocked_hubs", []).has("itacare")
			valid = valid and regional.get("visited_hubs", []).has("salvador") and regional.get("visited_hubs", []).has("itacare")
			valid = valid and str(regional.get("historical_note", "")) == "preserve"
		valid = valid and not map.can_travel_to("salvador") and not map.can_travel_to("itacare")
		if FileAccess.file_exists(backup):
			var previous: Variant = JSON.parse_string(FileAccess.get_file_as_string(backup))
			valid = valid and typeof(previous) == TYPE_DICTIONARY and previous.get("world_map_state", {}) == history
		else:
			valid = false
		for candidate in [path, backup, temp]:
			if FileAccess.file_exists(candidate):
				DirAccess.remove_absolute(candidate)
		world.load_from_dict(original_world)
		progression.load_from_dict(original_progression)
		map.load_from_dict(original_map)
		if not valid:
			push_error("regional migration regression at v%d" % version)
			failed = true
			break
	if failed:
		quit(1)
	else:
		print("[RegionalSaveV6] PASS")
		quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
