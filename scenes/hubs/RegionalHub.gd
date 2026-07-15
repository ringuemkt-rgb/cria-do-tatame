extends Control

@export var hub_id: String = ""
@export var hub_title: String = "TERRITÓRIO"
@export_multiline var hub_description: String = ""
@export var accent_color: Color = Color(0.84, 0.69, 0.22, 1.0)

const MAP_SCENE: String = "res://scenes/world/WorldMapScreen.tscn"
const CRIA_LIVE_SCENE: String = "res://scenes/ui/CriaLiveUI.tscn"
const MAIN_MENU_SCENE: String = "res://scenes/main_menu/MainMenu.tscn"

var _transitioning: bool = false

func _ready() -> void:
	if hub_id == "":
		push_error("[RegionalHub] hub_id não configurado")
		return
	WorldMapManager.current_hub = hub_id
	WorldState.current_hub = hub_id
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
