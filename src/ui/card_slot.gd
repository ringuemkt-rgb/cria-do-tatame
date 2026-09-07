class_name CardSlot
extends PanelContainer
## Slot interativo da mão canônica do DeckManager.
## Fail-closed para formato, posição, unlock e recursos.

signal pressed_slot(card_id: String)

const VisualTheme = preload("res://src/ui/CriaVisualTheme.gd")

const STATE_LABELS := {
	"PLAYER_STANDING_NEUTRAL": "EM PÉ",
	"PLAYER_TOP_CLINCH": "CLINCH TOP",
	"PLAYER_BOTTOM_CLINCH": "CLINCH BOTTOM",
	"PLAYER_TOP_GUARD": "GUARDA TOP",
	"PLAYER_BOTTOM_GUARD": "GUARDA",
	"PLAYER_TOP_SIDE": "LATERAL TOP",
	"PLAYER_BOTTOM_SIDE": "LATERAL BOTTOM",
	"PLAYER_TOP_MOUNT": "MONTADA",
	"PLAYER_BOTTOM_MOUNT": "SOB MONTADA",
	"PLAYER_BACK_ATTACK": "COSTAS",
	"PLAYER_BACK_DEFENSE": "DEF. COSTAS",
	"PLAYER_SUBMISSION_ATTACK": "FINALIZAÇÃO",
	"PLAYER_SUBMISSION_DEFENSE": "DEF. FINALIZAÇÃO",
	"RESET": "RESET"
}

@onready var name_lbl: Label = %CardName
@onready var st_lbl: Label = %CardSt
@onready var pos_lbl: Label = %CardPos
@onready var fmt_lbl: Label = %CardFmt
@onready var icon_lbl: Label = %CardIcon
@onready var lock_ov: Label = %LockOverlay
@onready var rarity_badge: Label = %RarityBadge

var card_id: String = ""
var block_reason: String = ""
var _spec: Dictionary = {}

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	focus_mode = Control.FOCUS_ALL
	_apply_style(false, false)

func setup(
	spec: Dictionary,
	combat_format: String,
	resources: Dictionary,
	current_state: String,
	selected: bool = false
) -> void:
	_spec = spec.duplicate(true)
	card_id = str(spec.get("id", ""))
	name_lbl.text = str(spec.get("name", spec.get("pt", card_id if card_id != "" else "CARTA")))
	var technique := _get_technique(spec)
	var technique_gas := _technique_cost(technique, "gas")
	var activation: Dictionary = spec.get("activation_cost", {})
	var extra_focus := int(activation.get("focus", 0))
	var level := int(spec.get("level", 1))
	st_lbl.text = "⚡%d  F%d  ★%d" % [int(round(technique_gas)), extra_focus, level]
	pos_lbl.text = _position_label(spec.get("valid_states", []))
	var formats: Array = spec.get("formats", ["GI", "NO-GI"])
	fmt_lbl.text = "+".join(formats)
	icon_lbl.text = _category_icon(str(spec.get("category", "transicao")))
	var rarity := str(spec.get("rarity", "epica" if str(spec.get("category", "")) == "finalizacao" else "rara"))
	rarity_badge.text = "◆" if rarity == "epica" else "◇"
	rarity_badge.modulate = Color("8b00ff") if rarity == "epica" else VisualTheme.GOLD

	block_reason = _block_reason(spec, technique, combat_format, resources, current_state)
	lock_ov.visible = block_reason != ""
	lock_ov.text = "🔒\n%s" % block_reason if block_reason != "" else ""
	tooltip_text = block_reason if block_reason != "" else str(spec.get("note", ""))
	_apply_style(selected, block_reason != "")

func is_blocked() -> bool:
	return block_reason != ""

func _gui_input(event: InputEvent) -> void:
	if is_blocked():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed_slot.emit(card_id)
		accept_event()
	elif event is InputEventKey and event.pressed and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE):
		pressed_slot.emit(card_id)
		accept_event()

func _block_reason(
	spec: Dictionary,
	technique: Dictionary,
	combat_format: String,
	resources: Dictionary,
	current_state: String
) -> String:
	if card_id == "":
		return "CARD"
	if not bool(spec.get("unlocked", false)):
		return "LOCKED"
	var formats: Array = spec.get("formats", ["GI", "NO-GI"])
	if combat_format == "" or not formats.has(combat_format):
		return "FORMAT"
	var states: Array = spec.get("valid_states", [])
	if not states.is_empty() and not states.has(current_state):
		return "POSIÇÃO"
	var activation: Dictionary = spec.get("activation_cost", {})
	var total_gas := float(activation.get("gas", 0.0)) + _technique_cost(technique, "gas")
	var total_focus := float(activation.get("focus", 0.0)) + _technique_cost(technique, "focus")
	var total_moral := _technique_cost(technique, "moral")
	if float(resources.get("gas", 0.0)) < total_gas:
		return "STAMINA"
	if float(resources.get("focus", 0.0)) < total_focus:
		return "FOCO"
	if float(resources.get("moral", 0.0)) < total_moral:
		return "MORAL"
	return ""

func _get_technique(spec: Dictionary) -> Dictionary:
	if not has_node("/root/DataRegistry"):
		return {}
	var technique_id := str(spec.get("technique_id", ""))
	if technique_id == "":
		return {}
	return DataRegistry.get_technique(technique_id)

func _technique_cost(technique: Dictionary, resource: String) -> float:
	if technique.is_empty():
		return 0.0
	var cost: Dictionary = technique.get("cost", technique.get("custo", {}))
	if resource == "focus":
		return float(cost.get("focus", cost.get("foco", technique.get("focus_cost", 0.0))))
	return float(cost.get(resource, technique.get("%s_cost" % resource, 0.0)))

func _position_label(states_variant) -> String:
	var states: Array = states_variant if typeof(states_variant) == TYPE_ARRAY else []
	if states.is_empty():
		return "QUALQUER POS."
	var labels: Array[String] = []
	for state in states:
		labels.append(str(STATE_LABELS.get(str(state), str(state))))
	return " / ".join(labels)

func _category_icon(category: String) -> String:
	match category:
		"finalizacao": return "◈"
		"queda": return "▼"
		"passagem": return "→"
		"raspagem": return "↻"
		"controle": return "■"
		"defesa": return "◆"
		"pegada": return "✦"
		_: return "●"

func _apply_style(selected: bool, blocked: bool) -> void:
	if blocked:
		add_theme_stylebox_override("panel", VisualTheme.panel_style(0.92, Color("4a4a4a"), 2, 6))
		modulate = Color(0.48, 0.48, 0.48, 1.0)
	elif selected:
		add_theme_stylebox_override("panel", VisualTheme.panel_style(0.98, VisualTheme.HONOR, 3, 6))
		modulate = Color.WHITE
	else:
		add_theme_stylebox_override("panel", VisualTheme.panel_style(0.94, VisualTheme.GOLD, 2, 6))
		modulate = Color.WHITE
