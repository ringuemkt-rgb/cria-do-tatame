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
	var requests: Array = []
	panel.travel_requested.connect(func(destination_node: String, vehicle_id: String, world_context: Dictionary):
		requests.append({"destination": destination_node, "vehicle": vehicle_id, "context": world_context.duplicate(true)})
	)

	var node := {
		"id": "ponte_do_saici",
		"nome": "Ponte do Saici",
		"tipo": "clandestina",
		"faccao": "NTM"
	}
	var blocked_context := {
		"weather": "chuva",
		"act": 3,
		"sombra": 10,
		"flags": {},
		"route_unlocks": []
	}
	var blocked_view: Dictionary = panel.present_node("itubera", node, blocked_context)
	_check(bool(blocked_view.get("route_found", false)), "panel resolves route even when destination node is locked")
	_check(not bool(blocked_view.get("traversable", true)), "destination node lock blocks travel preview")
	_check(blocked_view.get("gate_reasons", []).has("node_lock_unsatisfied:tinker"), "node lock exposes missing tinker requirement")
	_check(panel.get_node("Margin/VBox/Start").disabled, "prepare action is disabled while destination is locked")
	_check(world_map_manager.call("to_dict") == map_before, "locked preview does not mutate map state")

	var context := blocked_context.duplicate(true)
	context["flags"] = {"tinker": true}
	var view: Dictionary = panel.present_node("itubera", node, context)
	_check(bool(view.get("route_found", false)), "panel resolves a catalogued route")
	_check(str(view.get("destination", "")) == "ponte_do_saici", "panel keeps destination id")
	_check(str(view.get("route_type", "")) == "terrestre", "panel displays normalized route type")
	_check(bool(view.get("read_only", false)), "panel presentation stays read-only")
	_check(bool(view.get("traversable", false)), "destination opens when node requirements are satisfied")
	_check(_has_method(view.get("method_options", []), "kombi_terreiro"), "panel exposes Kombi option")
	_check(_has_method(view.get("method_options", []), "onibus_regional"), "panel exposes regional bus fallback")
	_check(str(view.get("world_context_snapshot", {}).get("weather", "")) == "chuva", "panel preserves route context snapshot")
	_check(bool(view.get("world_context_snapshot", {}).get("flags", {}).get("tinker", false)), "panel preserves node-lock flag in context snapshot")
	_check(panel.visible, "panel becomes visible after focus")

	var kombi_button: Button = panel.get_node_or_null("Margin/VBox/Methods/Method_kombi_terreiro")
	var start_button: Button = panel.get_node("Margin/VBox/Start")
	_check(kombi_button != null, "Kombi preview button is rendered")
	if kombi_button != null:
		_check(not kombi_button.disabled, "Kombi preview button enabled on traversable route")
		kombi_button.pressed.emit()
		await process_frame
		var selected: Dictionary = panel.get_view_model()
		_check(str(selected.get("selected_method", "")) == "kombi_terreiro", "method selection remains a preview")
		_check(not start_button.disabled, "prepare action enables only after valid method selection")
		start_button.pressed.emit()
		await process_frame
		_check(requests.size() == 1, "prepare action emits exactly one travel request")
		if requests.size() == 1:
			_check(str(requests[0].get("destination", "")) == "ponte_do_saici", "travel request carries destination")
			_check(str(requests[0].get("vehicle", "")) == "kombi_terreiro", "travel request carries selected vehicle")
			_check(bool(requests[0].get("context", {}).get("flags", {}).get("tinker", false)), "travel request carries immutable planning context")
		_check(start_button.disabled, "prepare action locks after emission to prevent double request")

	_check(world_map_manager.call("to_dict") == map_before, "panel signal emission still does not mutate WorldMapManager")
	_check(int(world_state.get("money")) == money_before, "panel does not spend money")
	_check(is_equal_approx(float(world_state.get("energy")), energy_before), "panel does not spend energy")
	_check(str(world_state.get("current_hub")) == world_hub_before, "panel does not move WorldState hub")

	var unresolved: Dictionary = panel.present_node("itubera", {"id": "sem_rota", "nome": "Sem Rota", "tipo": "interesse"}, context)
	_check(not bool(unresolved.get("route_found", true)), "uncatalogued destination fails closed")
	_check(not bool(unresolved.get("traversable", true)), "uncatalogued destination cannot start travel")
	_check(unresolved.get("method_options", []).is_empty(), "uncatalogued destination exposes no methods")
	_check(panel.get_node("Margin/VBox/Start").disabled, "uncatalogued destination cannot emit prepare request")
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
