extends Node

signal flow_step_changed(step_id: String)
signal act_changed(act_id: String)
signal daily_slot_changed(slot_id: String)

var current_step := "main_menu"
var current_act := "ato_1_o_chao"
var current_slot := "manha"
var completed_steps := []
var flow_flags := {}

func _ready() -> void:
	if DataRegistry.validation_report.get("ok", true) == false:
		push_warning("[GameFlowManager] DataRegistry com pendencias: %s" % str(DataRegistry.validation_report.get("errors", [])))

func start_new_run() -> void:
	current_step = "main_menu"
	current_act = "ato_1_o_chao"
	current_slot = "manha"
	completed_steps = []
	flow_flags = {}
	flow_step_changed.emit(current_step)

func advance_to(step_id: String) -> void:
	if current_step != "" and not completed_steps.has(current_step):
		completed_steps.append(current_step)
	current_step = step_id
	flow_step_changed.emit(step_id)

func set_act(act_id: String) -> void:
	current_act = act_id
	act_changed.emit(act_id)

func set_daily_slot(slot_id: String) -> void:
	current_slot = slot_id
	daily_slot_changed.emit(slot_id)

func next_recommended_action() -> Dictionary:
	var flow: Dictionary = DataRegistry.complete_game_flow
	var slice: Dictionary = flow.get("vertical_slice_02", {})
	if current_act == "ato_1_o_chao":
		if not completed_steps.has("intro_terreiro"):
			return {"type": "cutscene", "id": "intro_terreiro"}
		if not completed_steps.has("primeiro_treino_basico"):
			return {"type": "training", "id": "repeticao_drill"}
		if not completed_steps.has("primeira_luta_davi"):
			return {"type": "combat", "opponent": "davi_relampago", "arena": "terreiro_da_luta"}
		if not completed_steps.has("primeiro_post_cria_live"):
			return {"type": "cria_live", "id": "post_luta_davi"}
	return {"type": "mission", "id": MissionManager.get_next_recommended_mission(), "slice_goal": slice.get("goal", "")}

func mark_flag(flag_id: String, value := true) -> void:
	flow_flags[flag_id] = value

func has_flag(flag_id: String) -> bool:
	return bool(flow_flags.get(flag_id, false))

func to_dict() -> Dictionary:
	return {"current_step": current_step, "current_act": current_act, "current_slot": current_slot, "completed_steps": completed_steps, "flow_flags": flow_flags}

func load_from_dict(data: Dictionary) -> void:
	current_step = str(data.get("current_step", "main_menu"))
	current_act = str(data.get("current_act", "ato_1_o_chao"))
	current_slot = str(data.get("current_slot", "manha"))
	completed_steps = data.get("completed_steps", [])
	flow_flags = data.get("flow_flags", {})
