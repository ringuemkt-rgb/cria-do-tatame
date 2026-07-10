extends Node
class_name CareerSaveStore

# Armazenamento modular para subsistemas de carreira.
# O singleton global SaveManager permanece em src/autoloads/SaveManager.gd.

const SAVE_ROOT := "user://careers/"
const DEFAULT_SLOT := "career_001"

func ensure_slot(slot_id: String = DEFAULT_SLOT) -> bool:
	var dir := DirAccess.open("user://")
	if dir == null:
		push_error("[CareerSaveStore] Nao foi possivel abrir user://")
		return false
	if not DirAccess.dir_exists_absolute(SAVE_ROOT):
		var root_error := dir.make_dir_recursive("careers")
		if root_error != OK and root_error != ERR_ALREADY_EXISTS:
			push_error("[CareerSaveStore] Falha ao criar diretorio raiz de saves")
			return false
	if not DirAccess.dir_exists_absolute(SAVE_ROOT + slot_id):
		var slot_error := dir.make_dir_recursive("careers/" + slot_id)
		if slot_error != OK and slot_error != ERR_ALREADY_EXISTS:
			push_error("[CareerSaveStore] Falha ao criar slot: " + slot_id)
			return false
	return true

func save_json(file_name: String, data: Dictionary, slot_id: String = DEFAULT_SLOT) -> bool:
	if not ensure_slot(slot_id):
		return false
	var path := SAVE_ROOT + slot_id + "/" + file_name
	var temp_path := path + ".tmp"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_error("[CareerSaveStore] Falha ao gravar: " + temp_path)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var rename_error := DirAccess.rename_absolute(temp_path, path)
	if rename_error != OK:
		push_error("[CareerSaveStore] Falha ao concluir save: " + path)
		return false
	return true

func load_json(file_name: String, fallback: Dictionary = {}, slot_id: String = DEFAULT_SLOT) -> Dictionary:
	if not ensure_slot(slot_id):
		return fallback.duplicate(true)
	var path := SAVE_ROOT + slot_id + "/" + file_name
	if not FileAccess.file_exists(path):
		save_json(file_name, fallback, slot_id)
		return fallback.duplicate(true)
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return fallback.duplicate(true)
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("[CareerSaveStore] Save invalido, usando fallback: " + path)
		return fallback.duplicate(true)
	return parsed

func append_log(file_name: String, entry: Dictionary, slot_id: String = DEFAULT_SLOT) -> void:
	var data := load_json(file_name, {"entries": []}, slot_id)
	if not data.has("entries") or typeof(data["entries"]) != TYPE_ARRAY:
		data["entries"] = []
	data["entries"].append(entry)
	save_json(file_name, data, slot_id)
