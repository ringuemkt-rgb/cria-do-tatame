class_name MapPage
extends Control

signal map_node_selected(node_id: String)
signal page_anchor_selected(page_id: String)

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
	if not is_node_ready():
		return
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
		pending_label.visible = false
	else:
		base_texture.texture = null
		pending_label.visible = true
		pending_label.text = "BASE VISUAL PENDENTE DE INGESTÃO\n%s" % base_path

	for anchor_value in _anchors:
		var anchor: Dictionary = anchor_value
		_add_anchor_button(anchor)
	for node_value in _nodes:
		var node: Dictionary = node_value
		_add_node_button(node)

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
	button.pressed.connect(func(): map_node_selected.emit(node_id))

func _make_button(item: Dictionary, label: String) -> Button:
	var pos_value = item.get("pos", [0.5, 0.5])
	var x := clamp(float(pos_value[0]), 0.0, 1.0)
	var y := clamp(float(pos_value[1]), 0.0, 1.0)
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
