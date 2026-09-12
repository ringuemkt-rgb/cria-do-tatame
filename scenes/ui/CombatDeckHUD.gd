extends CanvasLayer

const VisualTheme = preload("res://src/ui/CriaVisualTheme.gd")
const PHASE_NAMES := ["DISTANCE", "GRIP", "CLINCH", "TAKEDOWN", "GROUND", "TRANSITION", "TECHNICAL", "RESET"]

@export_enum("GI", "NO-GI") var combat_format := "GI"

var card_slots: Array = []
var current_state := "PLAYER_STANDING_NEUTRAL"
var current_resources: Dictionary = {"gas": 0.0, "focus": 0.0, "moral": 0.0}

func _ready() -> void:
	card_slots = [
		$Panel/Layout/Cards/Card1,
		$Panel/Layout/Cards/Card2,
		$Panel/Layout/Cards/Card3,
		$Panel/Layout/Cards/Card4,
	]
	$Panel.add_theme_stylebox_override("panel", VisualTheme.panel_style(0.94, VisualTheme.GOLD, 2, 8))
	VisualTheme.style_heading($Panel/Layout/Header/Title, 14, VisualTheme.HONOR)
	$Panel/Layout/Header/Clash.add_theme_color_override("font_color", VisualTheme.CYAN)
	$Panel/Layout/Status/PositionLabel.add_theme_color_override("font_color", VisualTheme.OFF_WHITE)
	$Panel/Layout/Status/PhaseLabel.add_theme_color_override("font_color", VisualTheme.HONOR)
	$Panel/Layout/Status/DeckCount.add_theme_color_override("font_color", VisualTheme.CYAN)
	for slot in card_slots:
		slot.pressed_slot.connect(_on_card_pressed)
	if not SignalBus.combat_deck_hand_changed.is_connected(_on_hand_changed):
		SignalBus.combat_deck_hand_changed.connect(_on_hand_changed)
	if not SignalBus.combat_state_changed.is_connected(_on_state_changed):
		SignalBus.combat_state_changed.connect(_on_state_changed)
	if not SignalBus.technique_clash_resolved.is_connected(_on_clash):
		SignalBus.technique_clash_resolved.connect(_on_clash)
	if not SignalBus.resources_changed.is_connected(_on_resources_changed):
		SignalBus.resources_changed.connect(_on_resources_changed)
	if not SignalBus.technique_started.is_connected(_on_technique_started):
		SignalBus.technique_started.connect(_on_technique_started)
	DeckManager.set_combat_format(combat_format)
	_sync_from_runtime()
	_on_hand_changed(DeckManager.get_hand(), DeckManager.selected_card_id)

func _sync_from_runtime() -> void:
	if has_node("/root/CombatManager"):
		current_state = CombatManager.get_current_state_name()
		var fighter: Dictionary = CombatManager.fighters.get(CombatManager.player_id, {})
		if not fighter.is_empty():
			current_resources = fighter.duplicate(true)
	_refresh_status()

func _on_hand_changed(hand: Array, selected_card_id: String) -> void:
	for index in range(card_slots.size()):
		var slot = card_slots[index]
		if index >= hand.size():
			slot.visible = false
			continue
		slot.visible = true
		var card: Dictionary = hand[index]
		slot.setup(card, combat_format, current_resources, current_state, str(card.get("id", "")) == selected_card_id)
	_refresh_status()

func _on_card_pressed(card_id: String) -> void:
	if card_id == "":
		return
	DeckManager.select_card(card_id)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("deck_card_1"):
		_press_slot(0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("deck_card_2"):
		_press_slot(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("deck_card_3"):
		_press_slot(2)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("deck_card_4"):
		_press_slot(3)
		get_viewport().set_input_as_handled()

func _press_slot(index: int) -> void:
	if index < 0 or index >= card_slots.size():
		return
	var slot = card_slots[index]
	if slot.visible and not slot.is_blocked():
		_on_card_pressed(slot.card_id)

func _on_state_changed(_old_state, new_state) -> void:
	current_state = str(new_state)
	_on_hand_changed(DeckManager.get_hand(), DeckManager.selected_card_id)

func _on_resources_changed(fighter_id, resources: Dictionary) -> void:
	if not has_node("/root/CombatManager") or str(fighter_id) != str(CombatManager.player_id):
		return
	current_resources = resources.duplicate(true)
	_on_hand_changed(DeckManager.get_hand(), DeckManager.selected_card_id)

func _on_technique_started(technique_id, actor_id) -> void:
	if has_node("/root/CombatManager") and str(actor_id) == str(CombatManager.player_id):
		$Panel/Layout/Status/PhaseLabel.text = "FASE • %s" % str(technique_id).to_upper()

func _on_clash(result: Dictionary) -> void:
	var outcome := str(result.get("outcome", "contested"))
	var delta := float(result.get("delta", 0.0))
	match outcome:
		"critical_advantage": $Panel/Layout/Header/Clash.text = "DOMÍNIO TÉCNICO  %+0.1f" % delta
		"advantage": $Panel/Layout/Header/Clash.text = "VANTAGEM  %+0.1f" % delta
		"counter_window": $Panel/Layout/Header/Clash.text = "JANELA DE CONTRA  %+0.1f" % delta
		_: $Panel/Layout/Header/Clash.text = "DISPUTA  %+0.1f" % delta

func _refresh_status() -> void:
	$Panel/Layout/Header/Format.text = combat_format
	$Panel/Layout/Status/PositionLabel.text = "POS • %s" % current_state.replace("PLAYER_", "").replace("_", " ")
	if has_node("/root/CombatManager"):
		var phase_index := int(CombatManager.phase)
		if phase_index >= 0 and phase_index < PHASE_NAMES.size():
			$Panel/Layout/Status/PhaseLabel.text = "FASE • %s" % PHASE_NAMES[phase_index]
		else:
			$Panel/Layout/Status/PhaseLabel.text = "FASE • —"
	$Panel/Layout/Status/DeckCount.text = "DECK %d · MÃO %d" % [DeckManager.active_deck.size(), DeckManager.hand.size()]
