extends Control

const HUB_SCENE := "res://scenes/hubs/TerreiroDaLuta.tscn"
const MAP_ART_DATA := "res://data/visual/world_map_art_v01.json"
const VisualTheme = preload("res://src/ui/CriaVisualTheme.gd")

const NODE_PATHS := {
	"itubera": "MapNodes/Itubera",
	"salvador": "MapNodes/Salvador",
	"zambiapunga": "MapNodes/Zambiapunga",
	"camamu_manguezal": "MapNodes/Camamu"
}

var _map_art: Dictionary = {}
var _node_positions: Dictionary = {}
var _routes: Array = []
var _transitioning: bool = false


func _ready() -> void:
	_load_map_art()
	_style_interface()
	for hub_id_value in NODE_PATHS.keys():
		var hub_id: String = str(hub_id_value)
		_connect_node(str(NODE_PATHS[hub_id]), hub_id)
	if has_node("InfoPanel/VBox/Back"):
		$InfoPanel/VBox/Back.pressed.connect(_on_back_pressed)
	resized.connect(_layout_map_nodes)
	call_deferred("_layout_map_nodes")
	_update_status()
	AudioManager.play_sfx("menu_open")


func _load_map_art() -> void:
	if not FileAccess.file_exists(MAP_ART_DATA):
		push_warning("[WorldMapScreen] Dados de arte do mapa ausentes.")
		return
	var file := FileAccess.open(MAP_ART_DATA, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	_map_art = parsed
	_node_positions = _map_art.get("node_positions", {})
	_routes = _map_art.get("route_pairs", [])


func _style_interface() -> void:
	if has_node("InfoPanel"):
		$InfoPanel.add_theme_stylebox_override("panel", VisualTheme.panel_style(0.90, VisualTheme.GOLD, 2, 12))
	if has_node("InfoPanel/VBox/Title"):
		VisualTheme.style_heading($InfoPanel/VBox/Title, 27, VisualTheme.HONOR)
	if has_node("InfoPanel/VBox/Subtitle"):
		$InfoPanel/VBox/Subtitle.add_theme_color_override("font_color", VisualTheme.CYAN)
		$InfoPanel/VBox/Subtitle.add_theme_font_size_override("font_size", 12)
	if has_node("InfoPanel/VBox/Status"):
		$InfoPanel/VBox/Status.add_theme_color_override("font_color", VisualTheme.OFF_WHITE)
	if has_node("InfoPanel/VBox/Message"):
		$InfoPanel/VBox/Message.add_theme_color_override("font_color", Color("d8e2ee"))
	if has_node("InfoPanel/VBox/Back"):
		VisualTheme.apply_primary_button($InfoPanel/VBox/Back)
	for hub_id_value in NODE_PATHS.keys():
		var path: String = str(NODE_PATHS[hub_id_value])
		if has_node(path):
			VisualTheme.apply_action_button(get_node(path), VisualTheme.GOLD)


func _connect_node(path: String, hub_id: String) -> void:
	if not has_node(path):
		push_warning("[WorldMapScreen] Nó visual ausente: " + path)
		return
	var button: Button = get_node(path)
	button.pressed.connect(_on_travel_pressed.bind(hub_id))


func _on_travel_pressed(hub_id: String) -> void:
	if _transitioning:
		return
	AudioManager.play_sfx("button_confirm")
	var result: Dictionary = WorldMapManager.travel_to(hub_id)
	if has_node("InfoPanel/VBox/Message"):
		$InfoPanel/VBox/Message.text = str(result.get("message", ""))
	_update_status()
	if not bool(result.get("ok", false)):
		return
	_transitioning = true
	await get_tree().create_timer(0.35).timeout
	if not is_inside_tree():
		return
	var target: String = str(result.get("hub", {}).get("entry_scene", HUB_SCENE))
	var error: Error = get_tree().change_scene_to_file(target)
	if error != OK:
		_transitioning = false
		$InfoPanel/VBox/Message.text = "Não foi possível entrar no destino."
		push_error("[WorldMapScreen] Falha ao abrir %s: %s" % [target, error_string(error)])


func _on_back_pressed() -> void:
	if _transitioning:
		return
	var hub: Dictionary = WorldMapManager.get_hub_data(WorldMapManager.current_hub)
	var target: String = str(hub.get("entry_scene", HUB_SCENE))
	_transitioning = true
	var error: Error = get_tree().change_scene_to_file(target)
	if error != OK:
		_transitioning = false


func _update_status() -> void:
	if has_node("InfoPanel/VBox/Status"):
		var current: Dictionary = WorldMapManager.get_hub_data(WorldMapManager.current_hub)
		$InfoPanel/VBox/Status.text = "%s • R$ %d • Semana %d" % [
			str(current.get("name", WorldMapManager.current_hub)).to_upper(),
			WorldState.money,
			WorldState.week
		]
	for hub_id_value in NODE_PATHS.keys():
		var hub_id: String = str(hub_id_value)
		var button: Button = get_node_or_null(str(NODE_PATHS[hub_id]))
		if button == null:
			continue
		var hub: Dictionary = WorldMapManager.get_hub_data(hub_id)
		var cost: int = int(hub.get("travel_cost", 0))
		var hours: int = int(hub.get("travel_hours", 0))
		var is_current: bool = hub_id == WorldMapManager.current_hub
		button.text = "%s\n%s" % [
			str(hub.get("name", hub_id)).to_upper(),
			"VOCÊ ESTÁ AQUI" if is_current else "R$ %d • %dh" % [cost, hours]
		]
		button.tooltip_text = str(hub.get("role", "território")).replace("_", " ").capitalize()
		var accent: Color = VisualTheme.HONOR if is_current else VisualTheme.GOLD
		VisualTheme.apply_action_button(button, accent)
	queue_redraw()


func _layout_map_nodes() -> void:
	var map_rect := _covered_map_rect()
	for hub_id_value in NODE_PATHS.keys():
		var hub_id: String = str(hub_id_value)
		var button: Button = get_node_or_null(str(NODE_PATHS[hub_id]))
		var normalized: Array = _node_positions.get(hub_id, [])
		if button == null or normalized.size() != 2:
			continue
		var center := map_rect.position + Vector2(float(normalized[0]), float(normalized[1])) * map_rect.size
		button.position = center - button.size * 0.5
	queue_redraw()


func _covered_map_rect() -> Rect2:
	if size.x <= 0.0 or size.y <= 0.0:
		return Rect2(Vector2.ZERO, size)
	const ART_ASPECT: float = 16.0 / 9.0
	var viewport_aspect: float = size.x / size.y
	if viewport_aspect >= ART_ASPECT:
		var rendered_height: float = size.x / ART_ASPECT
		return Rect2(Vector2(0.0, (size.y - rendered_height) * 0.5), Vector2(size.x, rendered_height))
	var rendered_width: float = size.y * ART_ASPECT
	return Rect2(Vector2((size.x - rendered_width) * 0.5, 0.0), Vector2(rendered_width, size.y))


func _draw() -> void:
	if _node_positions.is_empty():
		return
	var map_rect := _covered_map_rect()
	for route_value in _routes:
		var route: Array = route_value
		if route.size() != 2:
			continue
		var from_position: Array = _node_positions.get(str(route[0]), [])
		var to_position: Array = _node_positions.get(str(route[1]), [])
		if from_position.size() != 2 or to_position.size() != 2:
			continue
		var start := map_rect.position + Vector2(float(from_position[0]), float(from_position[1])) * map_rect.size
		var finish := map_rect.position + Vector2(float(to_position[0]), float(to_position[1])) * map_rect.size
		draw_line(start, finish, Color(0.0, 0.0, 0.0, 0.58), 8.0, true)
		draw_dashed_line(start, finish, Color(0.95, 0.76, 0.18, 0.88), 3.0, 12.0, true)
