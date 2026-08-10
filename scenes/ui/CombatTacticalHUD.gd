extends CanvasLayer
class_name CombatTacticalHUD

const VisualTheme = preload("res://src/ui/CriaVisualTheme.gd")

var tactical_steps: Array = []
var state_to_step: Dictionary = {}
var step_panels: Array[PanelContainer] = []
var step_labels: Array[Label] = []
var current_step := 0
var furthest_step := 0

@onready var position_label: Label = $LeftRail/Layout/Position
@onready var control_title: Label = $LeftRail/Layout/ControlTitle
@onready var control_bar: ProgressBar = $LeftRail/Layout/Control
@onready var moral_title: Label = $LeftRail/Layout/MoralTitle
@onready var moral_bar: ProgressBar = $LeftRail/Layout/Moral
@onready var technique_label: Label = $RightRail/Layout/Technique
@onready var phase_label: Label = $RightRail/Layout/Phase
@onready var defense_label: Label = $RightRail/Layout/Defense
@onready var outcome_label: Label = $RightRail/Layout/Outcome
@onready var steps_container: HBoxContainer = $FlowStrip/Layout/Steps


func _ready() -> void:
	_load_contract()
	_build_flow_steps()
	_style_hud()
	_connect_signals()
	_reset_hud()


func _load_contract() -> void:
	var contract: Dictionary = VisualTheme.protocol()
	tactical_steps = contract.get("combat_visual_flow", {}).get("tactical_steps", []).duplicate(true)
	state_to_step.clear()
	for index in range(tactical_steps.size()):
		var step: Dictionary = tactical_steps[index]
		for state in step.get("states", []):
			state_to_step[str(state)] = index


func _build_flow_steps() -> void:
	for child in steps_container.get_children():
		child.queue_free()
	step_panels.clear()
	step_labels.clear()
	for index in range(tactical_steps.size()):
		var step: Dictionary = tactical_steps[index]
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.custom_minimum_size = Vector2(82, 44)
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.text = "%d  %s" % [index + 1, str(step.get("label", "ETAPA"))]
		VisualTheme.style_tactical_text(label, VisualTheme.OFF_WHITE, 10)
		panel.add_child(label)
		steps_container.add_child(panel)
		step_panels.append(panel)
		step_labels.append(label)


func _style_hud() -> void:
	$LeftRail.add_theme_stylebox_override("panel", VisualTheme.tactical_panel_style(VisualTheme.GOLD, 0.94))
	$RightRail.add_theme_stylebox_override("panel", VisualTheme.tactical_panel_style(VisualTheme.GOLD, 0.94))
	$FlowStrip.add_theme_stylebox_override("panel", VisualTheme.tactical_panel_style(VisualTheme.RIVER, 0.94))
	VisualTheme.style_tactical_text($LeftRail/Layout/Title, VisualTheme.HONOR, 13)
	VisualTheme.style_tactical_text($LeftRail/Layout/Objective, VisualTheme.OFF_WHITE, 11)
	VisualTheme.style_tactical_text($LeftRail/Layout/PositionTitle, VisualTheme.CYAN, 10)
	VisualTheme.style_tactical_text(position_label, VisualTheme.OFF_WHITE, 12)
	VisualTheme.style_tactical_text(control_title, VisualTheme.HONOR, 10)
	VisualTheme.style_tactical_text(moral_title, VisualTheme.HONOR, 10)
	VisualTheme.style_progress(control_bar, VisualTheme.CYAN)
	VisualTheme.style_progress(moral_bar, VisualTheme.HONOR)
	VisualTheme.style_tactical_text($RightRail/Layout/Title, VisualTheme.HONOR, 13)
	VisualTheme.style_tactical_text(technique_label, VisualTheme.OFF_WHITE, 15)
	VisualTheme.style_tactical_text(phase_label, VisualTheme.CYAN, 11)
	VisualTheme.style_tactical_text($RightRail/Layout/DefenseTitle, VisualTheme.CONFLICT, 10)
	VisualTheme.style_tactical_text(defense_label, VisualTheme.OFF_WHITE, 11)
	VisualTheme.style_tactical_text(outcome_label, Color("d7c88e"), 10)
	VisualTheme.style_tactical_text($FlowStrip/Layout/Title, VisualTheme.CYAN, 11)


func _connect_signals() -> void:
	if not SignalBus.combat_started.is_connected(_on_combat_started):
		SignalBus.combat_started.connect(_on_combat_started)
	if not SignalBus.combat_state_changed.is_connected(_on_state_changed):
		SignalBus.combat_state_changed.connect(_on_state_changed)
	if not SignalBus.resources_changed.is_connected(_on_resources_changed):
		SignalBus.resources_changed.connect(_on_resources_changed)
	if not SignalBus.technique_started.is_connected(_on_technique_started):
		SignalBus.technique_started.connect(_on_technique_started)
	if not SignalBus.technique_resolved.is_connected(_on_technique_resolved):
		SignalBus.technique_resolved.connect(_on_technique_resolved)
	if not SignalBus.combat_finished.is_connected(_on_combat_finished):
		SignalBus.combat_finished.connect(_on_combat_finished)


func _reset_hud() -> void:
	current_step = 0
	furthest_step = 0
	position_label.text = "EM PE - NEUTRO"
	technique_label.text = "LEITURA DE PEGADA"
	phase_label.text = "FASE: PREPARACAO"
	defense_label.text = "CEDO • PERFEITO • TARDE"
	outcome_label.text = "CONSTRUA POSICAO ANTES DE FORCAR."
	control_bar.value = 0.0
	moral_bar.value = 50.0
	_refresh_steps()


