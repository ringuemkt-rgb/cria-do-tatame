extends Node

const SAVE_VERSION := 2
const SAVE_PREFIX := "user://cria_save_"
const SAVE_SUFFIX := ".json"
const SAVE_PATH := "user://savegame.json"

func save_game(slot_id := 1) -> bool:
	var data: Dictionary = WorldState.to_dict()
	data["save_version"] = SAVE_VERSION
	data["saved_at"] = Time.get_datetime_string_from_system()
	if has_node("/root/TinkerBondManager"):
		data["tinker_bond"] = TinkerBondManager.to_dict()
	if has_node("/root/MissionManager"):
		data["mission_state"] = MissionManager.to_dict()
	if has_node("/root/FactionManager"):
		data["faction_state"] = FactionManager.to_dict()
	if has_node("/root/WorldMapManager"):
		data["world_map_state"] = WorldMapManager.to_dict()
	if has_node("/root/GearManager"):
		data["gear_state"] = GearManager.to_dict()
	if has_node("/root/TrainingManager"):
		data["training_state"] = TrainingManager.to_dict()
	if has_node("/root/HubActivityManager"):
		data["hub_activity_state"] = HubActivityManager.to_dict()
	if has_node("/root/CriaLiveInteractionManager"):
		data["cria_live_interaction_state"] = CriaLiveInteractionManager.to_dict()
	if has_node("/root/GameFlowManager"):
		data["game_flow_state"] = GameFlowManager.to_dict()
	var path := get_slot_path(slot_id)
	if not _write_atomic_json(path, data):
		push_error("[SaveManager] Falha ao salvar slot %s de forma atomica." % slot_id)
		return false
	SignalBus.save_completed.emit(slot_id)
	return true

func _write_atomic_json(final_path: String, data: Dictionary) -> bool:
	var temp_path := final_path + ".tmp"
	var backup_path := final_path + ".bak"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	file.close()

	var dir := DirAccess.open("user://")
	if dir == null:
		DirAccess.remove_absolute(temp_path)
		return false

	var final_name := final_path.get_file()
	var temp_name := temp_path.get_file()
	var backup_name := backup_path.get_file()
	if dir.file_exists(backup_name) and dir.remove(backup_name) != OK:
		dir.remove(temp_name)
		return false

	var had_final := dir.file_exists(final_name)
	if had_final:
		var backup_error := dir.rename(final_name, backup_name)
		if backup_error != OK:
			dir.remove(temp_name)
			return false

	var promote_error := dir.rename(temp_name, final_name)
	if promote_error != OK:
		if had_final and dir.file_exists(backup_name):
			dir.rename(backup_name, final_name)
		if dir.file_exists(temp_name):
			dir.remove(temp_name)
		return false

	if dir.file_exists(backup_name):
		dir.remove(backup_name)
	return true

func load_game(slot_id := 1) -> bool:
	var path := get_slot_path(slot_id)
	var parsed := _read_json_dictionary(path)
	if parsed.is_empty():
		var backup_path := path + ".bak"
		parsed = _read_json_dictionary(backup_path)
		if parsed.is_empty():
			return false
		# Recupera automaticamente o save principal a partir do backup valido.
		if not _write_atomic_json(path, parsed):
			push_warning("[SaveManager] Backup carregado, mas nao foi possivel restaurar o arquivo principal.")
	WorldState.load_from_dict(parsed)
	if parsed.has("tinker_bond") and has_node("/root/TinkerBondManager"):
		TinkerBondManager.load_from_dict(parsed["tinker_bond"])
	if parsed.has("mission_state") and has_node("/root/MissionManager"):
		MissionManager.load_from_dict(parsed["mission_state"])
	if parsed.has("faction_state") and has_node("/root/FactionManager"):
		FactionManager.load_from_dict(parsed["faction_state"])
	if parsed.has("world_map_state") and has_node("/root/WorldMapManager"):
		WorldMapManager.load_from_dict(parsed["world_map_state"])
	if parsed.has("gear_state") and has_node("/root/GearManager"):
		GearManager.load_from_dict(parsed["gear_state"])
	if parsed.has("training_state") and has_node("/root/TrainingManager"):
		TrainingManager.load_from_dict(parsed["training_state"])
	if parsed.has("hub_activity_state") and has_node("/root/HubActivityManager"):
		HubActivityManager.load_from_dict(parsed["hub_activity_state"])
	if parsed.has("cria_live_interaction_state") and has_node("/root/CriaLiveInteractionManager"):
		CriaLiveInteractionManager.load_from_dict(parsed["cria_live_interaction_state"])
	if parsed.has("game_flow_state") and has_node("/root/GameFlowManager"):
		GameFlowManager.load_from_dict(parsed["game_flow_state"])
	SignalBus.save_loaded.emit(slot_id)
	return true

func _read_json_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var raw := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("[SaveManager] Save invalido em %s." % path)
		return {}
	return parsed

func get_slot_path(slot_id := 1) -> String:
	return SAVE_PREFIX + str(slot_id) + SAVE_SUFFIX

func has_save(slot_id := 1) -> bool:
	return FileAccess.file_exists(get_slot_path(slot_id))

func delete_save(slot_id := 1) -> void:
	var path := get_slot_path(slot_id)
	for candidate in [path, path + ".tmp", path + ".bak"]:
		if FileAccess.file_exists(candidate):
			DirAccess.remove_absolute(candidate)

func salvar_jogo() -> bool:
	return save_game(1)

func carregar_jogo() -> bool:
	return load_game(1)

func tem_save() -> bool:
	return has_save(1)

func deletar_save() -> void:
	delete_save(1)
