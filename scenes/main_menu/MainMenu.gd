extends Control

const HUB_SCENE := "res://scenes/hubs/TerreiroDaLuta.tscn"

func _ready() -> void:
	$MenuButtons/NewGame.pressed.connect(_on_new_game_pressed)
	$MenuButtons/Continue.pressed.connect(_on_continue_pressed)

func _on_new_game_pressed() -> void:
	WorldState.reset_new_game()
	SaveManager.save_game(1)
	get_tree().change_scene_to_file(HUB_SCENE)

func _on_continue_pressed() -> void:
	if SaveManager.has_save(1):
		SaveManager.load_game(1)
	else:
		WorldState.reset_new_game()
	get_tree().change_scene_to_file(HUB_SCENE)
