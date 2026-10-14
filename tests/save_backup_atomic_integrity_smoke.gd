extends SceneTree

# Isolated I/O regression. Never touches player slots.
const TEST_DIR := "user://qa_save_backup_integrity/"
const PRIMARY := TEST_DIR + "save.json"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TEST_DIR))
	var backup := PRIMARY + ".bak"
	var tmp := PRIMARY + ".tmp"
	for path in [PRIMARY, backup, tmp]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	var original := {"save_version": 5, "proof": "recoverable"}
	var file := FileAccess.open(backup, FileAccess.WRITE)
	if file == null:
		_fail("cannot create backup fixture")
		return
	file.store_string(JSON.stringify(original))
	file.close()
	file = FileAccess.open(PRIMARY, FileAccess.WRITE)
	if file == null:
		_fail("cannot create corrupt primary fixture")
		return
	file.store_string("{broken json")
	file.close()
	var manager := root.get_node_or_null("SaveManager")
	if manager == null:
		_fail("SaveManager autoload missing")
		return
	var accepted: bool = manager.call("_write_atomic_json", PRIMARY, {"save_version": 6, "proof": "replacement"})
	var backup_data = JSON.parse_string(FileAccess.get_file_as_string(backup))
	var primary_data := FileAccess.get_file_as_string(PRIMARY)
	var valid := not accepted and typeof(backup_data) == TYPE_DICTIONARY and backup_data == original and primary_data == "{broken json"
	for path in [PRIMARY, backup, tmp]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_DIR))
	if not valid:
		_fail("corrupt primary overwrote valid backup")
		return
	print("PASS: valid backup preserved and corrupt primary not promoted")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
