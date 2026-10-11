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
	root.add_child(screen)
	screen.size = Vector2(1280.0, 720.0)
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
	_check(right.position.x < 1280.0 and right.position.x > 650.0, "travel buttons are onscreen at 1280 width")
	_check(left.size.x > 250.0 and right.size.x > 250.0, "touch HUD panels have readable widths")
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
	screen.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	print("[WorldAtlasNav] checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
