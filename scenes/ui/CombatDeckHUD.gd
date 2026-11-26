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

# Keep six card hit targets usable when the Android viewport becomes narrow.
# This is layout only: the same buttons and guarded input path remain active.
func _apply_responsive_layout() -> void:
	_apply_responsive_layout_for_size(get_viewport().get_visible_rect().size)

func _apply_responsive_layout_for_size(viewport_size: Vector2) -> void:
	var panel: Panel = $Panel
	var grid: GridContainer = $Panel/Layout/Cards
	var compact: bool = viewport_size.x < 960.0 or viewport_size.y < 600.0
	var three_columns: bool = viewport_size.y > viewport_size.x or viewport_size.x < 720.0
	grid.columns = 3 if three_columns else 6
	if compact:
		var panel_height := 202.0 if three_columns else 126.0
		panel.anchor_left = 0.02
		panel.anchor_right = 0.98
		panel.anchor_top = 1.0
		panel.anchor_bottom = 1.0
		panel.offset_left = 0.0
		panel.offset_right = 0.0
		panel.offset_top = -panel_height - 12.0
		panel.offset_bottom = -12.0
	else:
		# Preserve the approved desktop composition at 1280x720.
		panel.anchor_left = 0.49
		panel.anchor_right = 0.98
		panel.anchor_top = 0.49
		panel.anchor_bottom = 0.655
		panel.offset_left = 0.0
		panel.offset_right = 0.0
		panel.offset_top = 0.0
		panel.offset_bottom = 0.0

func _ready() -> void:
	card_buttons.clear()
	for index in range(1, 7):
		card_buttons.append(get_node("Panel/Layout/Cards/Card%d" % index))
	$Panel.add_theme_stylebox_override("panel", VisualTheme.panel_style(0.92, VisualTheme.GOLD, 2, 8))
	VisualTheme.style_heading($Panel/Layout/Header/Title, 14, VisualTheme.HONOR)
	$Panel/Layout/Header/Clash.add_theme_color_override("font_color", VisualTheme.CYAN)
	for index in range(card_buttons.size()):
		VisualTheme.apply_action_button(card_buttons[index], VisualTheme.GOLD)
		card_buttons[index].custom_minimum_size = Vector2(48.0, 68.0)
		card_buttons[index].clip_text = true
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
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	_on_hand_changed(DeckManager.get_hand(), DeckManager.selected_card_id)

func _on_hand_changed(hand: Array, selected_card_id: String) -> void:
	# Legacy deck signals may still arrive during a V2 fight. Never replace
	# the authoritative technique hand or the active defense choices.
	if defense_mode or v2_mode:
		return
	for index in range(card_buttons.size()):
		var button := card_buttons[index]
		if index >= hand.size():
			_clear_slot(button)
			continue
		var card: Dictionary = hand[index] if typeof(hand[index]) == TYPE_DICTIONARY else {}
		var card_id := _valid_id(card.get("id", ""))
		if card_id.is_empty():
			_clear_slot(button)
			continue
		var raw_cost: Variant = card.get("activation_cost", {})
		var cost: Dictionary = raw_cost if typeof(raw_cost) == TYPE_DICTIONARY else {}
		var raw_level: Variant = card.get("level", 1)
		var level: int = clampi(int(raw_level), 0, 5) if typeof(raw_level) == TYPE_INT else 1
		button.text = "%s\n%s  F%d G%d" % [
			str(card.get("name", "Técnica")),
			"◆".repeat(level),
			_safe_display_cost(cost.get("focus", 0)),
			_safe_display_cost(cost.get("gas", 0))
		]
		button.tooltip_text = button.text.replace("\n", " • ")
		button.set_meta("card_id", card_id)
		button.disabled = not _actions_enabled or not _is_compatible(card)
		button.modulate = Color("ffd45a") if card_id == selected_card_id else Color.WHITE

func _on_card_pressed(index: int) -> void:
	if not visible or not is_inside_tree() or not $Panel.is_visible_in_tree():
		return
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
	if not visible or not is_inside_tree() or not $Panel.is_visible_in_tree() or event.is_echo():
		return
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
	var states: Variant = card.get("valid_states", [])
	return typeof(states) == TYPE_ARRAY and (states.is_empty() or states.has(current_state))