func _on_combat_started(_arena_id, _player_id, _opponent_id) -> void:
	_reset_hud()


func _on_state_changed(_old_state, new_state) -> void:
	var state := str(new_state)
	current_step = int(state_to_step.get(state, current_step))
	furthest_step = maxi(furthest_step, current_step)
	position_label.text = _readable_state(state)
	phase_label.text = "FASE: %s" % str(tactical_steps[current_step].get("label", "LEITURA")) if current_step < tactical_steps.size() else "FASE: LEITURA"
	_refresh_steps()


func _on_resources_changed(fighter_id, resources: Dictionary) -> void:
	if str(fighter_id) != "ruan_macacao":
		return
	var control := clampf(float(resources.get("control", resources.get("control_meter", 0.0))), 0.0, 100.0)
	var moral := clampf(float(resources.get("moral", 50.0)), 0.0, 100.0)
	control_bar.value = control
	moral_bar.value = moral
	control_title.text = "CONTROLE  %d%%" % int(round(control))
	moral_title.text = "MORAL / PUBLICO  %d%%" % int(round(moral))


func _on_technique_started(technique_id, actor_id) -> void:
	var technique: Dictionary = DataRegistry.get_technique(str(technique_id))
	technique_label.text = str(technique.get("nome", technique.get("name", str(technique_id)))).to_upper()
	phase_label.text = "FASE: PREPARACAO"
	if str(actor_id) == "ruan_macacao":
		defense_label.text = "BASE • CONTATO • ESTABILIZACAO"
		outcome_label.text = "EXECUTE COM CONTROLE; NAO FORCE A POSICAO."
	else:
		defense_label.text = "CEDO • PERFEITO • TARDE"
		outcome_label.text = "LEIA A ENTRADA E RESPONDA NA JANELA."


func _on_technique_resolved(result) -> void:
	if typeof(result) != TYPE_DICTIONARY:
		return
	var data: Dictionary = result
	var technique_id := str(data.get("technique_id", data.get("action_id", "")))
	var technique: Dictionary = DataRegistry.get_technique(technique_id)
	technique_label.text = str(data.get("nome", technique.get("nome", technique.get("name", technique_id)))).to_upper()
	var success := bool(data.get("success", false))
	phase_label.text = "FASE: %s" % ("ESTABILIZADA" if success else "DEFENDIDA")
	var frame_data: Dictionary = data.get("frame_data", {})
	var presentation: Dictionary = frame_data.get("presentation", {})
	var counter_window := int(presentation.get("counter_window_ms", 0))
	if counter_window > 0:
		defense_label.text = "JANELA DE CONTRA: %d ms" % counter_window
	elif success:
		defense_label.text = "POSICAO CONFIRMADA"
	else:
		defense_label.text = "DEFESA LEU A ENTRADA"
	var message := str(data.get("message", ""))
	outcome_label.text = message.replace("_", " ").to_upper() if message != "" else ("CONTROLE MANTIDO." if success else "VOLTE A BASE.")


func _on_combat_finished(result) -> void:
	if typeof(result) != TYPE_DICTIONARY:
		return
	var data: Dictionary = result
	technique_label.text = str(data.get("method", "ENCERRAMENTO TECNICO")).replace("_", " ").to_upper()
	phase_label.text = "FASE: RESPEITO E RECUPERACAO"
	defense_label.text = "TAP • ARBITRO • TEMPO/PONTOS"
	outcome_label.text = "A LUTA TERMINA; A INTEGRIDADE DOS DOIS CONTINUA."
	current_step = mini(4, tactical_steps.size() - 1)
	furthest_step = current_step
	_refresh_steps()


func _refresh_steps() -> void:
	for index in range(step_panels.size()):
		var accent := Color("4b4230")
		if index < current_step or index < furthest_step:
			accent = VisualTheme.token_color("respect_green", VisualTheme.MANGROVE)
		elif index == current_step:
			accent = VisualTheme.token_color("honor_gold", VisualTheme.HONOR)
		step_panels[index].add_theme_stylebox_override("panel", VisualTheme.tactical_step_style(accent, index == current_step))
		step_labels[index].add_theme_color_override("font_color", VisualTheme.OFF_WHITE if index <= furthest_step or index == current_step else Color("77736a"))


func _readable_state(state: String) -> String:
	var labels := {
		"PLAYER_STANDING_NEUTRAL": "EM PE - NEUTRO",
		"PLAYER_TOP_CLINCH": "CLINCH POR CIMA",
		"PLAYER_BOTTOM_CLINCH": "CLINCH POR BAIXO",
		"PLAYER_TOP_GUARD": "GUARDA POR CIMA",
		"PLAYER_BOTTOM_GUARD": "GUARDA POR BAIXO",
		"PLAYER_TOP_SIDE": "CONTROLE LATERAL",
		"PLAYER_BOTTOM_SIDE": "DEFESA LATERAL",
		"PLAYER_TOP_MOUNT": "MONTADA POR CIMA",
		"PLAYER_BOTTOM_MOUNT": "MONTADA POR BAIXO",
		"PLAYER_BACK_ATTACK": "ATACANDO AS COSTAS",
		"PLAYER_BACK_DEFENSE": "DEFENDENDO AS COSTAS",
		"PLAYER_SUBMISSION_ATTACK": "CONTROLE DE FINALIZACAO",
		"PLAYER_SUBMISSION_DEFENSE": "DEFESA DE FINALIZACAO"
	}
	return str(labels.get(state, state.replace("PLAYER_", "").replace("_", " ")))
