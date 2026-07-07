extends Node

const SAVE_PREFIX := "user://cria_save_"
const SAVE_SUFFIX := ".json"
const SAVE_PATH := "user://savegame.json"

func save_game(slot_id := 1):
	var data = WorldState.to_dict()
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

func has_save(slot_id := 1):
	return FileAccess.file_exists(SAVE_PREFIX + str(slot_id) + SAVE_SUFFIX)

func delete_save(slot_id := 1) -> void:
	var path = SAVE_PREFIX + str(slot_id) + SAVE_SUFFIX
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
