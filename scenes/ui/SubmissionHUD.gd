extends CanvasLayer
class_name SubmissionHUD

const VisualTheme = preload("res://src/ui/CriaVisualTheme.gd")

@onready var panel: Panel = $Panel
@onready var technique_label: Label = $Panel/Layout/Technique
@onready var phase_label: Label = $Panel/Layout/Phase
@onready var target_label: Label = $Panel/Layout/Target
@onready var control_title: Label = $Panel/Layout/ControlTitle
@onready var control_bar: ProgressBar = $Panel/Layout/Control
@onready var escape_title: Label = $Panel/Layout/EscapeTitle
@onready var escape_bar: ProgressBar = $Panel/Layout/Escape
@onready var mediator_label: Label = $Panel/Layout/Mediator
@onready var safety_label: Label = $Panel/Layout/Safety

func _ready() -> void:
	visible = false
	_style_hud()
	if not SignalBus.submission_exchange_changed.is_connected(_on_exchange_changed):
		SignalBus.submission_exchange_changed.connect(_on_exchange_changed)
	if not SignalBus.submission_resolved.is_connected(_on_submission_resolved):
		SignalBus.submission_resolved.connect(_on_submission_resolved)
	if not SignalBus.combat_finished.is_connected(_on_combat_finished):
		SignalBus.combat_finished.connect(_on_combat_finished)

func _style_hud() -> void:
	panel.add_theme_stylebox_override("panel", VisualTheme.tactical_panel_style(VisualTheme.CONFLICT, 0.97))
	VisualTheme.style_tactical_text($Panel/Layout/Title, VisualTheme.HONOR, 13)
	VisualTheme.style_tactical_text(technique_label, VisualTheme.OFF_WHITE, 16)
	VisualTheme.style_tactical_text(phase_label, VisualTheme.CYAN, 11)
	VisualTheme.style_tactical_text(target_label, Color("d7c88e"), 10)
	VisualTheme.style_tactical_text(control_title, VisualTheme.CONFLICT, 10)
	VisualTheme.style_tactical_text(escape_title, VisualTheme.CYAN, 10)
	VisualTheme.style_progress(control_bar, VisualTheme.CONFLICT)
	VisualTheme.style_progress(escape_bar, VisualTheme.CYAN)
	VisualTheme.style_tactical_text(mediator_label, VisualTheme.HONOR, 10)
	VisualTheme.style_tactical_text(safety_label, VisualTheme.OFF_WHITE, 9)

func _on_exchange_changed(snapshot) -> void:
	if typeof(snapshot) != TYPE_DICTIONARY:
		return
	var data: Dictionary = snapshot
	visible = bool(data.get("active", false))
	if not visible:
		return
	technique_label.text = str(data.get("display_name", "FINALIZACAO")).to_upper()
	phase_label.text = "FASE: %s" % _phase_label(str(data.get("phase", "setup")))
	target_label.text = "FOCO TECNICO: %s" % _target_label(str(data.get("target_region", "")))
	var control := clampf(float(data.get("technical_control", 0.0)), 0.0, 100.0)
	var escape := clampf(float(data.get("escape_progress", 0.0)), 0.0, 100.0)
	control_bar.value = control
	escape_bar.value = escape
	control_title.text = "CONTROLE TECNICO  %d%%" % int(round(control))
	escape_title.text = "PROGRESSO DE ESCAPE  %d%%" % int(round(escape))
	mediator_label.text = "SEGURANCA: %s" % _mediator_label(str(data.get("intervention_role", "corner_mediator")))
	safety_label.text = str(data.get("safety_copy", "Respeite o tap."))

func _on_submission_resolved(_result) -> void:
	visible = false

func _on_combat_finished(_result) -> void:
	visible = false

func _phase_label(value: String) -> String:
	var labels := {
		"setup": "PREPARACAO",
		"lock": "CONTROLE ESTABELECIDO",
		"technical_pressure": "PRESSAO TECNICA",
		"tap_or_escape": "TAP OU ESCAPE",
		"referee_or_recovery": "MEDIACAO E RECUPERACAO"
	}
	return str(labels.get(value, value.replace("_", " ").to_upper()))

func _target_label(value: String) -> String:
	var labels := {
		"elbow_and_shoulder_chain": "CADEIA BRACO / OMBRO",
		"neck_and_posture_chain": "POSTURA / PESCOCO",
		"neck_and_upper_torso": "POSTURA / TRONCO",
		"shoulder_chain": "CADEIA DO OMBRO",
		"ankle_and_knee_chain": "CADEIA PERNA / JOELHO",
		"knee_and_hip_chain": "CADEIA QUADRIL / JOELHO",
		"knee_and_lower_leg_chain": "CADEIA DO MEMBRO INFERIOR"
	}
	return str(labels.get(value, "ALINHAMENTO POSICIONAL"))

func _mediator_label(value: String) -> String:
	var labels := {
		"referee": "ARBITRO PRESENTE",
		"instructor": "INSTRUTOR PRESENTE",
		"community_mediator": "MEDIADOR PRESENTE",
		"event_mediator": "MEDIADOR DO EVENTO",
		"corner_mediator": "CANTO RESPONSAVEL"
	}
	return str(labels.get(value, "MEDIACAO ATIVA"))
