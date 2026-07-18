extends Control

const HUB_SCENE := "res://scenes/hubs/TerreiroDaLuta.tscn"
const VisualTheme = preload("res://src/ui/CriaVisualTheme.gd")
const ArenaBackdropScript = preload("res://src/visual/ArenaBackdrop.gd")

@onready var menu_buttons: VBoxContainer = $Content/MenuButtons
@onready var options_panel: VBoxContainer = $Content/OptionsPanel
@onready var new_game_button: Button = $Content/MenuButtons/NewGame
@onready var continue_button: Button = $Content/MenuButtons/Continue
@onready var options_button: Button = $Content/MenuButtons/Options
@onready var audio_toggle_button: Button = $Content/OptionsPanel/AudioToggle
@onready var options_back_button: Button = $Content/OptionsPanel/Back

var _transitioning := false

func _ready() -> void:
	_build_premium_shell()
	continue_button.disabled = not SaveManager.has_save(1)
	_connect_once(new_game_button, _on_new_game_pressed)
	_connect_once(continue_button, _on_continue_pressed)
	_connect_once(options_button, _on_options_pressed)
	_connect_once(audio_toggle_button, _on_audio_toggle_pressed)
	_connect_once(options_back_button, _on_options_back_pressed)
	_update_audio_label()

func _build_premium_shell() -> void:
	var arena_backdrop := ArenaBackdropScript.new()
	arena_backdrop.name = "AnimatedTerreiroBackdrop"
	arena_backdrop.arena_id = "terreiro_da_luta"
	arena_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(arena_backdrop)
	move_child(arena_backdrop, 0)
	$Background.color = Color(0.02, 0.025, 0.03, 0.72)
	var frame := Panel.new()
	frame.name = "MenuFrame"
	frame.anchor_left = 0.5
	frame.anchor_top = 0.5
	frame.anchor_right = 0.5
	frame.anchor_bottom = 0.5
	frame.offset_left = -310.0
	frame.offset_top = -300.0
	frame.offset_right = 310.0
	frame.offset_bottom = 300.0
	frame.add_theme_stylebox_override("panel", VisualTheme.panel_style(0.90, VisualTheme.GOLD, 2, 12))
	add_child(frame)
	move_child(frame, get_node("Content").get_index())
	VisualTheme.style_heading($Content/Title, 42, VisualTheme.HONOR)
	$Content/Subtitle.add_theme_color_override("font_color", VisualTheme.OFF_WHITE)
	$Content/Subtitle.add_theme_font_size_override("font_size", 16)
	$Content/Quote.add_theme_color_override("font_color", Color("d7c88e"))
	$Content/Quote.add_theme_font_size_override("font_size", 18)
	for button in [new_game_button, continue_button, options_button, audio_toggle_button, options_back_button]:
		VisualTheme.apply_primary_button(button)
	$Content/OptionsPanel/OptionsTitle.add_theme_color_override("font_color", VisualTheme.HONOR)
	$Content/OptionsPanel/Version.add_theme_color_override("font_color", Color("9a9589"))

func _connect_once(button: Button, callback: Callable) -> void:
	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)

func _on_new_game_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	WorldState.reset_new_game()
	GameFlowManager.start_new_run()
	DeckManager.configure_from_data(DataRegistry.combat_deck)
	if not SaveManager.save_game(1):
		push_warning("[MainMenu] Novo jogo iniciado, mas o save inicial falhou.")
	_change_scene(HUB_SCENE)

func _on_continue_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	if SaveManager.has_save(1):
		if not SaveManager.load_game(1):
			push_warning("[MainMenu] Save invalido. Iniciando novo jogo.")
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
		audio_toggle_button.text = "AUDIO: %s" % ("LIGADO" if AudioManager.enabled else "DESLIGADO")
