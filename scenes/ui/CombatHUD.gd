extends CanvasLayer

var estados_ptbr := {
	"PLAYER_STANDING_NEUTRAL": "EM PE - NEUTRO",
	"PLAYER_TOP_CLINCH": "CLINCH - POR CIMA",
	"PLAYER_BOTTOM_CLINCH": "CLINCH - POR BAIXO",
	"PLAYER_TOP_GUARD": "GUARDA - POR CIMA",
	"PLAYER_BOTTOM_GUARD": "GUARDA - POR BAIXO",
	"PLAYER_TOP_SIDE": "LATERAL - POR CIMA",
	"PLAYER_BOTTOM_SIDE": "LATERAL - POR BAIXO",
	"PLAYER_TOP_MOUNT": "MONTADA - POR CIMA",
	"PLAYER_BOTTOM_MOUNT": "MONTADA - POR BAIXO",
	"PLAYER_BACK_ATTACK": "COSTAS - ATACANDO",
	"PLAYER_BACK_DEFENSE": "COSTAS - DEFENDENDO",
	"PLAYER_SUBMISSION_ATTACK": "ENCERRAMENTO - ATACANDO",
	"PLAYER_SUBMISSION_DEFENSE": "ENCERRAMENTO - DEFENDENDO",
	"RESET": "REINICIANDO"
}

var barras_dinamicas := {}
var estado_label: Label
var mensagem_label: Label

func _ready() -> void:
	_build_fallback_ui_if_needed()
	if not SignalBus.resources_changed.is_connected(_on_resources_changed):
		SignalBus.resources_changed.connect(_on_resources_changed)
	if not SignalBus.combat_state_changed.is_connected(_on_combat_state_changed):
		SignalBus.combat_state_changed.connect(_on_combat_state_changed)

func _build_fallback_ui_if_needed() -> void:
	if has_node("TopBar"):
		return
	var top_bar := VBoxContainer.new()
	top_bar.name = "TopBar"
	top_bar.anchor_left = 0.02
	top_bar.anchor_right = 0.98
	top_bar.anchor_top = 0.02
	top_bar.anchor_bottom = 0.26
	add_child(top_bar)
	estado_label = Label.new()
	estado_label.name = "StateLabel"
	estado_label.text = "EM PE - NEUTRO"
	estado_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_bar.add_child(estado_label)
	var grid := GridContainer.new()
	grid.columns = 2
	top_bar.add_child(grid)
	for item in ["HP", "Gás", "Guarda", "Foco", "Moral", "Controle", "Pegada"]:
		var box := VBoxContainer.new()
		var label := Label.new()
		label.text = item
		var bar := ProgressBar.new()
		bar.max_value = 100
		bar.value = 100
		bar.custom_minimum_size = Vector2(260, 22)
		box.add_child(label)
		box.add_child(bar)
		grid.add_child(box)
		barras_dinamicas[item] = bar
	mensagem_label = Label.new()
	mensagem_label.name = "MessageLabel"
	mensagem_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mensagem_label.anchor_left = 0.2
	mensagem_label.anchor_right = 0.8
	mensagem_label.anchor_top = 0.76
	mensagem_label.anchor_bottom = 0.92
	add_child(mensagem_label)

func update_state(state_name: String) -> void:
	if has_node("TopBar/StateLabel"):
		$TopBar/StateLabel.text = estados_ptbr.get(state_name, state_name)
	elif estado_label != null:
		estado_label.text = estados_ptbr.get(state_name, state_name)

func update_player_resources(resources: Dictionary) -> void:
	_update_bar("TopBar/PlayerPanel/PlayerHP", resources.get("health", resources.get("hp", 100)), 100)
	_update_bar("TopBar/PlayerPanel/PlayerGas", resources.get("gas", 100), 100)
	_update_bar("TopBar/PlayerPanel/PlayerGuarda", resources.get("guard", resources.get("guarda", 100)), 100)
	_update_bar("TopBar/PlayerPanel/PlayerFoco", resources.get("focus", resources.get("foco", 100)), 100)
	_update_bar("TopBar/PlayerPanel/PlayerMoral", resources.get("moral", 100), 100)
	_set_dynamic("HP", resources.get("health", resources.get("hp", 100)))
	_set_dynamic("Gás", resources.get("gas", 100))
	_set_dynamic("Guarda", resources.get("guard", resources.get("guarda", 100)))
	_set_dynamic("Foco", resources.get("focus", resources.get("foco", 100)))
	_set_dynamic("Moral", resources.get("moral", 100))
	_set_dynamic("Controle", resources.get("control", resources.get("control_meter", 0)))
	_set_dynamic("Pegada", resources.get("grip_integrity", resources.get("integridade_pegada", 100)))

func update_opponent_resources(resources: Dictionary) -> void:
	_update_bar("TopBar/OpponentPanel/OpponentHP", resources.get("health", resources.get("hp", 100)), 100)
	_update_bar("TopBar/OpponentPanel/OpponentGas", resources.get("gas", 100), 100)

func show_message(msg: String, duration: float = 2.0) -> void:
	var label := get_node_or_null("MessageLabel")
	if label == null:
		label = mensagem_label
	if label == null:
		return
	label.text = msg
	await get_tree().create_timer(duration).timeout
	label.text = ""

func _on_resources_changed(fighter_id, resources: Dictionary) -> void:
	if str(fighter_id) == "ruan_macacao":
		update_player_resources(resources)
	else:
		update_opponent_resources(resources)

func _on_combat_state_changed(_old_state, new_state) -> void:
	update_state(str(new_state))

func _update_bar(path: String, value: float, max_value: float) -> void:
	if has_node(path):
		var bar = get_node(path)
		bar.max_value = max_value
		bar.value = value

func _set_dynamic(label: String, value) -> void:
	if barras_dinamicas.has(label):
		barras_dinamicas[label].value = float(value)
