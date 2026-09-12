extends Control

signal page_changed(page_id: String)
signal node_focused(node: Dictionary)

const MAP_DATA_PATH := "res://data/world/world_map_v4.json"
const LIFE_CONTRACT_PATH := "res://data/visual/world_map_life_v1.json"
const DESIGN_SIZE := Vector2(1920.0, 1080.0)

var active_page_id := "01"
var selected_node_id := "itubera"
var motion_enabled := true
var _time := 0.0
var _map_data: Dictionary = {}
var _life_contract: Dictionary = {}

func _ready() -> void:
	_load_contracts()
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()

func _process(delta: float) -> void:
	if motion_enabled:
		_time += delta
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton) or not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	var hit := _find_hit(event.position)
	if hit.is_empty():
		return
	if hit.has("target_page"):
		open_page(str(hit.get("target_page", "01")))
		return
	selected_node_id = str(hit.get("id", ""))
	node_focused.emit(hit)
	queue_redraw()

func _load_contracts() -> void:
	_map_data = _load_json(MAP_DATA_PATH)
	_life_contract = _load_json(LIFE_CONTRACT_PATH)

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

func open_page(page_id: String) -> bool:
	for page_value in _map_data.get("pages", []):
		if str(page_value.get("id", "")) == page_id:
			active_page_id = page_id
			page_changed.emit(active_page_id)
			queue_redraw()
			return true
	return false

func get_page_count() -> int:
	return _map_data.get("pages", []).size()

func get_node_count() -> int:
	return _map_data.get("nodes", []).size()

func get_visual_contract() -> Dictionary:
	return _life_contract.duplicate(true)

func _draw() -> void:
	var bounds := Rect2(Vector2.ZERO, size)
	draw_rect(bounds, Color("08131a"))
	_draw_map_backdrop(bounds)
	_draw_ornamental_frame(bounds)
	if active_page_id == "01":
		_draw_regional_anchors()
	else:
		_draw_page_nodes()
	_draw_map_header(bounds)

func _draw_map_backdrop(bounds: Rect2) -> void:
	draw_rect(bounds.grow(-18.0), Color("0c4157"))
	var inset := bounds.grow(-42.0)
	var phase := sin(_time * 0.7) if motion_enabled else 0.0
	for index in range(7):
		var y := inset.position.y + 55.0 + float(index) * 86.0 + phase * 4.0
		draw_line(Vector2(inset.position.x + 30.0, y), Vector2(inset.end.x - 30.0, y - 20.0), Color(0.35, 0.84, 0.92, 0.17), 2.0)
	var coast := PackedVector2Array([Vector2(inset.position.x + inset.size.x * 0.12, inset.position.y + inset.size.y * 0.15), Vector2(inset.position.x + inset.size.x * 0.42, inset.position.y + inset.size.y * 0.08), Vector2(inset.position.x + inset.size.x * 0.69, inset.position.y + inset.size.y * 0.20), Vector2(inset.position.x + inset.size.x * 0.62, inset.position.y + inset.size.y * 0.54), Vector2(inset.position.x + inset.size.x * 0.80, inset.position.y + inset.size.y * 0.82), Vector2(inset.position.x + inset.size.x * 0.36, inset.position.y + inset.size.y * 0.91), Vector2(inset.position.x + inset.size.x * 0.13, inset.position.y + inset.size.y * 0.70)])
	draw_colored_polygon(coast, Color("234c39"))
	draw_polyline(coast, Color("5ca97c"), 7.0, true)
	_draw_ambient_boat(bounds)

func _draw_ambient_boat(bounds: Rect2) -> void:
	if not motion_enabled:
		return
	var x := bounds.position.x + 80.0 + fmod(_time * 22.0, maxf(1.0, bounds.size.x - 160.0))
	var y := bounds.position.y + bounds.size.y * 0.76 + sin(_time * 1.3) * 5.0
	draw_colored_polygon(PackedVector2Array([Vector2(x - 13.0, y), Vector2(x + 16.0, y), Vector2(x + 8.0, y + 7.0), Vector2(x - 8.0, y + 7.0)]), Color("e4c56d"))
	draw_line(Vector2(x, y), Vector2(x, y - 22.0), Color("e4c56d"), 2.0)

func _draw_regional_anchors() -> void:
	for anchor_value in _map_data.get("municipal_anchors", []):
		var anchor: Dictionary = anchor_value
		var pos_data: Array = anchor.get("pos", [0.5, 0.5])
		if pos_data.size() < 2:
			continue
		var point := _normalized_to_screen(Vector2(float(pos_data[0]), float(pos_data[1])))
		var color := _faction_color(str(anchor.get("faccao", "neutral")))
		_draw_route_pulse(point, color)
		_draw_badge(point, str(anchor.get("nome", "?")), color, str(anchor.get("id", "")) == selected_node_id)

