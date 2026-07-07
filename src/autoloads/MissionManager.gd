extends Node

var current_mission_id := ""
var completed := []
var active_data := {}

func start_mission(mission_id: String) -> Dictionary:
	current_mission_id = mission_id
	active_data = _find_mission(mission_id)
	SignalBus.mission_started.emit(mission_id)
	return active_data

func complete_mission(mission_id := "") -> void:
	var id := mission_id if mission_id != "" else current_mission_id
	if id == "":
		return
	if not completed.has(id):
		completed.append(id)
	WorldState.completed_missions = completed.duplicate()
	SignalBus.mission_completed.emit(id)
	current_mission_id = ""
	active_data = {}

func apply_choice(choice_id: String) -> Dictionary:
	var bond := TinkerBondManager.apply_choice(choice_id)
	CriaLiveManager.generate_post("missao", {"choice_id": choice_id, "tinker_bond": bond})
	SaveManager.save_game(1)
	return bond

func _find_mission(mission_id: String) -> Dictionary:
	var path := "res://data/missions/story_missions_v01.json"
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	for mission in parsed.get("missions", []):
		if str(mission.get("id", "")) == mission_id:
			return mission
	return {}

func get_next_recommended_mission() -> String:
	var order := [
		"ato1_fica_no_chao_ou_levanta",
		"ato2_o_primeiro_video",
		"ato3_comunicado_ou_silencio",
		"ato4_contrato_de_sangue_frio",
		"ato5_quem_ficou"
	]
	for id in order:
		if not completed.has(id):
			return id
	return ""

func to_dict() -> Dictionary:
	return {"current_mission_id": current_mission_id, "completed": completed}

func load_from_dict(data: Dictionary) -> void:
	current_mission_id = str(data.get("current_mission_id", ""))
	completed = data.get("completed", [])
