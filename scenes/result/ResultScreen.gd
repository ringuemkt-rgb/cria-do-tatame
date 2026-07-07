extends Control

const HUB_SCENE := "res://scenes/hubs/TerreiroDaLuta.tscn"

func _ready() -> void:
	if has_node("Panel/Result"):
		$Panel/Result.text = "Resultado: " + str(WorldState.last_combat_result)
	if has_node("Panel/BackToHub"):
		$Panel/BackToHub.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	CareerLoop.advance_day()
	SaveManager.save_game(1)
	get_tree().change_scene_to_file(HUB_SCENE)
