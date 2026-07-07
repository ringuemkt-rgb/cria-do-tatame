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
	SaveManager.save_game(1)

func apply_choice(choice_id: String) -> Dictionary:
	var bond := TinkerBondManager.apply_choice(choice_id)
	CriaLiveManager.generate_post("missao", {"choice_id": choice_id, "tinker_bond": bond})
	SaveManager.save_game(1)
	return bond

func apply_mission_choice(choice_id: String) -> Dictionary:
	var choice := find_choice(current_mission_id, choice_id)
	if choice.is_empty():
		return apply_choice(choice_id)
	var effects: Dictionary = choice.get("effects", {})
	if choice.has("tinker_event"):
		effects["tinker_event"] = choice["tinker_event"]
	var faction_state := {}
	if has_node("/root/FactionManager"):
		faction_state = FactionManager.apply_choice_effects(effects)
	else:
		for axis in ["honra", "hype", "sombra", "legado", "moral", "raiz"]:
			if effects.has(axis):
				WorldState.modify_reputation(axis, float(effects[axis]))
	if effects.has("tinker_event"):
		TinkerBondManager.apply_event(str(effects["tinker_event"]))
	CriaLiveManager.generate_post("missao_escolha", {"mission_id": current_mission_id, "choice_id": choice_id, "effects": effects})
	SaveManager.save_game(1)
	return {"choice": choice, "effects": effects, "faction_state": faction_state}

func find_choice(mission_id: String, choice_id: String) -> Dictionary:
	var mission := _find_mission(mission_id)
	for choice in mission.get("choices", []):
		if str(choice.get("id", "")) == choice_id:
			return choice
	return {}

func _find_mission(mission_id: String) -> Dictionary:
	var mission := DataRegistry.get_story_mission(mission_id)
	if not mission.is_empty():
		return mission
	mission = DataRegistry.get_faction_mission(mission_id)
	if not mission.is_empty():
		return mission
	for path in ["res://data/missions/missao_01_fica_no_chao.json", "res://data/missions/missao_04_contrato_sangue_frio.json"]:
		if FileAccess.file_exists(path):
			var file := FileAccess.open(path, FileAccess.READ)
			var parsed = JSON.parse_string(file.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY and str(parsed.get("id", "")) == mission_id:
				return parsed
	return {}

func get_next_recommended_mission() -> String:
	var order := [
		"ato1_fica_no_chao_ou_levanta",
		"ato2_o_primeiro_video",
		"aleluia_dizimo_do_campeao",
		"molho_festa_que_lava",
		"ato3_comunicado_ou_silencio",
		"laele_olho_que_tudo_ve",
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
