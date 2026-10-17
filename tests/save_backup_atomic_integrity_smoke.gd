extends SceneTree

# Isolated I/O regression. Never touches player slots.
const PRIMARY := "user://qa_save_backup_integrity_20261016.json"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
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
	var backup_bytes := FileAccess.get_file_as_string(backup)
	var replacement := {"save_version": 6, "proof": "replacement"}
	var accepted: bool = manager.call("_write_atomic_json", PRIMARY, replacement)
	var preserved := FileAccess.get_file_as_string(backup) == backup_bytes
	var primary_data: Variant = JSON.parse_string(FileAccess.get_file_as_string(PRIMARY))
	var valid: bool = accepted and preserved and typeof(primary_data) == TYPE_DICTIONARY
	if typeof(primary_data) == TYPE_DICTIONARY:
		valid = valid and int(primary_data.get("save_version", 0)) == 6 and primary_data.get("proof") == "replacement"
	valid = valid and not FileAccess.file_exists(tmp)
	for path in [PRIMARY, backup, tmp]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	if not valid:
		_fail("replacement failed, backup changed, or temporary file leaked")
		return
	print("PASS: valid backup bytes preserved and replacement primary promoted")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
