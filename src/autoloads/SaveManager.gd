extends Node

const SAVE_PREFIX := "user://cria_save_"
const SAVE_SUFFIX := ".json"
const SAVE_PATH := "user://savegame.json"

func save_game(slot_id := 1):
	var data = WorldState.to_dict()
	data["saved_at"] = Time.get_datetime_string_from_system()
	var path = SAVE_PREFIX + str(slot_id) + SAVE_SUFFIX
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("[SaveManager] Falha ao salvar.")
		return false
	file.store_string(JSON.stringify(data, "\t"))
	SignalBus.save_completed.emit(slot_id)
	return true

func load_game(slot_id := 1):
	var path = SAVE_PREFIX + str(slot_id) + SAVE_SUFFIX
	if not FileAccess.file_exists(path):
		return false
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("[SaveManager] Save invalido.")
		return false
	WorldState.load_from_dict(parsed)
	SignalBus.save_loaded.emit(slot_id)
	return true

func has_save(slot_id := 1):
	return FileAccess.file_exists(SAVE_PREFIX + str(slot_id) + SAVE_SUFFIX)

func delete_save(slot_id := 1) -> void:
	var path = SAVE_PREFIX + str(slot_id) + SAVE_SUFFIX
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
