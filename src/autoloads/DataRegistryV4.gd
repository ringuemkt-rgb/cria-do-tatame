extends "res://src/autoloads/DataRegistry.gd"

var world_map_nodes_v4: Dictionary = {}
var seasonal_events_v4: Dictionary = {}

func load_all() -> void:
	super.load_all()
	world_map_nodes_v4 = _load_external_json("res://data/world/world_map_nodes_v4.json")
	seasonal_events_v4 = _load_external_json("res://data/world/seasonal_events_v4.json")
	var errors: Array = validation_report.get("errors", []).duplicate()
	if world_map_nodes_v4.get("nodes", {}).size() != 11:
		errors.append("world_map_nodes_v4 deve possuir exatamente 11 municipios")
	if str(world_map_nodes_v4.get("special_locations", {}).get("pratigi", {}).get("municipio", "")) != "Ituberá":
		errors.append("Pratigi deve estar vinculado a Itubera")
	if seasonal_events_v4.get("eventos", []).size() < 4:
		errors.append("seasonal_events_v4 deve possuir ao menos quatro eventos")
	validation_report["errors"] = errors
	validation_report["ok"] = errors.is_empty()
	validation_report["world_nodes_v4"] = world_map_nodes_v4.get("nodes", {}).size()
	validation_report["seasonal_events_v4"] = seasonal_events_v4.get("eventos", []).size()
	SignalBus.data_validation_finished.emit(validation_report)

func get_world_node_v4(node_id: String) -> Dictionary:
	return world_map_nodes_v4.get("nodes", {}).get(node_id, {}).duplicate(true)

func get_special_location_v4(location_id: String) -> Dictionary:
	return world_map_nodes_v4.get("special_locations", {}).get(location_id, {}).duplicate(true)

func get_seasonal_event_v4(event_id: String) -> Dictionary:
	for event_value in seasonal_events_v4.get("eventos", []):
		if str(event_value.get("id", "")) == event_id:
			return event_value.duplicate(true)
	return {}

func _load_external_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}
