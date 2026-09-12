extends SceneTree

const PanelScene = preload("res://scenes/world/TravelDetailPanel.tscn")

var failures: Array[String] = []
var checks := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var world_map_manager: Node = root.get_node_or_null("WorldMapManager")
	var world_state: Node = root.get_node_or_null("WorldState")
	_check(world_map_manager != null, "WorldMapManager autoload is available")
	_check(world_state != null, "WorldState autoload is available")
	if world_map_manager == null or world_state == null:
		_finish()
		return

	var map_before: Dictionary = world_map_manager.call("to_dict").duplicate(true)
	var money_before := int(world_state.get("money"))
	var energy_before := float(world_state.get("energy"))
	var world_hub_before := str(world_state.get("current_hub"))

	var panel = PanelScene.instantiate()
	root.add_child(panel)
	await process_frame

	var node := {
		"id": "ponte_do_saici",
		"nome": "Ponte do Saici",
		"tipo": "clandestina",
		"faccao": "NTM"
	}
	var context := {
		"weather": "chuva",
		"act": 3,
		"sombra": 10,
		"flags": {},
		"route_unlocks": []
	}
	var view: Dictionary = panel.present_node("itubera", node, context)
	_check(bool(view.get("route_found", false)), "panel resolves a catalogued route")
	_check(str(view.get("destination", "")) == "ponte_do_saici", "panel keeps destination id")
	_check(str(view.get("route_type", "")) == "terrestre", "panel displays normalized route type")
	_check(bool(view.get("read_only", false)), "panel declares read-only VT2 semantics")
	_check(bool(view.get("traversable", false)), "unblocked terrestrial route is previewable")
	_check(_has_method(view.get("method_options", []), "kombi_terreiro"), "panel exposes Kombi option")
	_check(_has_method(view.get("method_options", []), "onibus_regional"), "panel exposes regional bus fallback")
	_check(str(view.get("world_context_snapshot", {}).get("weather", "")) == "chuva", "panel preserves route context snapshot")
	_check(panel.visible, "panel becomes visible after focus")

	var kombi_button: Button = panel.get_node_or_null("Margin/VBox/Methods/Method_kombi_terreiro")
	_check(kombi_button != null, "Kombi preview button is rendered")
	if kombi_button != null:
		_check(not kombi_button.disabled, "Kombi preview button enabled on traversable route")
		kombi_button.pressed.emit()
		await process_frame
		var selected: Dictionary = panel.get_view_model()
		_check(str(selected.get("selected_method", "")) == "kombi_terreiro", "method selection remains a preview")

	_check(world_map_manager.call("to_dict") == map_before, "VT2 panel does not mutate WorldMapManager")
	_check(int(world_state.get("money")) == money_before, "VT2 panel does not spend money")
	_check(is_equal_approx(float(world_state.get("energy")), energy_before), "VT2 panel does not spend energy")
	_check(str(world_state.get("current_hub")) == world_hub_before, "VT2 panel does not move WorldState hub")

	var unresolved: Dictionary = panel.present_node("itubera", {"id": "sem_rota", "nome": "Sem Rota", "tipo": "interesse"}, context)
	_check(not bool(unresolved.get("route_found", true)), "uncatalogued destination fails closed")
	_check(not bool(unresolved.get("traversable", true)), "uncatalogued destination cannot start travel")
	_check(unresolved.get("method_options", []).is_empty(), "uncatalogued destination exposes no methods")
	_check(world_map_manager.call("to_dict") == map_before, "failed preview still does not mutate map state")

	panel.close_panel()
	_check(not panel.visible, "panel closes without travel")
	panel.queue_free()
	_finish()

func _finish() -> void:
	print("TRAVEL_DETAIL_PANEL_SMOKE checks=%d failures=%d" % [checks, failures.size()])
	for failure in failures:
		push_error(failure)
	quit(0 if failures.is_empty() else 1)

func _has_method(options: Array, vehicle_id: String) -> bool:
	for option_value in options:
		if typeof(option_value) == TYPE_DICTIONARY and str(option_value.get("vehicle_id", "")) == vehicle_id:
			return true
	return false

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
