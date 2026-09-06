class_name MapPage
extends Control

signal map_node_selected(node_id: String)
signal page_anchor_selected(page_id: String)

const LOGICAL_SIZE := Vector2(1920.0, 1080.0)
const FACTION_COLORS := {"ALE": Color("#FF9408"), "LEM": Color("#4A6741"), "NTM": Color("#3FE3F5")}

@onready var base_texture: TextureRect = $BaseTexture
@onready var node_layer: Control = $NodeLayer
@onready var pending_label: Label = $PendingLabel

var _page: Dictionary = {}
var _anchors: Array = []
var _nodes: Array = []
var _evaluations: Dictionary = {}

func configure(page: Dictionary, anchors: Array, nodes: Array, evaluations: Dictionary) -> void:
	_page = page
	_anchors = anchors
	_nodes = nodes
	_evaluations = evaluations
	if is_node_ready():
		_apply_page()

func _ready() -> void:
	_apply_page()

func _apply_page() -> void:
	if not is_instance_valid(base_texture) or not is_instance_valid(node_layer):
		return
	for child in node_layer.get_children():
		child.queue_free()
	var base_path := str(_page.get("base", ""))
	if base_path != "" and ResourceLoader.exists(base_path):
		base_texture.texture = load(base_path)
		base_texture.modulate = Color.WHITE
		pending_label.visible = false
	else:
		base_texture.texture = null
		base_texture.modulate = Color("#16202A")
		pending_label.visible = true
		pending_label.text = "BASE VISUAL PENDENTE DE INGESTÃO\n%s" % base_path
	for anchor_value in _anchors:
		_add_anchor_button(anchor_value)
	for node_value in _nodes:
		_add_node_button(node_value)

func _add_anchor_button(anchor: Dictionary) -> void:
	var target_page := str(anchor.get("target_page", ""))
	var label := str(anchor.get("nome", anchor.get("id", "")))
	var button := _make_button(anchor, label)
	button.tooltip_text = "%s • abrir página %s" % [label, target_page]
	button.pressed.connect(func(): page_anchor_selected.emit(target_page))

func _add_node_button(node: Dictionary) -> void:
	var node_id := str(node.get("id", ""))
	var evaluation: Dictionary = _evaluations.get(node_id, {"unlocked": true, "reason": ""})
	var unlocked := bool(evaluation.get("unlocked", false))
	var label := str(node.get("nome", node_id))
	if not unlocked:
		label = "[LOCK] " + label
	var button := _make_button(node, label)
	button.tooltip_text = str(evaluation.get("reason", "")) if not unlocked else str(node.get("tipo", ""))
	var emblem_path := "res://assets/brand/arena_icons/%s.png" % str(node.get("emblema", ""))
	if ResourceLoader.exists(emblem_path):
		button.icon = load(emblem_path)
	var faction := str(node.get("faccao", ""))
	if FACTION_COLORS.has(faction):
		button.modulate = FACTION_COLORS[faction].lightened(0.15)
	button.pressed.connect(func(): map_node_selected.emit(node_id))

func _make_button(item: Dictionary, label: String) -> Button:
	var pos_value = item.get("pos", [0.5, 0.5])
	var raw_x := float(pos_value[0])
	var raw_y := float(pos_value[1])
	var x := raw_x / LOGICAL_SIZE.x if raw_x > 1.0 else raw_x
	var y := raw_y / LOGICAL_SIZE.y if raw_y > 1.0 else raw_y
	x = clamp(x, 0.0, 1.0)
	y = clamp(y, 0.0, 1.0)
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(112, 36)
	button.anchor_left = x
	button.anchor_right = x
	button.anchor_top = y
	button.anchor_bottom = y
	button.offset_left = -56.0
	button.offset_right = 56.0
	button.offset_top = -18.0
	button.offset_bottom = 18.0
	button.focus_mode = Control.FOCUS_ALL
	node_layer.add_child(button)
	return button
