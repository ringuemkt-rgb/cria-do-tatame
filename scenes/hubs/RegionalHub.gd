extends Control

@export var hub_id: String = ""
@export var hub_title: String = "TERRITÓRIO"
@export_multiline var hub_description: String = ""
@export var accent_color: Color = Color(0.84, 0.69, 0.22, 1.0)

const MAP_SCENE: String = "res://scenes/world/WorldMapScreen.tscn"
const CRIA_LIVE_SCENE: String = "res://scenes/ui/CriaLiveUI.tscn"
const MAIN_MENU_SCENE: String = "res://scenes/main_menu/MainMenu.tscn"
const NPCPresencePanelScript = preload("res://scenes/hubs/NPCPresencePanel.gd")
const VisualTheme = preload("res://src/ui/CriaVisualTheme.gd")
const FighterPlaceholderScript = preload("res://src/characters/FighterPlaceholder.gd")

const CHARACTER_ALIASES := {"cassio_molho_oliveira": "cassio_molho"}

var _transitioning: bool = false

func _ready() -> void:
	if hub_id == "":
		push_error("[RegionalHub] hub_id não configurado")
		return
	WorldMapManager.current_hub = hub_id
	WorldState.current_hub = hub_id
	_style_interface()
	_build_npc_presence()
	_build_representative_npc()
	_play_hub_ambience()
	_connect_if_exists("Panel/ExploreBtn", _on_explore)
	_connect_if_exists("Panel/RestBtn", _on_rest)
	_connect_if_exists("Panel/AdvanceDayBtn", _on_advance_day)
	_connect_if_exists("Panel/CriaLiveBtn", _on_cria_live)
	_connect_if_exists("Panel/MapBtn", _on_map)
	_connect_if_exists("Panel/SaveBtn", _on_save)
	_connect_if_exists("Panel/MainMenuBtn", _on_main_menu)
	if not SignalBus.day_advanced.is_connected(_on_day_changed):
		SignalBus.day_advanced.connect(_on_day_changed)
	_build_activity_buttons()
	_update_ui()

func _build_npc_presence() -> void:
	if has_node("NPCPresencePanel"):
		return
	var presence := NPCPresencePanelScript.new()
	presence.call("configure", hub_id)
	add_child(presence)

func _build_representative_npc() -> void:
	var hub: Dictionary = WorldMapManager.get_hub_data(hub_id)
	for npc_id_value in hub.get("npc_pool", []):
		var raw_id: String = str(npc_id_value)
		var canonical_id: String = str(CHARACTER_ALIASES.get(raw_id, raw_id))
		var character: Dictionary = DataRegistry.get_character(canonical_id)
		if character.is_empty():
			continue
		var actor := FighterPlaceholderScript.new()
		actor.name = "RepresentativeNPC"
		actor.fighter_id = canonical_id
		actor.display_name = str(character.get("name", canonical_id))
		actor.position = Vector2(1080.0, 470.0)
		actor.scale = Vector2(-0.72, 0.72)
		actor.z_index = 1
		add_child(actor)
		break

func _play_hub_ambience() -> void:
	var cue_id: String = "arena_idle_loop"
	match hub_id:
		"salvador": cue_id = "salvador_city_loop"
		"zambiapunga": cue_id = "zambiapunga_square_loop"
		"camamu_manguezal": cue_id = "mangrove_tide_loop"
	AudioManager.play_ambience(cue_id)

func _style_interface() -> void:
	if has_node("Panel"):
		$Panel.z_index = 2
		var backdrop := Panel.new()
		backdrop.name = "InterfaceBackdrop"
		backdrop.anchor_left = 0.5
		backdrop.anchor_top = 0.5
		backdrop.anchor_right = 0.5
		backdrop.anchor_bottom = 0.5
		backdrop.offset_left = -382.0
		backdrop.offset_top = -358.0
		backdrop.offset_right = 382.0
		backdrop.offset_bottom = 358.0
		backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		backdrop.add_theme_stylebox_override("panel", VisualTheme.panel_style(0.88, accent_color, 2, 14))
		add_child(backdrop)
		move_child(backdrop, 2)
	if has_node("Panel/Title"):
		VisualTheme.style_heading($Panel/Title, 28, accent_color)
	for label_path in ["Panel/Status", "Panel/Weather"]:
		if has_node(label_path):
			get_node(label_path).add_theme_color_override("font_color", VisualTheme.CYAN)
	if has_node("Panel/Message"):
		$Panel/Message.add_theme_color_override("font_color", VisualTheme.HONOR)
	if has_node("Panel/ActivitiesLabel"):
		$Panel/ActivitiesLabel.add_theme_color_override("font_color", VisualTheme.OFF_WHITE)
	for button_name in ["ExploreBtn", "RestBtn", "AdvanceDayBtn", "CriaLiveBtn", "MapBtn", "SaveBtn", "MainMenuBtn"]:
		var path: String = "Panel/" + str(button_name)
		if has_node(path):
			VisualTheme.apply_primary_button(get_node(path))

