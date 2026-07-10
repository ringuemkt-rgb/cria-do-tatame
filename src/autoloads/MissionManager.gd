extends Node

var current_mission_id: String = ""
var completed: Array = []
var active_data: Dictionary = {}

func start_mission(mission_id: String) -> Dictionary:
	current_mission_id = mission_id
	active_data = _find_mission(mission_id)
	SignalBus.mission_started.emit(mission_id)
	return active_data

func complete_mission(mission_id: String = "") -> void:
	var resolved_id: String = mission_id if mission_id != "" else current_mission_id
	if resolved_id == "":
		return
	if not completed.has(resolved_id):
		completed.append(resolved_id)
	WorldState.completed_missions = completed.duplicate()
	SignalBus.mission_completed.emit(resolved_id)
	current_mission_id = ""
	active_data = {}
	SaveManager.save_game(1)

func apply_choice(choice_id: String) -> Dictionary:
	var bond: Dictionary = TinkerBondManager.apply_choice(choice_id)
	CriaLiveManager.generate_post("missao", {"choice_id": choice_id, "tinker_bond": bond})
	SaveManager.save_game(1)
	return bond

func apply_mission_choice(choice_id: String) -> Dictionary:
	var choice: Dictionary = find_choice(current_mission_id, choice_id)
	if choice.is_empty():
		return apply_choice(choice_id)
	var effects: Dictionary = choice.get("effects", {}).duplicate(true)
	if choice.has("tinker_event"):
		effects["tinker_event"] = choice["tinker_event"]
	var faction_state: Dictionary = {}
	if has_node("/root/FactionManager"):
		faction_state = FactionManager.apply_choice_effects(effects)
	else:
		for axis_value in ["honra", "hype", "sombra", "legado", "moral", "raiz"]:
			var axis: String = str(axis_value)
			if effects.has(axis):
				WorldState.modify_reputation(axis, float(effects[axis]))
	if effects.has("tinker_event"):
		TinkerBondManager.apply_event(str(effects["tinker_event"]))
	CriaLiveManager.generate_post("missao_escolha", {"mission_id": current_mission_id, "choice_id": choice_id, "effects": effects})
	SaveManager.save_game(1)
	return {"choice": choice, "effects": effects, "faction_state": faction_state}

func find_choice(mission_id: String, choice_id: String) -> Dictionary:
	var mission: Dictionary = _find_mission(mission_id)
	for choice_value in mission.get("choices", []):
		if typeof(choice_value) != TYPE_DICTIONARY:
			continue
		var choice: Dictionary = choice_value
		if str(choice.get("id", "")) == choice_id:
			return choice
	return {}

func _find_mission(mission_id: String) -> Dictionary:
	var mission: Dictionary = DataRegistry.get_story_mission(mission_id)
	if not mission.is_empty():
		return mission
	mission = DataRegistry.get_faction_mission(mission_id)
	if not mission.is_empty():
		return mission
	for path_value in ["res://data/missions/missao_01_fica_no_chao.json", "res://data/missions/missao_04_contrato_sangue_frio.json"]:
		var path: String = str(path_value)
		if FileAccess.file_exists(path):
			var file := FileAccess.open(path, FileAccess.READ)
			if file == null:
				continue
			var parsed = JSON.parse_string(file.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY and str(parsed.get("id", "")) == mission_id:
				return parsed
	return {}

func get_next_recommended_mission() -> String:
	var order: Array[String] = [
		"ato1_fica_no_chao_ou_levanta",
		"ato2_o_primeiro_video",
		"aleluia_dizimo_do_campeao",
		"molho_festa_que_lava",
		"ato3_comunicado_ou_silencio",
		"laele_olho_que_tudo_ve",
		"ato4_contrato_de_sangue_frio",
		"ato5_quem_ficou"
	]
	for mission_id in order:
		if not completed.has(mission_id):
			return mission_id
	return ""

func to_dict() -> Dictionary:
	return {"current_mission_id": current_mission_id, "completed": completed}

func load_from_dict(data: Dictionary) -> void:
	current_mission_id = str(data.get("current_mission_id", ""))
	completed = data.get("completed", [])
