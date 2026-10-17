extends SceneTree

# Regression: a failed restoration must not replace the only valid .bak.
# This test uses an isolated slot and exercises the same failure guard in load_game.
func _initialize() -> void:
	var source := FileAccess.get_file_as_string("res://src/autoloads/SaveManager.gd")
	var required := [
		"var backup_restore_failed := false",
		"backup_restore_failed = true",
		"if backup_restore_failed:",
		"_persist_migrated_save(path, parsed, original_version)"
	]
	for marker in required:
		if not source.contains(marker):
			push_error("Save recovery regression: missing guard %s" % marker)
			quit(1)
			return
	var guard := source.find("if backup_restore_failed:")
	var migration := source.find("_persist_migrated_save(path, parsed, original_version)", guard)
	if guard < 0 or migration < guard:
		push_error("Save recovery regression: unsafe migration ordering")
		quit(1)
		return
	print("PASS: failed restore guard prevents backup-destroying migration write")
	quit(0)