func _connect_if_exists(path: String, callback: Callable) -> void:
	if not has_node(path):
		push_warning("[RegionalHub] Node ausente: " + path)
		return
	var button: Button = get_node(path)
	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)

func _build_activity_buttons() -> void:
	if not has_node("Panel/Activities"):
		return
	var container: VBoxContainer = $Panel/Activities
	for child in container.get_children():
		child.queue_free()
	var hub: Dictionary = WorldMapManager.get_hub_data(hub_id)
	var activity_ids: Array = hub.get("activities", [])
	for activity_id_value in activity_ids:
		var activity_id: String = str(activity_id_value)
		var activity: Dictionary = HubActivityManager.get_activity(activity_id)
		var button := Button.new()
		button.name = "Activity_" + activity_id
		button.custom_minimum_size = Vector2(0, 46)
		button.text = str(activity.get("name", activity_id.replace("_", " ").capitalize()))
		button.tooltip_text = _activity_tooltip(activity)
		button.disabled = activity.is_empty()
		VisualTheme.apply_action_button(button, accent_color)
		button.pressed.connect(_on_activity_pressed.bind(activity_id))
		container.add_child(button)

func _activity_tooltip(activity: Dictionary) -> String:
	if activity.is_empty():
		return "Atividade ainda indisponível."
	var energy_cost: int = int(activity.get("energy_cost", 0))
	var money: int = int(activity.get("money", 0))
	var details: Array[String] = ["Energia %d" % energy_cost]
	if money > 0:
		details.append("Recebe R$ %d" % money)
	elif money < 0:
		details.append("Custa R$ %d" % absi(money))
	return " • ".join(details)

func _on_activity_pressed(activity_id: String) -> void:
	var result: Dictionary = HubActivityManager.execute_activity(activity_id)
	_show_message(str(result.get("message", "Atividade processada.")))
	_update_ui()

func _on_explore() -> void:
	var event: Dictionary = HubActivityManager.roll_dynamic_event()
	if event.is_empty():
		_show_message("O território está calmo. Ainda assim, alguém observa cada movimento.")
		return
	_show_message(str(event.get("label", "Um acontecimento mudou o ritmo do território.")))

func _on_rest() -> void:
	WorldState.energy = minf(100.0, WorldState.energy + 30.0)
	WorldState.strain_level = maxi(0, WorldState.strain_level - 1)
	WorldState._sync_aliases()
	SaveManager.save_game(1)
	_show_message("Ruan descansou e reduziu o desgaste acumulado.")
	_update_ui()

func _on_advance_day() -> void:
	WorldState.advance_day()
	SaveManager.save_game(1)
	_show_message("O dia avançou. O mundo continuou se movendo.")
	_update_ui()

func _on_cria_live() -> void:
	_change_scene(CRIA_LIVE_SCENE)

func _on_map() -> void:
	_change_scene(MAP_SCENE)

func _on_save() -> void:
	_show_message("Jogo salvo com sucesso." if SaveManager.save_game(1) else "Falha ao salvar o jogo.")

func _on_main_menu() -> void:
	SaveManager.save_game(1)
	_change_scene(MAIN_MENU_SCENE)

func _change_scene(path: String) -> void:
	if _transitioning:
		return
	_transitioning = true
	var error: Error = get_tree().change_scene_to_file(path)
	if error != OK:
		_transitioning = false
		_show_message("Falha ao abrir a próxima tela.")
		push_error("[RegionalHub] Falha ao abrir %s: %s" % [path, error_string(error)])

func _update_ui() -> void:
	if has_node("Panel/Title"):
		$Panel/Title.text = hub_title
		$Panel/Title.modulate = accent_color
	if has_node("Panel/Description"):
		$Panel/Description.text = hub_description
	if has_node("Panel/Status"):
		$Panel/Status.text = "Semana %d • %s • R$ %d • Energia %d • Desgaste %d" % [
			WorldState.week,
			WorldState.days[WorldState.day_index].capitalize(),
			WorldState.money,
			int(WorldState.energy),
			WorldState.strain_level
		]
	if has_node("Panel/Weather"):
		var weather_id: String = WorldDirectorManager.get_weather_for_hub(hub_id)
		var weather: Dictionary = WorldDirectorManager.get_weather_definition(weather_id)
		var pressure: Dictionary = FactionDirectorManager.get_snapshot()
		$Panel/Weather.text = "Clima: %s • Pressão regional: nível %d" % [
			str(weather.get("label", weather_id.replace("_", " ").capitalize())),
			int(pressure.get("pressure_level", 0))
		]

func _show_message(message: String) -> void:
	if has_node("Panel/Message"):
		$Panel/Message.text = message

func _on_day_changed(_day_name, _week_number) -> void:
	_update_ui()

func _exit_tree() -> void:
	AudioManager.stop_ambience()
