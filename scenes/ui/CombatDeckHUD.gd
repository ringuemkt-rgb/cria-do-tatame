extends CanvasLayer

const VisualTheme = preload("res://src/ui/CriaVisualTheme.gd")

var card_buttons: Array[Button] = []
var current_state := "PLAYER_STANDING_NEUTRAL"
var v2_mode := false
var v2_hand: Array = []

func _ready() -> void:
	card_buttons.clear()
	for index in range(1, 7):
		card_buttons.append(get_node("Panel/Layout/Cards/Card%d" % index))
	$Panel.add_theme_stylebox_override("panel", VisualTheme.panel_style(0.92, VisualTheme.GOLD, 2, 8))
	VisualTheme.style_heading($Panel/Layout/Header/Title, 14, VisualTheme.HONOR)
	$Panel/Layout/Header/Clash.add_theme_color_override("font_color", VisualTheme.CYAN)
	for index in range(card_buttons.size()):
		VisualTheme.apply_action_button(card_buttons[index], VisualTheme.GOLD)
		card_buttons[index].pressed.connect(_on_card_pressed.bind(index))
	if not SignalBus.combat_deck_hand_changed.is_connected(_on_hand_changed):
		SignalBus.combat_deck_hand_changed.connect(_on_hand_changed)
	if not SignalBus.combat_state_changed.is_connected(_on_state_changed):
		SignalBus.combat_state_changed.connect(_on_state_changed)
	if not SignalBus.combat_v2_hand_changed.is_connected(_on_v2_hand_changed):
		SignalBus.combat_v2_hand_changed.connect(_on_v2_hand_changed)
	if not SignalBus.technique_clash_resolved.is_connected(_on_clash):
		SignalBus.technique_clash_resolved.connect(_on_clash)
	_on_hand_changed(DeckManager.get_hand(), DeckManager.selected_card_id)

func _on_hand_changed(hand: Array, selected_card_id: String) -> void:
	for index in range(card_buttons.size()):
		var button := card_buttons[index]
		if index >= hand.size():
			button.text = "—"
			button.disabled = true
			button.set_meta("card_id", "")
			continue
		var card: Dictionary = hand[index]
		var card_id := str(card.get("id", ""))
		var cost: Dictionary = card.get("activation_cost", {})
		var level := int(card.get("level", 1))
		button.text = "%s\n%s  F%d G%d" % [
			str(card.get("name", "Técnica")),
			"◆".repeat(level),
			int(cost.get("focus", 0)),
			int(cost.get("gas", 0))
		]
		button.set_meta("card_id", card_id)
		button.disabled = not _is_compatible(card)
		button.modulate = Color("ffd45a") if card_id == selected_card_id else Color.WHITE

func _on_card_pressed(index: int) -> void:
	if index < 0 or index >= card_buttons.size():
		return
	var card_id := str(card_buttons[index].get_meta("card_id", ""))
	if card_id == "":
		return
	if v2_mode:
		SignalBus.combat_v2_card_selected.emit(card_id)
	else:
		DeckManager.select_card(card_id)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("deck_card_1"):
		_on_card_pressed(0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("deck_card_2"):
		_on_card_pressed(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("deck_card_3"):
		_on_card_pressed(2)
		get_viewport().set_input_as_handled()

func _on_state_changed(_old_state, new_state) -> void:
	current_state = str(new_state)
	if v2_mode:
		_on_v2_hand_changed(v2_hand)
	else:
		_on_hand_changed(DeckManager.get_hand(), DeckManager.selected_card_id)

func _on_clash(result: Dictionary) -> void:
	var outcome := str(result.get("outcome", "contested"))
	var delta := float(result.get("delta", 0.0))
	match outcome:
		"critical_advantage": $Panel/Layout/Header/Clash.text = "DOMÍNIO TÉCNICO  %+0.1f" % delta
		"advantage": $Panel/Layout/Header/Clash.text = "VANTAGEM  %+0.1f" % delta
		"counter_window": $Panel/Layout/Header/Clash.text = "JANELA DE CONTRA  %+0.1f" % delta
		_: $Panel/Layout/Header/Clash.text = "DISPUTA  %+0.1f" % delta

func _is_compatible(card: Dictionary) -> bool:
	var states: Array = card.get("valid_states", [])
	return states.is_empty() or states.has(current_state)


func _on_v2_hand_changed(hand: Array) -> void:
	v2_mode = true
	v2_hand = hand.duplicate()
	var available_ids: Dictionary = {}
	for row_value in CombatManager.get_available_techniques():
		if typeof(row_value) == TYPE_DICTIONARY:
			available_ids[str(row_value.get("id", ""))] = true
	for index in range(card_buttons.size()):
		var button: Button = card_buttons[index]
		if index >= v2_hand.size():
			button.text = "—"
			button.disabled = true
			button.set_meta("card_id", "")
			continue
		var technique_id := str(v2_hand[index])
		var info: Dictionary = DataRegistry.get_technique(technique_id)
		button.text = str(info.get("nome", info.get("name", technique_id))).replace("_", " ")
		button.set_meta("card_id", technique_id)
		button.disabled = not available_ids.has(technique_id)
		button.modulate = Color.WHITE
