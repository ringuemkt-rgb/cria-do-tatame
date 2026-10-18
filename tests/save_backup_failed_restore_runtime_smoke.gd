extends SceneTree

# Fault-injection regression: a failed restore cannot consume the only valid .bak.
# The high-numbered temporary QA slot is checked for collisions before use.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var manager: Node = root.get_node_or_null("SaveManager")
	if manager == null:
		_fail("SaveManager autoload missing")
		return
	var slot: int = 900000000 + int(Time.get_ticks_usec() % 100000000)
	var path: String = manager.call("get_slot_path", slot)
	var backup: String = path + ".bak"
	var temp: String = path + ".tmp"
	if FileAccess.file_exists(path) or FileAccess.file_exists(backup) or FileAccess.file_exists(temp) or DirAccess.dir_exists_absolute(path):
		_fail("QA slot collision; no existing files touched")
		return
	if not manager.call("save_game", slot):
		_fail("could not create QA fixture")
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		_cleanup(path)
		_fail("fixture is not a dictionary")
		return
	var fixture: Dictionary = parsed
	fixture["save_version"] = 5
	var file := FileAccess.open(backup, FileAccess.WRITE)
	if file == null:
		_cleanup(path)
		_fail("cannot create QA backup")
		return
	file.store_string(JSON.stringify(fixture))
	file.close()
	var backup_bytes: String = FileAccess.get_file_as_string(backup)
	if DirAccess.remove_absolute(path) != OK or DirAccess.make_dir_absolute(path) != OK:
		_cleanup(path)
		_fail("could not install directory-based restore failure")
		return
	var loaded: bool = manager.call("load_game", slot)
	var preserved: bool = FileAccess.file_exists(backup) and FileAccess.get_file_as_string(backup) == backup_bytes
	var primary_blocked: bool = DirAccess.dir_exists_absolute(path)
	var temp_clean: bool = not FileAccess.file_exists(temp)
	_cleanup(path)
	if not (loaded and preserved and primary_blocked and temp_clean):
		_fail("failed restore must preserve backup and skip migration write")
		return
	print("[SaveFailedRestore] PASS: backup preserved; failed restore did not persist migration")
	quit(0)

func _cleanup(path: String) -> void:
	if DirAccess.dir_exists_absolute(path):
		DirAccess.remove_absolute(path)
	for candidate in [path, path + ".bak", path + ".tmp"]:
		if FileAccess.file_exists(candidate):
			DirAccess.remove_absolute(candidate)

func _fail(message: String) -> void:
	push_error("[SaveFailedRestore] " + message)
	quit(1)
