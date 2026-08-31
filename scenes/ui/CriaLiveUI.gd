extends Control

const HUB_SCENE := "res://scenes/hubs/TerreiroDaLuta.tscn"

func _ready() -> void:
	$CriaLiveV2/Header/Back.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(HUB_SCENE)