func _on_v2_hand_changed(hand: Array) -> void:
	v2_mode = true
	v2_hand = hand.duplicate()
	if defense_mode:
		return
	var available_ids: Dictionary = {}
	for row_value in CombatManager.get_available_techniques():
		if typeof(row_value) == TYPE_DICTIONARY and bool(row_value.get("affordable", false)):
			available_ids[_valid_id(row_value.get("id", ""))] = true
	for index in range(card_buttons.size()):
		var button: Button = card_buttons[index]
		if index >= v2_hand.size():
			_clear_slot(button)
			continue
		var technique_id := _valid_id(v2_hand[index])
		if technique_id.is_empty():
			_clear_slot(button)
			continue
		var info: Dictionary = DataRegistry.get_technique(technique_id)
		button.text = _format_v2_card_label(technique_id, info)
		button.tooltip_text = button.text.replace("\n", " • ")
		button.set_meta("card_id", technique_id)
		button.disabled = not _actions_enabled or not CombatManager.is_running or not available_ids.has(technique_id)
		button.modulate = Color.WHITE

# IDs are opaque: reject malformed values without rewriting canonical IDs.
func _valid_id(value: Variant) -> String:
	if typeof(value) != TYPE_STRING:
		return ""
	var id: String = value
	return id if not id.strip_edges().is_empty() else ""

func _clear_slot(button: Button) -> void:
	button.text = "—"
	button.tooltip_text = ""
	button.set_meta("card_id", "")
	button.disabled = true
	button.modulate = Color.WHITE

func _safe_display_cost(value: Variant) -> int:
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return 0
	var number := float(value)
	if not is_finite(number) or number < 0.0 or number > 2147483647.0:
		return 0
	return int(number)

func _format_v2_card_label(technique_id: String, info: Dictionary) -> String:
	var title := str(info.get("nome", info.get("name", technique_id))).replace("_", " ")
	var raw_cost: Variant = info.get("cost", info.get("custo", {}))
	var cost: Dictionary = raw_cost if typeof(raw_cost) == TYPE_DICTIONARY else {}
	var parts: Array[String] = []
	var gas := _safe_display_cost(cost.get("gas", info.get("gas_cost", 0)))
	var focus := _safe_display_cost(cost.get("focus", cost.get("foco", info.get("focus_cost", 0))))
	var moral := _safe_display_cost(cost.get("moral", info.get("moral_cost", 0)))
	if gas > 0:
		parts.append("G%d" % gas)
	if focus > 0:
		parts.append("F%d" % focus)
	if moral > 0:
		parts.append("M%d" % moral)
	return title if parts.is_empty() else title + "\n" + " ".join(parts)

func open_defense_window(options: Array, seconds: float) -> void:
	var valid_seconds := is_finite(seconds) and seconds > 0.0
	_defense_choice_submitted = false
	defense_mode = true
	defense_options = options.duplicate(true)
	$Panel/Layout/Header/Title.text = "REACAO • DEFENDA AGORA"
	$Panel/Layout/Header/Clash.text = "JANELA %.1fs" % seconds if valid_seconds else "JANELA ENCERRADA"
	for index in range(card_buttons.size()):
		var button: Button = card_buttons[index]
		if index >= defense_options.size():
			_clear_slot(button)
			continue
		# Treat malformed reaction payloads as unavailable, never as actions.
		var option: Dictionary = defense_options[index] if typeof(defense_options[index]) == TYPE_DICTIONARY else {}
		var defense_id := _valid_id(option.get("id", ""))
		if defense_id.is_empty():
			_clear_slot(button)
			continue
		button.text = "DEFESA\n%s" % str(option.get("name", defense_id)).replace("_", " ")
		button.tooltip_text = button.text.replace("\n", " • ")
		button.set_meta("card_id", defense_id)
		button.disabled = false
		button.modulate = Color.WHITE

	if not valid_seconds:
		_expire_defense_window()

func set_defense_window_remaining(seconds: float) -> void:
	if not defense_mode or _defense_choice_submitted:
		return
	if not is_finite(seconds) or seconds <= 0.0:
		_expire_defense_window()
	else:
		$Panel/Layout/Header/Clash.text = "JANELA %.1fs" % seconds

func _expire_defense_window() -> void:
	_defense_choice_submitted = true
	for button in card_buttons:
		button.disabled = true
	$Panel/Layout/Header/Clash.text = "JANELA ENCERRADA"

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
