class_name CombatHUDv2
extends CanvasLayer

signal phase_changed(phase: String)

enum Phase { EM_PE, SOLO }

var phase: Phase = Phase.EM_PE

@onready var stand_phase: Control = $StandPhaseHUD
@onready var ground_phase: Control = $GroundPhaseHUD
@onready var player_bar: ProgressBar = $StandPhaseHUD/Frame/Layout/ScoreRow/PlayerBlock/PlayerBar
@onready var enemy_bar: ProgressBar = $StandPhaseHUD/Frame/Layout/ScoreRow/EnemyBlock/EnemyBar
@onready var timer_label: Label = $StandPhaseHUD/Frame/Layout/ScoreRow/CenterBlock/Timer
@onready var environment_hand: HBoxContainer = $StandPhaseHUD/Frame/Layout/EnvironmentHand
@onready var position_label: Label = $GroundPhaseHUD/GroundFrame/GroundLayout/PositionRow/PositionLabel
@onready var dominance_meter: ProgressBar = $GroundPhaseHUD/GroundFrame/GroundLayout/DominanceMeter
@onready var technique_hand: HBoxContainer = $GroundPhaseHUD/GroundFrame/GroundLayout/TechniqueHand
@onready var gas_bar: ProgressBar = $GroundPhaseHUD/GroundFrame/GroundLayout/ResourceRow/GasBar
@onready var grip_label: Label = $GroundPhaseHUD/GroundFrame/GroundLayout/ResourceRow/GripLabel


func _ready() -> void:
	_set_phase(Phase.EM_PE)


func set_environment(cards: Array) -> void:
	_clear_container(environment_hand)
	for card_data in cards.slice(0, 3):
		environment_hand.add_child(_build_environment_card(card_data))


func enter_solo(position_name: String, dominance: float) -> void:
	_set_phase(Phase.SOLO)
	position_label.text = position_name
	dominance_meter.value = clampf(dominance, 0.0, 100.0)


func exit_to_standing() -> void:
	_set_phase(Phase.EM_PE)


func update_solo(position_name: String, dominance: float, gas: float, grip: String) -> void:
	position_label.text = position_name
	dominance_meter.value = clampf(dominance, 0.0, 100.0)
	gas_bar.value = clampf(gas, 0.0, 100.0)
	grip_label.text = "PEGADA: %s" % grip


func update_standing(player_value: float, enemy_value: float, time_seconds: float) -> void:
	player_bar.value = clampf(player_value, 0.0, 100.0)
	enemy_bar.value = clampf(enemy_value, 0.0, 100.0)
	var safe_seconds := maxi(0, int(time_seconds))
	timer_label.text = "%02d:%02d" % [safe_seconds / 60, safe_seconds % 60]


func update_hand(cards: Array) -> void:
	_clear_container(technique_hand)
	for card_data in cards.slice(0, 3):
		var button := Button.new()
		button.text = "%s\nGÁS %d" % [card_data.get("name_pt", "TÉCNICA"), int(card_data.get("gas", 0))]
		button.custom_minimum_size = Vector2(168, 72)
		button.tooltip_text = card_data.get("eligibility_reason", "Elegibilidade decidida pelo runtime")
		technique_hand.add_child(button)


func _set_phase(next_phase: Phase) -> void:
	phase = next_phase
	stand_phase.visible = phase == Phase.EM_PE
	ground_phase.visible = phase == Phase.SOLO
	phase_changed.emit("em_pe" if phase == Phase.EM_PE else "solo")


func _build_environment_card(card_data: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(184, 74)
	panel.tooltip_text = card_data.get("desc", "Modificador ambiental")
	var layout := VBoxContainer.new()
	var title := Label.new()
	title.text = "%s  %s" % [card_data.get("icon", "◆"), card_data.get("name", "AMBIENTE")]
	title.add_theme_font_size_override("font_size", 14)
	var description := Label.new()
	description.text = card_data.get("short_desc", card_data.get("desc", ""))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 10)
	layout.add_child(title)
	layout.add_child(description)
	panel.add_child(layout)
	return panel


func _clear_container(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