func _draw_page_nodes() -> void:
	var nodes := _nodes_for_active_page()
	var point_by_id := {}
	for node_value in nodes:
		var node: Dictionary = node_value
		point_by_id[str(node.get("id", ""))] = _node_screen_position(node)
	for route_value in _map_data.get("routes", []):
		var route: Dictionary = route_value
		var from_id := str(route.get("from", ""))
		var to_id := str(route.get("to", ""))
		if point_by_id.has(from_id) and point_by_id.has(to_id):
			var route_color := Color("efdc9a")
			if str(route.get("tipo", "")) == "maritima": route_color = Color("59d9e7")
			if bool(route.get("bloqueada", false)): route_color = Color("a33e43")
			_draw_dashed_route(point_by_id[from_id], point_by_id[to_id], route_color)
	for node_value in nodes:
		var node: Dictionary = node_value
		var locked := node.has("lock")
		var color := Color("916eac") if str(node.get("tipo", "")) == "secreta" else _faction_color(str(node.get("faccao", "neutral")))
		if locked: color = color.darkened(0.45)
		var point := _node_screen_position(node)
		_draw_route_pulse(point, color)
		_draw_badge(point, str(node.get("nome", "?")), color, str(node.get("id", "")) == selected_node_id, locked)

func _draw_dashed_route(from: Vector2, to: Vector2, color: Color) -> void:
	for index in range(18):
		if index % 2 != 0: continue
		var shift := fmod(_time * 3.0, 2.0) if motion_enabled else 0.0
		var a := clampf((float(index) + shift) / 18.0, 0.0, 1.0)
		var b := clampf((float(index) + 0.72 + shift) / 18.0, 0.0, 1.0)
		draw_line(from.lerp(to, a), from.lerp(to, b), color, 3.0)

func _draw_route_pulse(point: Vector2, color: Color) -> void:
	var radius := 25.0 + (sin(_time * 2.6 + point.x * 0.01) + 1.0) * 4.0 if motion_enabled else 29.0
	draw_arc(point, radius, 0.0, TAU, 32, Color(color, 0.32), 2.0)

func _draw_badge(point: Vector2, label_text: String, color: Color, selected: bool, locked := false) -> void:
	draw_circle(point, 20.0, Color("11181b") if not selected else color.darkened(0.45))
	draw_arc(point, 20.0, 0.0, TAU, 24, Color("e7ca78") if selected else color, 3.0)
	if locked:
		draw_string(ThemeDB.fallback_font, point + Vector2(-5.0, 6.0), "×", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 22, Color("e2b9b0"))
	else:
		draw_circle(point, 5.0, Color("f2e8b4"))
	var label_rect := Rect2(point + Vector2(26.0, -13.0), Vector2(210.0, 26.0))
	draw_rect(label_rect.grow(3.0), Color(0.02, 0.05, 0.06, 0.76))
	draw_string(ThemeDB.fallback_font, label_rect.position + Vector2(5.0, 18.0), label_text, HORIZONTAL_ALIGNMENT_LEFT, label_rect.size.x - 8.0, 15, Color("f5e9bb"))

func _draw_ornamental_frame(bounds: Rect2) -> void:
	var frame := bounds.grow(-12.0)
	draw_rect(frame, Color("e2c46e"), false, 3.0)
	for corner in [frame.position, Vector2(frame.end.x, frame.position.y), Vector2(frame.position.x, frame.end.y), frame.end]: draw_circle(corner, 8.0, Color("e2c46e"))

func _draw_map_header(bounds: Rect2) -> void:
	var page_name := "Baixo Sul"
	for page_value in _map_data.get("pages", []):
		if str(page_value.get("id", "")) == active_page_id: page_name = str(page_value.get("nome", page_name))
	var plaque := Rect2(bounds.position + Vector2(34.0, 30.0), Vector2(345.0, 56.0))
	draw_rect(plaque, Color(0.02, 0.04, 0.05, 0.88))
	draw_rect(plaque, Color("e2c46e"), false, 2.0)
	draw_string(ThemeDB.fallback_font, plaque.position + Vector2(16.0, 35.0), "MAPA • %s" % page_name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, Color("f7e8ad"))

func _find_hit(local: Vector2) -> Dictionary:
	if active_page_id == "01":
		for anchor_value in _map_data.get("municipal_anchors", []):
			var anchor: Dictionary = anchor_value
			var pos_data: Array = anchor.get("pos", [0.5, 0.5])
			if pos_data.size() >= 2 and local.distance_to(_normalized_to_screen(Vector2(float(pos_data[0]), float(pos_data[1])))) < 48.0: return anchor
		return {}
	for node_value in _nodes_for_active_page():
		var node: Dictionary = node_value
		if local.distance_to(_node_screen_position(node)) < 48.0: return node
	return {}

func _nodes_for_active_page() -> Array:
	var output: Array = []
	for node_value in _map_data.get("nodes", []):
		if str(node_value.get("pagina", "")) == active_page_id: output.append(node_value)
	return output

func _node_screen_position(node: Dictionary) -> Vector2:
	var pos_data: Array = node.get("pos", [960, 540])
	if pos_data.size() < 2: return size * 0.5
	return Vector2(float(pos_data[0]) / DESIGN_SIZE.x * size.x, float(pos_data[1]) / DESIGN_SIZE.y * size.y)

func _normalized_to_screen(point: Vector2) -> Vector2:
	return Vector2(point.x * size.x, point.y * size.y)

func _faction_color(faction: String) -> Color:
	match faction:
		"ALE": return Color("ff9408")
		"LEM": return Color("4a6741")
		"NTM": return Color("3fe3f5")
	return Color("e2c46e")
