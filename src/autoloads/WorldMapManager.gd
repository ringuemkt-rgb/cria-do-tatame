extends Node

const MAP_PATH := "res://data/world/world_map_v4.json"
const INFO_PATH := "res://data/world/arena_info_v1.json"

var current_hub := "itubera"
var visited_hubs := ["itubera"]
var travel_log := []
var unlocked_hubs := ["itubera", "salvador", "zambiapunga", "camamu_manguezal"]

var map_data: Dictionary = {}
var arena_info: Dictionary = {}
var current_page := "01"
var selected_node := ""

func _ready() -> void:
	_load_v4_data()

func _load_v4_data() -> void:
	map_data = _load_json(MAP_PATH)
	arena_info = _load_json(INFO_PATH)

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

func reset() -> void:
	current_hub = "itubera"
	visited_hubs = ["itubera"]
	travel_log = []
	unlocked_hubs = ["itubera", "salvador", "zambiapunga", "camamu_manguezal"]
	current_page = "01"
	selected_node = ""
	if map_data.is_empty() or arena_info.is_empty():
		_load_v4_data()

# Legacy dense-hub travel contract kept intact for compatibility.
func get_hub_data(hub_id: String) -> Dictionary:
	return DataRegistry.hubs_dense.get("hubs", {}).get(hub_id, {})

func can_travel_to(hub_id: String) -> bool:
	return unlocked_hubs.has(hub_id) and not get_hub_data(hub_id).is_empty()

func travel_to(hub_id: String) -> Dictionary:
	if not can_travel_to(hub_id):
		return {"ok": false, "message": "Destino indisponivel."}
	var hub := get_hub_data(hub_id)
	var cost := int(hub.get("travel_cost", 0))
	if WorldState.money < cost:
		return {"ok": false, "message": "Dinheiro insuficiente para viajar."}
	WorldState.money -= cost
	current_hub = hub_id
	WorldState.current_hub = hub_id
	if not visited_hubs.has(hub_id):
		visited_hubs.append(hub_id)
	travel_log.append({"hub": hub_id, "week": WorldState.week, "day": WorldState.days[WorldState.day_index], "cost": cost})
	var hours := int(hub.get("travel_hours", 0))
	if hours >= int(DataRegistry.hubs_dense.get("travel_rules", {}).get("day_advance_threshold_hours", 8)):
		WorldState.advance_day()
	SaveManager.save_game(1)
	return {"ok": true, "message": "Viagem para " + str(hub.get("name", hub_id)) + " concluida.", "hub": hub}

func get_available_activities() -> Array:
	return get_hub_data(current_hub).get("activities", [])

func get_available_locations() -> Array:
	return get_hub_data(current_hub).get("locations", [])

# EPIC 69 / world_map_v4 API. WorldMapManager owns map state; UI only presents it.
func resolve_map_id(raw_id: String) -> String:
	return str(map_data.get("aliases", {}).get(raw_id, raw_id))

func get_pages() -> Array:
	return map_data.get("pages", [])

func get_page(page_id: String) -> Dictionary:
	for page_value in get_pages():
		var page: Dictionary = page_value
		if str(page.get("id", "")) == page_id:
			return page
	return {}

func set_page(page_id: String) -> bool:
	if get_page(page_id).is_empty():
		return false
	current_page = page_id
	return true

func get_page_nodes(page_id: String) -> Array:
	var out: Array = []
	for node_value in map_data.get("nodes", []):
		var node: Dictionary = node_value
		if str(node.get("pagina", "")) == page_id:
			out.append(node)
	return out

func get_page_anchors(page_id: String) -> Array:
	var out: Array = []
	for anchor_value in map_data.get("municipal_anchors", []):
		var anchor: Dictionary = anchor_value
		if str(anchor.get("pagina", "")) == page_id:
			out.append(anchor)
	return out

func get_map_node(raw_id: String) -> Dictionary:
	var node_id := resolve_map_id(raw_id)
	for node_value in map_data.get("nodes", []):
		var node: Dictionary = node_value
		if str(node.get("id", "")) == node_id:
			return node
	return {}

func get_arena_panel(raw_id: String) -> Dictionary:
	var node_id := resolve_map_id(raw_id)
	for panel_value in arena_info.get("arenas", []):
		var panel: Dictionary = panel_value
		if str(panel.get("id", "")) == node_id:
			return panel
	return {}

func evaluate_map_node(raw_id: String) -> Dictionary:
	var node := get_map_node(raw_id)
	if node.is_empty():
		return {"unlocked": false, "reason": "Nó inexistente."}
	return WorldMapRules.evaluate_node(node, _world_context())

func select_map_node(raw_id: String) -> Dictionary:
	var node_id := resolve_map_id(raw_id)
	var node := get_map_node(node_id)
	if node.is_empty():
		return {"ok": false, "message": "Nó inexistente."}
	selected_node = node_id
	return {
		"ok": true,
		"node": node,
		"panel": get_arena_panel(node_id),
		"evaluation": evaluate_map_node(node_id)
	}

func get_route_state(raw_from: String, raw_to: String) -> Dictionary:
	var from_id := resolve_map_id(raw_from)
	var to_id := resolve_map_id(raw_to)
	for route_value in map_data.get("routes", []):
		var route: Dictionary = route_value
		if str(route.get("from", "")) == from_id and str(route.get("to", "")) == to_id:
			var state := WorldMapRules.route_state(route, _world_context())
			state["route"] = route
			return state
	return {"available": false, "reason": "Rota não cadastrada."}

func get_page_evaluations(page_id: String) -> Dictionary:
	var result := {}
	for node_value in get_page_nodes(page_id):
		var node: Dictionary = node_value
		var node_id := str(node.get("id", ""))
		result[node_id] = WorldMapRules.evaluate_node(node, _world_context())
	return result

func _world_context() -> Dictionary:
	var flags: Dictionary = WorldState.story_flags if WorldState.story_flags is Dictionary else {}
	var fragments := int(flags.get("truth_fragments", flags.get("fragments", 0)))
	return {
		"act": int(WorldState.act),
		"hype": float(WorldState.get_reputation("hype")),
		"heat": int(flags.get("heat", 0)),
		"fragments": fragments,
		"reputation_tier": str(flags.get("reputation_tier", "")),
		"completed_missions": WorldState.completed_missions,
		"flags": flags
	}

func to_dict() -> Dictionary:
	return {
		"current_hub": current_hub,
		"visited_hubs": visited_hubs,
		"travel_log": travel_log,
		"unlocked_hubs": unlocked_hubs,
		"current_page": current_page,
		"selected_node": selected_node
	}

func load_from_dict(data: Dictionary) -> void:
	current_hub = str(data.get("current_hub", "itubera"))
	visited_hubs = data.get("visited_hubs", ["itubera"])
	travel_log = data.get("travel_log", [])
	unlocked_hubs = data.get("unlocked_hubs", unlocked_hubs)
	current_page = str(data.get("current_page", "01"))
	selected_node = resolve_map_id(str(data.get("selected_node", "")))
