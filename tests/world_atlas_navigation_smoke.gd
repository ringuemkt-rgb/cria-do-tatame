extends SceneTree

var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("[WorldAtlasNav] " + message)

func _run() -> void:
	await process_frame
	var scene: PackedScene = load("res://scenes/world/WorldMapScreen.tscn")
	_check(scene != null, "WorldMapScreen remains a loadable PackedScene")
	if scene == null:
		_finish()
		return
	var screen: Control = scene.instantiate()
	root.size = Vector2i(1280, 720)
	root.add_child(screen)
	await process_frame
	await process_frame
	var layer: Control = screen.get_node("WorldMapLifeLayer")
	var left: Control = screen.get_node("HUD/LeftPanel")
	var right: Control = screen.get_node("HUD/RightPanel")
	var footer: Label = screen.get_node("HUD/Footer")
	var former_destination: Button = screen.get_node("HUD/RightPanel/Salvador")
	_check(screen.get_map_page_count() == 10, "legacy ten page atlas preserved")
	_check(screen.get_map_node_count() == 40, "canonical forty map points preserved")
	var names: Array = layer.call("get_page_ids")
	_check(names.size() == 10, "ten addressable pages")
	_check(str(names[0]) == "01" and str(names[9]) == "10", "page ordering remains stable")
	_check(str(layer.call("get_page_name", "02")) == "Ituberá", "Ituberá page correctly labeled")
	_check(str(layer.call("get_page_name", "03")) == "Nilo Peçanha", "Nilo Peçanha page correctly labeled")
	var canvas_rect := layer.get_global_rect()
	var top_rect := left.get_global_rect()
	var travel_rect := right.get_global_rect()
	_check(canvas_rect.position.y >= top_rect.end.y, "atlas begins below top controls")
	_check(canvas_rect.end.y <= travel_rect.position.y, "atlas ends above travel controls")
	_check(canvas_rect.size.x >= 1200.0 and canvas_rect.size.y >= 380.0, "atlas canvas has touch-readable bounds")
	_check(left.size.x >= 1100.0 and right.size.x >= 1100.0, "controls use full responsive width")
	var touch_buttons: Array = [
		screen.get_node("HUD/LeftPanel/PreviousPage"),
		screen.get_node("HUD/LeftPanel/NextPage"),
		screen.get_node("HUD/LeftPanel/Regional"),
		screen.get_node("HUD/RightPanel/Itubera"),
		screen.get_node("HUD/RightPanel/Salvador"),
		screen.get_node("HUD/RightPanel/Zambiapunga"),
		screen.get_node("HUD/RightPanel/Camamu"),
		screen.get_node("HUD/RightPanel/Back")
	]
	for button in touch_buttons:
		_check(button.get_global_rect().size.y >= 40.0, "touch button height: " + button.name)
		_check(not button.get_global_rect().intersects(canvas_rect), "touch button does not cover atlas: " + button.name)
	_check(footer.position.y < 720.0, "footer is on the visible screen")
	_check(former_destination.disabled, "Salvador is visibly not a playable destination")
	_check(str(former_destination.text).contains("CONTEXTO"), "Salvador marked as story context")
	layer.open_page("01")
	screen.get_node("HUD/LeftPanel/NextPage").emit_signal("pressed")
	_check(str(layer.get("active_page_id")) == "02", "next-page touch goes to Ituberá")
	_check(str(screen.get_node("HUD/LeftPanel/PageIndex").text).contains("02"), "page status reflects selection")
	screen.get_node("HUD/LeftPanel/PreviousPage").emit_signal("pressed")
	_check(str(layer.get("active_page_id")) == "01", "previous-page touch returns to Baixo Sul")
	screen.get_node("HUD/LeftPanel/PreviousPage").emit_signal("pressed")
	_check(str(layer.get("active_page_id")) == "10", "previous-page touch wraps through ten pages")
	screen.get_node("HUD/LeftPanel/Regional").emit_signal("pressed")
	_check(str(layer.get("active_page_id")) == "01", "regional button returns to overview")
	var source: Dictionary = layer.call("get_page_source_state", "01")
	_check(not bool(source.get("final_art_approved", true)), "visual proof cannot be faked")
	_check(not bool(source.get("georeference_verified", true)), "concept coordinates are not labeled georeferenced")
	_check(bool(source.get("candidate_loaded", false)), "first reference image remains loaded")
	var map_file := FileAccess.open("res://data/world/world_map_v4.json", FileAccess.READ)
	_check(map_file != null, "canonical world map data exists")
	if map_file != null:
		var map_data: Variant = JSON.parse_string(map_file.get_as_text())
		map_file.close()
		_check(typeof(map_data) == TYPE_DICTIONARY, "canonical world map JSON parses")
		if typeof(map_data) == TYPE_DICTIONARY:
			var anchors: Array = map_data.get("municipal_anchors", [])
			var nodes: Array = map_data.get("nodes", [])
			_check(anchors.size() == 14 and nodes.size() == 40, "14 regional anchors and 40 map nodes")
			layer.open_page("01")
			for anchor_value in anchors:
				var anchor: Dictionary = anchor_value
				var pos_data: Array = anchor.get("pos", [0.5, 0.5])
				var local_point := Vector2(float(pos_data[0]) * layer.size.x, float(pos_data[1]) * layer.size.y)
				var center: Vector2 = layer.get_global_transform() * local_point
				var hit: Dictionary = layer.call("_find_hit", local_point)
				_check(canvas_rect.has_point(center), "anchor center inside atlas: " + str(anchor.get("id", "?")))
				_check(str(hit.get("id", "")) == str(anchor.get("id", "")), "nearest hit resolves anchor: " + str(anchor.get("id", "?")))
				for button in touch_buttons:
					_check(not button.get_global_rect().has_point(center), "anchor not covered: " + str(anchor.get("id", "?")))
			for node_value in nodes:
				var node: Dictionary = node_value
				layer.open_page(str(node.get("pagina", "02")))
				var local_point: Vector2 = layer.call("_node_screen_position", node)
				var center: Vector2 = layer.get_global_transform() * local_point
				var hit: Dictionary = layer.call("_find_hit", local_point)
				_check(canvas_rect.has_point(center), "node center inside atlas: " + str(node.get("id", "?")))
				_check(str(hit.get("id", "")) == str(node.get("id", "")), "nearest hit resolves node: " + str(node.get("id", "?")))
				for button in touch_buttons:
					_check(not button.get_global_rect().has_point(center), "node not covered: " + str(node.get("id", "?")))
			var travel_before: int = root.get_node("WorldMapManager").get("travel_log").size()
			var money_before := int(root.get_node("WorldState").get("money"))
			layer.open_page("01")
			var first_anchor: Dictionary = anchors[0]
			var first_pos: Array = first_anchor.get("pos", [0.5, 0.5])
			var tap := InputEventMouseButton.new()
			tap.button_index = MOUSE_BUTTON_LEFT
			tap.pressed = true
			tap.position = Vector2(float(first_pos[0]) * layer.size.x, float(first_pos[1]) * layer.size.y)
			layer._gui_input(tap)
			_check(str(layer.active_page_id) == str(first_anchor.get("target_page", "")), "tap opens nearest regional page")
			_check(int(root.get_node("WorldState").get("money")) == money_before, "map tap does not debit money")
			_check(root.get_node("WorldMapManager").get("travel_log").size() == travel_before, "map tap does not create travel")
			layer.open_page("01")
			# Android sends InputEventScreenTouch; some devices also synthesize
			# InputEventMouseButton. Both must resolve as one intentional tap.
			var focused_ids: Array[String] = []
			layer.node_focused.connect(func(node: Dictionary) -> void:
				focused_ids.append(str(node.get("id", "")))
			)
			var native_touch := InputEventScreenTouch.new()
			native_touch.index = 0
			native_touch.pressed = true
			native_touch.position = tap.position
			layer._gui_input(native_touch)
			_check(str(layer.active_page_id) == str(first_anchor.get("target_page", "")), "native Android touch opens regional page")
			var synthetic_mouse := InputEventMouseButton.new()
			synthetic_mouse.button_index = MOUSE_BUTTON_LEFT
			synthetic_mouse.pressed = true
			synthetic_mouse.position = native_touch.position
			layer._gui_input(synthetic_mouse)
			_check(str(layer.active_page_id) == str(first_anchor.get("target_page", "")), "synthetic mouse cannot navigate twice")
			_check(focused_ids.is_empty(), "synthetic mouse does not focus a second marker")
			var touch_node: Dictionary = {}
			for candidate_value in nodes:
				var candidate: Dictionary = candidate_value
				if str(candidate.get("pagina", "")) == "02":
					touch_node = candidate
					break
			_check(not touch_node.is_empty(), "Ituberá has an atlas marker for native touch")
			if not touch_node.is_empty():
				layer.open_page("02")
				var node_touch := InputEventScreenTouch.new()
				node_touch.index = 0
				node_touch.pressed = true
				node_touch.position = layer.call("_node_screen_position", touch_node)
				var before_focus := focused_ids.size()
				layer._gui_input(node_touch)
				_check(focused_ids.size() == before_focus + 1, "native touch focuses exactly one atlas node")
				_check(str(layer.selected_node_id) == str(touch_node.get("id", "")), "native touch selects intended node")
				var duplicate := InputEventMouseButton.new()
				duplicate.button_index = MOUSE_BUTTON_LEFT
				duplicate.pressed = true
				duplicate.position = node_touch.position
				layer._gui_input(duplicate)
				_check(focused_ids.size() == before_focus + 1, "touch-generated mouse does not duplicate node focus")
				_check(screen.get_node("HUD/LeftPanel/PageIndex").text.contains("Ituberá"), "page title remains visible in top HUD")
				_check(not screen.get_node("HUD/LeftPanel/PageIndex").get_global_rect().intersects(layer.get_global_rect()), "page title never overlays map emblems")
			_check(int(root.get_node("WorldState").get("money")) == money_before, "native touch cannot debit travel currency")
			_check(root.get_node("WorldMapManager").get("travel_log").size() == travel_before, "native touch cannot initiate travel")
			layer.open_page("01")
	# Exercise the same fit rectangle used by the renderer for every loaded candidate.
	var art_by_page: Dictionary = layer.get("_base_art_by_page")
	for texture_value in art_by_page.values():
		var texture: Texture2D = texture_value
		for canvas_size in [Vector2(1280, 403.2), Vector2(1600, 403.2), Vector2(1280, 448)]:
			var bounds := Rect2(Vector2.ZERO, canvas_size)
			var fitted: Rect2 = layer.call("_fit_base_art_rect", bounds, texture.get_size())
			_check(fitted.size.x > 0.0 and fitted.size.y > 0.0, "candidate has a nonempty art rect")
			_check(bounds.grow(-41.9).encloses(fitted), "candidate stays inside canvas inset")
			_check(is_equal_approx(fitted.size.x / fitted.size.y, texture.get_size().x / texture.get_size().y), "candidate aspect ratio preserved")
			_check(fitted.get_center().is_equal_approx(bounds.get_center()), "candidate centered inside canvas")
	for texture_size in [Vector2.ZERO, Vector2(512, 0), Vector2(0, 288)]:
		var empty: Rect2 = layer.call("_fit_base_art_rect", Rect2(Vector2.ZERO, Vector2(1280, 720)), texture_size)
		_check(empty.size == Vector2.ZERO, "invalid texture size has empty rectangle")
	var tiny: Rect2 = layer.call("_fit_base_art_rect", Rect2(Vector2.ZERO, Vector2(40, 40)), Vector2(512, 288))
	_check(tiny.size == Vector2.ZERO, "tiny canvas has empty art rectangle")
	var source_pending: Dictionary = layer.call("get_page_source_state", "10")
	_check(not bool(source_pending.get("candidate_loaded", true)), "unpainted tenth page uses procedural fallback")
	var contract_file := FileAccess.open("res://data/visual/baixo_sul_map_reference_ledger_v1.json", FileAccess.READ)
	_check(contract_file != null, "user visual reference ledger versioned")
	if contract_file != null:
		var parsed = JSON.parse_string(contract_file.get_as_text())
		contract_file.close()
		_check(typeof(parsed) == TYPE_DICTIONARY and not parsed.get("shipping", true), "reference ledger is not shipping art")
		_check(parsed.get("world_scope", {}).get("primary_hub", "") == "itubera", "Ituberá preserved as playable hub")
		_check(parsed.get("world_scope", {}).get("context_only_not_playable", []).has("salvador"), "Salvador excluded from playable map contract")
	var world_map := root.get_node("WorldMapManager")
	var old_hub := str(world_map.get("current_hub"))
	screen._on_travel_pressed("salvador")
	_check(str(world_map.get("current_hub")) == old_hub, "UI must not travel outside the declared playable region")
	# Resize the viewport itself: an anchored Control overrides manual size writes.
	for viewport_size in [Vector2i(1280, 720), Vector2i(1600, 720), Vector2i(1280, 800)]:
		root.size = viewport_size
		for page_id in names:
			layer.open_page(str(page_id))
			await process_frame
			await process_frame
			var current_canvas := layer.get_global_rect()
			_check(current_canvas.position.y >= left.get_global_rect().end.y, "top controls clear atlas: %s %s" % [viewport_size, page_id])
			_check(current_canvas.end.y <= right.get_global_rect().position.y, "bottom controls clear atlas: %s %s" % [viewport_size, page_id])
			for button in touch_buttons:
				_check(screen.get_global_rect().encloses(button.get_global_rect()), "button stays onscreen: %s %s" % [viewport_size, button.name])
				_check(not button.get_global_rect().intersects(current_canvas), "button clears atlas: %s %s" % [viewport_size, button.name])
	screen.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	print("[WorldAtlasNav] checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
