extends CanvasLayer

var estados_ptbr := {
	"PLAYER_STANDING_NEUTRAL": "EM PÉ • NEUTRO",
	"PLAYER_TOP_CLINCH": "CLINCH • POR CIMA",
	"PLAYER_BOTTOM_CLINCH": "CLINCH • POR BAIXO",
	"PLAYER_TOP_GUARD": "GUARDA • POR CIMA",
	"PLAYER_BOTTOM_GUARD": "GUARDA • POR BAIXO",
	"PLAYER_TOP_SIDE": "LATERAL • POR CIMA",
	"PLAYER_BOTTOM_SIDE": "LATERAL • POR BAIXO",
	"PLAYER_TOP_MOUNT": "MONTADA • POR CIMA",
	"PLAYER_BOTTOM_MOUNT": "MONTADA • POR BAIXO",
	"PLAYER_BACK_ATTACK": "COSTAS • ATACANDO",
	"PLAYER_BACK_DEFENSE": "COSTAS • DEFENDENDO",
	"PLAYER_SUBMISSION_ATTACK": "FINALIZAÇÃO • ATACANDO",
	"PLAYER_SUBMISSION_DEFENSE": "FINALIZAÇÃO • DEFENDENDO",
	"RESET": "REINICIANDO"
}

var barras_dinamicas := {}
var estado_label: Label
var mensagem_label: Label
var action_buttons: Array[Button] = []

func _ready() -> void:
	_build_fallback_ui_if_needed()
	_cache_action_buttons()
	if not SignalBus.resources_changed.is_connected(_on_resources_changed):
		SignalBus.resources_changed.connect(_on_resources_changed)
	if not SignalBus.combat_state_changed.is_connected(_on_combat_state_changed):
		SignalBus.combat_state_changed.connect(_on_combat_state_changed)

func _cache_action_buttons() -> void:
	action_buttons.clear()
	for index in range(1, 6):
		var button := get_node_or_null("CommandPlate/CommandBar/Action%d" % index) as Button
		if button != null:
			action_buttons.append(button)

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
	estado_label.text = "EM PÉ • NEUTRO"
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
	var translated := estados_ptbr.get(state_name, state_name.replace("_", " "))
	if has_node("TopBar/StateLabel"):
		$TopBar/StateLabel.text = translated
	elif estado_label != null:
		estado_label.text = translated
	_update_control_hint(translated)

func update_player_resources(resources: Dictionary) -> void:
	var hp := float(resources.get("health", resources.get("hp", 100)))
	var gas := float(resources.get("gas", 100))
	var guard_value := float(resources.get("guard", resources.get("guarda", 100)))
	var focus_value := float(resources.get("focus", resources.get("foco", 100)))
	var moral_value := float(resources.get("moral", 100))
	var control_value := float(resources.get("control", resources.get("control_meter", 0)))
	var grip_value := float(resources.get("grip_integrity", resources.get("integridade_pegada", 100)))

	_update_bar("TopBar/PlayerPanel/PlayerHP", hp, 100)
	_update_bar("TopBar/PlayerPanel/PlayerGas", gas, 100)
	_update_bar("TopBar/PlayerPanel/PlayerGuarda", guard_value, 100)
	_update_bar("TopBar/PlayerPanel/PlayerFoco", focus_value, 100)
	_update_bar("TopBar/PlayerPanel/PlayerMoral", moral_value, 100)
	_set_dynamic("HP", hp)
	_set_dynamic("Gás", gas)
	_set_dynamic("Guarda", guard_value)
	_set_dynamic("Foco", focus_value)
	_set_dynamic("Moral", moral_value)
	_set_dynamic("Controle", control_value)
	_set_dynamic("Pegada", grip_value)
	_set_label_text("ControlPanel/ControlStack/ControlValue", "%d%%" % roundi(abs(control_value)))
	_set_label_text("GripPanel/GripStack/GripValue", _grip_word(grip_value))
	_set_label_text("GripPanel/GripStack/GripHint", "INTEGRIDADE %d%%" % roundi(grip_value))

func update_opponent_resources(resources: Dictionary) -> void:
	_update_bar("TopBar/OpponentPanel/OpponentHP", resources.get("health", resources.get("hp", 100)), 100)
	_update_bar("TopBar/OpponentPanel/OpponentGas", resources.get("gas", 100), 100)

func update_round_timer(seconds_remaining: int, round_index: int, round_total: int = 3) -> void:
	var minutes := maxi(seconds_remaining, 0) / 60
	var seconds := maxi(seconds_remaining, 0) % 60
	_set_label_text("TopBar/TimerLabel", "%02d:%02d" % [minutes, seconds])
	_set_label_text("TopBar/OpponentPanel/RoundValue", "%d / %d" % [round_index, round_total])

func update_fighter_names(player_name: String, opponent_name: String, opponent_archetype: String = "RIVAL") -> void:
	_set_label_text("TopBar/PlayerPanel/PlayerName", player_name)
	_set_label_text("TopBar/OpponentPanel/OpponentName", opponent_name)
	_set_label_text("TopBar/OpponentPanel/OpponentStatus", opponent_archetype)

func update_context_actions(actions: Array) -> void:
	for index in range(action_buttons.size()):
		var button := action_buttons[index]
		if index >= actions.size():
			button.visible = false
			button.disabled = true
			continue
		var action_data = actions[index]
		button.visible = true
		button.disabled = not bool(action_data.get("enabled", true))
		button.text = _format_action_label(action_data)
		button.tooltip_text = str(action_data.get("description", ""))

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
		var bar := get_node(path) as ProgressBar
		bar.max_value = max_value
		bar.value = clampf(value, 0.0, max_value)

func _set_dynamic(label: String, value) -> void:
	if barras_dinamicas.has(label):
		barras_dinamicas[label].value = float(value)

func _set_label_text(path: String, value: String) -> void:
	var label := get_node_or_null(path) as Label
	if label != null:
		label.text = value

func _update_control_hint(state_text: String) -> void:
	_set_label_text("ControlPanel/ControlStack/ControlHint", state_text)

func _grip_word(value: float) -> String:
	if value >= 70.0:
		return "FORTE"
	if value >= 40.0:
		return "ESTÁVEL"
	if value >= 20.0:
		return "FRACA"
	return "QUEBRANDO"

func _format_action_label(action_data: Dictionary) -> String:
	var label := str(action_data.get("label", action_data.get("name", "AÇÃO"))).to_upper()
	var gas_cost := int(action_data.get("gas_cost", action_data.get("gas", 0)))
	if gas_cost > 0:
		return "%s\nGÁS %d" % [label, gas_cost]
	return label
