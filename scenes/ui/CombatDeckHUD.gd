extends CanvasLayer

const VisualTheme = preload("res://src/ui/CriaVisualTheme.gd")

var card_buttons: Array[Button] = []
var current_state := "PLAYER_STANDING_NEUTRAL"
var v2_mode := false
var v2_hand: Array = []
var defense_mode := false
var defense_options: Array = []
var _defense_choice_submitted := false
var _actions_enabled := true

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
	SignalBus.resources_changed.connect(_on_resources_changed)
	_on_hand_changed(DeckManager.get_hand(), DeckManager.selected_card_id)

func _on_hand_changed(hand: Array, selected_card_id: String) -> void:
	# Legacy deck signals may still arrive during a V2 fight. Never replace
	# the authoritative technique hand or the active defense choices.
	if defense_mode or v2_mode:
		return
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
		button.disabled = not _actions_enabled or not _is_compatible(card)
		button.modulate = Color("ffd45a") if card_id == selected_card_id else Color.WHITE

func _on_card_pressed(index: int) -> void:
	if index < 0 or index >= card_buttons.size():
		return
	# The player turn remains locked while Davi acts. Defense taps are
	# permitted only while the dedicated reaction window is visible.
	if card_buttons[index].disabled or (defense_mode and _defense_choice_submitted) or (not defense_mode and not _actions_enabled):
		return
	var card_id := str(card_buttons[index].get_meta("card_id", ""))
	if card_id == "":
		return
	if defense_mode:
		# Consume the reaction before notifying listeners: queued/double taps must
		# never submit a second defense for the same AI attack.
		_defense_choice_submitted = true
		for button in card_buttons:
			button.disabled = true
		$Panel/Layout/Header/Clash.text = "DEFESA ENVIADA"
		SignalBus.combat_v2_defense_selected.emit(card_id)
	elif v2_mode:
		SignalBus.combat_v2_card_selected.emit(card_id)
	else:
		DeckManager.select_card(card_id)

func _unhandled_input(event: InputEvent) -> void:
	# One input path for all six visible V2 slots, including timed defenses.
	# Touch remains bound to each Button.pressed; invalid/locked slots still
	# pass through _on_card_pressed and cannot bypass its guards.
	for index in range(card_buttons.size()):
		if event.is_action_pressed("deck_card_%d" % (index + 1)):
			_on_card_pressed(index)
			get_viewport().set_input_as_handled()
			return

func _on_state_changed(_old_state, new_state) -> void:
	current_state = str(new_state)
	if defense_mode:
		return
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
	if defense_mode:
		return
	var available_ids: Dictionary = {}
	for row_value in CombatManager.get_available_techniques():
		if typeof(row_value) == TYPE_DICTIONARY and bool(row_value.get("affordable", false)):
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
		button.disabled = not _actions_enabled or not CombatManager.is_running or not available_ids.has(technique_id)
		button.modulate = Color.WHITE

func open_defense_window(options: Array, seconds: float) -> void:
	_defense_choice_submitted = false
	defense_mode = true
	defense_options = options.duplicate(true)
	$Panel/Layout/Header/Title.text = "REACAO • DEFENDA AGORA"
	$Panel/Layout/Header/Clash.text = "JANELA %.1fs" % maxf(0.0, seconds)
	for index in range(card_buttons.size()):
		var button: Button = card_buttons[index]
		if index >= defense_options.size():
			button.text = "—"
			button.disabled = true
			button.set_meta("card_id", "")
			continue
		# Treat malformed reaction payloads as unavailable, never as actions.
		var option: Dictionary = defense_options[index] if typeof(defense_options[index]) == TYPE_DICTIONARY else {}
		var defense_id := str(option.get("id", ""))
		button.text = "DEFESA\n%s" % str(option.get("name", defense_id)).replace("_", " ")
		button.set_meta("card_id", defense_id)
		button.disabled = defense_id == ""
		button.modulate = Color.WHITE

func set_defense_window_remaining(seconds: float) -> void:
	if defense_mode and not _defense_choice_submitted:
		$Panel/Layout/Header/Clash.text = "JANELA %.1fs" % maxf(0.0, seconds)

func close_defense_window() -> void:
	if not defense_mode:
		return
	defense_mode = false
	_defense_choice_submitted = false
	defense_options.clear()
	$Panel/Layout/Header/Title.text = "MENTE NO TATAME • MÃO ATUAL"
	$Panel/Layout/Header/Clash.text = "AGUARDANDO DISPUTA"
	if v2_mode:
		_on_v2_hand_changed(v2_hand)
	else:
		_on_hand_changed(DeckManager.get_hand(), DeckManager.selected_card_id)

func set_actions_enabled(enabled: bool) -> void:
	_actions_enabled = enabled
	if defense_mode:
		if not enabled:
			return
		close_defense_window()
	if v2_mode:
		_on_v2_hand_changed(v2_hand)
	elif not enabled:
		for button in card_buttons:
			button.disabled = true
	else:
		_on_hand_changed(DeckManager.get_hand(), DeckManager.selected_card_id)

func _on_resources_changed(fighter_id, _resources) -> void:
	if defense_mode:
		return
	if v2_mode and str(fighter_id) == CombatManager.player_id:
		_on_v2_hand_changed(v2_hand)
