extends Control

const COMBAT_SCENE := "res://scenes/combat/CombatArenaBase.tscn"

func _ready() -> void:
	if has_node("Panel/StartCombat"):
		$Panel/StartCombat.pressed.connect(_on_start_combat_pressed)
	if has_node("Panel/AdvanceWeek"):
		$Panel/AdvanceWeek.pressed.connect(_on_advance_week_pressed)
	_update_labels()

func _on_start_combat_pressed() -> void:
	get_tree().change_scene_to_file(COMBAT_SCENE)

func _on_advance_week_pressed() -> void:
	CareerLoop.advance_day()
	SaveManager.save_game(1)
	_update_labels()

func _update_labels() -> void:
	if has_node("Panel/Status"):
		$Panel/Status.text = "Semana %s • %s • Energia %s" % [WorldState.week, WorldState.days[WorldState.day_index], WorldState.energy]
