extends Node
class_name SaveManager

const SAVE_ROOT := "user://careers/"
const DEFAULT_SLOT := "career_001"

func ensure_slot(slot_id: String = DEFAULT_SLOT) -> void:
	var dir := DirAccess.open("user://")
	if dir == null:
		return
	if not DirAccess.dir_exists_absolute(SAVE_ROOT):
		dir.make_dir_recursive("careers")
	if not DirAccess.dir_exists_absolute(SAVE_ROOT + slot_id):
		dir.make_dir_recursive("careers/" + slot_id)

func save_json(file_name: String, data: Dictionary, slot_id: String = DEFAULT_SLOT) -> bool:
	ensure_slot(slot_id)
	var path := SAVE_ROOT + slot_id + "/" + file_name
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager failed to write: " + path)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	return true

func load_json(file_name: String, fallback: Dictionary = {}, slot_id: String = DEFAULT_SLOT) -> Dictionary:
	ensure_slot(slot_id)
	var path := SAVE_ROOT + slot_id + "/" + file_name
	if not FileAccess.file_exists(path):
		save_json(file_name, fallback, slot_id)
		return fallback.duplicate(true)
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return fallback.duplicate(true)
	return parsed

func append_log(file_name: String, entry: Dictionary, slot_id: String = DEFAULT_SLOT) -> void:
	var data := load_json(file_name, {"entries": []}, slot_id)
	if not data.has("entries"):
		data["entries"] = []
	data["entries"].append(entry)
	save_json(file_name, data, slot_id)
