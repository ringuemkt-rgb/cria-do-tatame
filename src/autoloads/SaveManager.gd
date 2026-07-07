extends Node

const SAVE_PREFIX := "user://cria_save_"
const SAVE_SUFFIX := ".json"

func save_game(slot_id := 1):
	var path = SAVE_PREFIX + str(slot_id) + SAVE_SUFFIX
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(WorldState.to_dict(), "\t"))
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
		return false
	WorldState.load_from_dict(parsed)
	SignalBus.save_loaded.emit(slot_id)
	return true

func has_save(slot_id := 1):
	return FileAccess.file_exists(SAVE_PREFIX + str(slot_id) + SAVE_SUFFIX)
