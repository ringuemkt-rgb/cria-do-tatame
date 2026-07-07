extends Control

func _ready() -> void:
	$MenuButtons/NewGame.pressed.connect(_on_new_game_pressed)
	$MenuButtons/Continue.pressed.connect(_on_continue_pressed)

func _on_new_game_pressed() -> void:
	print("new career")

func _on_continue_pressed() -> void:
	print("continue career")
