extends Control

const HUB_SCENE := "res://scenes/hubs/TerreiroDaLuta.tscn"

@onready var menu_buttons: VBoxContainer = $ContentPanel/Content/MenuButtons
@onready var options_panel: VBoxContainer = $ContentPanel/Content/OptionsPanel
@onready var new_game_button: Button = $ContentPanel/Content/MenuButtons/NewGame
@onready var continue_button: Button = $ContentPanel/Content/MenuButtons/Continue
@onready var options_button: Button = $ContentPanel/Content/MenuButtons/Options
@onready var audio_toggle_button: Button = $ContentPanel/Content/OptionsPanel/AudioToggle
@onready var options_back_button: Button = $ContentPanel/Content/OptionsPanel/Back

var _transitioning := false

func _ready() -> void:
	continue_button.disabled = not SaveManager.has_save(1)
	_connect_once(new_game_button, _on_new_game_pressed)
	_connect_once(continue_button, _on_continue_pressed)
	_connect_once(options_button, _on_options_pressed)
	_connect_once(audio_toggle_button, _on_audio_toggle_pressed)
	_connect_once(options_back_button, _on_options_back_pressed)
	_update_audio_label()

func _connect_once(button: Button, callback: Callable) -> void:
	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)

func _on_new_game_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	WorldState.reset_new_game()
	GameFlowManager.start_new_run()
	if not SaveManager.save_game(1):
		push_warning("[MainMenu] Novo jogo iniciado, mas o save inicial falhou.")
	_change_scene(HUB_SCENE)

func _on_continue_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	if SaveManager.has_save(1):
		if not SaveManager.load_game(1):
			push_warning("[MainMenu] Save inválido. Iniciando novo jogo.")
			WorldState.reset_new_game()
			GameFlowManager.start_new_run()
	else:
		WorldState.reset_new_game()
		GameFlowManager.start_new_run()
	_change_scene(HUB_SCENE)

func _change_scene(path: String) -> void:
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		_transitioning = false
		push_error("[MainMenu] Falha ao trocar para %s: %s" % [path, error_string(error)])

func _on_options_pressed() -> void:
	menu_buttons.visible = false
	options_panel.visible = true
	_update_audio_label()

func _on_options_back_pressed() -> void:
	options_panel.visible = false
	menu_buttons.visible = true

func _on_audio_toggle_pressed() -> void:
	AudioManager.enabled = not AudioManager.enabled
	_update_audio_label()

func _update_audio_label() -> void:
	if audio_toggle_button != null:
		audio_toggle_button.text = "ÁUDIO: %s" % ("LIGADO" if AudioManager.enabled else "DESLIGADO")
