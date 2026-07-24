extends "res://src/autoloads/WorldMapManager.gd"

## Extensão do mapa legado com onze municípios, localização especial Pratigi,
## viagens terrestre/fluvial e moeda dual. Cenas ausentes continuam bloqueadas
## para entrada física, mas o nó pode existir no mapa e em missões.

var world_nodes: Dictionary = {}
var special_locations: Dictionary = {}
var seasonal_events: Array = []
var active_route_blocks: Dictionary = {}
var visited_nodes_v4: Array[String] = ["itubera"]
var unlocked_nodes_v4: Array[String] = ["itubera", "valenca", "nilo_pecanha", "camamu"]

func _ready() -> void:
	_load_v4_data()
	_sync_legacy_hubs()

func reset() -> void:
	super.reset()
	visited_nodes_v4 = ["itubera"]
	unlocked_nodes_v4 = ["itubera", "valenca", "nilo_pecanha", "camamu"]
	active_route_blocks = {}
	_sync_legacy_hubs()

func _load_v4_data() -> void:
	var map_data: Dictionary = DataRegistry.world_map_nodes_v4 if "world_map_nodes_v4" in DataRegistry else _load_json("res://data/world/world_map_nodes_v4.json")
	var events_data: Dictionary = DataRegistry.seasonal_events_v4 if "seasonal_events_v4" in DataRegistry else _load_json("res://data/world/seasonal_events_v4.json")
	world_nodes = map_data.get("nodes", {}).duplicate(true)
	special_locations = map_data.get("special_locations", {}).duplicate(true)
	seasonal_events = events_data.get("eventos", []).duplicate(true)

func get_node_data(node_id: String) -> Dictionary:
	return world_nodes.get(node_id, {}).duplicate(true)

func get_special_location(location_id: String) -> Dictionary:
	return special_locations.get(location_id, {}).duplicate(true)

func unlock_node(node_id: String, reason: String = "story") -> bool:
	if not world_nodes.has(node_id):
		return false
	if not unlocked_nodes_v4.has(node_id):
		unlocked_nodes_v4.append(node_id)
		if SignalBus.has_signal("world_node_unlocked"):
			SignalBus.world_node_unlocked.emit(node_id, reason)
	return true

func is_node_unlocked(node_id: String) -> bool:
	return unlocked_nodes_v4.has(node_id)

func can_travel_v4(node_id: String, mode: String = "terrestre") -> Dictionary:
	if not world_nodes.has(node_id):
		return {"ok": false, "error": "node_missing"}
	if not is_node_unlocked(node_id):
		return {"ok": false, "error": "node_locked"}
	if active_route_blocks.has("%s:%s" % [current_hub, node_id]):
		return {"ok": false, "error": "route_blocked", "reason": active_route_blocks["%s:%s" % [current_hub, node_id]]}
	var node: Dictionary = world_nodes[node_id]
	var blocked_until := str(node.get("blocked_until", ""))
	if blocked_until != "" and not bool(WorldState.story_flags.get(blocked_until, false)):
		return {"ok": false, "error": "story_gate", "required": blocked_until}
	var quote: Dictionary = Economy.quote_travel(node, mode)
	if not bool(quote.get("ok", false)):
		return quote
	if Economy.get_balance(str(quote["currency"])) < int(quote["amount"]):
		return {"ok": false, "error": "insufficient_balance", "quote": quote}
	return {"ok": true, "node": node, "quote": quote}

func travel_v4(node_id: String, mode: String = "terrestre") -> Dictionary:
	var validation := can_travel_v4(node_id, mode)
	if not bool(validation.get("ok", false)):
		return validation
	var quote: Dictionary = validation["quote"]
	var spend_result: Dictionary = Economy.spend(str(quote["currency"]), int(quote["amount"]), "viagem_%s" % mode, {"from": current_hub, "to": node_id})
	if not bool(spend_result.get("ok", false)):
		return spend_result
	var previous := current_hub
	current_hub = node_id
	WorldState.current_hub = node_id
	if not visited_nodes_v4.has(node_id): visited_nodes_v4.append(node_id)
	if not visited_hubs.has(node_id): visited_hubs.append(node_id)
	travel_log.append({"from":previous,"hub":node_id,"mode":mode,"week":WorldState.week,"day":WorldState.current_day,"currency":quote["currency"],"cost":quote["amount"]})
	if mode == "fluvial":
		FactionManager.apply_relation_delta("NTM", 1.0, "river_travel")
	elif mode == "terrestre":
		FactionManager.apply_heat_delta("LEM", 0.5, "road_travel")
	WorldState.advance_day()
	SaveManager.save_game(1)
	if SignalBus.has_signal("world_travel_completed_v4"):
		SignalBus.world_travel_completed_v4.emit(previous, node_id, mode, quote)
	return {"ok": true, "from": previous, "to": node_id, "mode": mode, "quote": quote, "node": validation["node"]}

func enter_node_scene(node_id: String = "") -> Dictionary:
	var resolved := node_id if node_id != "" else current_hub
	var node := get_node_data(resolved)
	if node.is_empty(): return {"ok": false, "error": "node_missing"}
	var scene_path := str(node.get("scene", ""))
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		return {"ok": false, "error": "scene_not_produced", "node_id": resolved}
	SignalBus.request_scene(scene_path)
	return {"ok": true, "scene": scene_path}

func get_active_seasonal_events(month: int, day: int) -> Array:
	var output: Array = []
	for event_value in seasonal_events:
		var event: Dictionary = event_value
		var id := str(event.get("id", ""))
		var active := false
		if id == "zambiapunga": active = (month == 10 and day == 31) or (month == 11 and day == 1)
		elif id == "sao_joao": active = month == 6
		elif id == "chuvas_itubera": active = month in [2, 3]
		elif id == "paralelo_pratigi": active = month in [12, 1, 2]
		if active: output.append(event.duplicate(true))
	return output

func block_route(from_id: String, to_id: String, reason: String) -> void:
	active_route_blocks["%s:%s" % [from_id, to_id]] = reason.left(96)

func unblock_route(from_id: String, to_id: String) -> void:
	active_route_blocks.erase("%s:%s" % [from_id, to_id])

func get_hub_data(hub_id: String) -> Dictionary:
	var node := get_node_data(hub_id)
	if not node.is_empty(): return node
	return super.get_hub_data(hub_id)

func can_travel_to(hub_id: String) -> bool:
	if world_nodes.has(hub_id):
		return bool(can_travel_v4(hub_id, "terrestre").get("ok", false)) or bool(can_travel_v4(hub_id, "fluvial").get("ok", false))
	return super.can_travel_to(hub_id)

func to_dict() -> Dictionary:
	var legacy: Dictionary = super.to_dict()
	legacy["version"] = 4
	legacy["visited_nodes_v4"] = visited_nodes_v4.duplicate()
	legacy["unlocked_nodes_v4"] = unlocked_nodes_v4.duplicate()
	legacy["active_route_blocks"] = active_route_blocks.duplicate(true)
	return legacy

func load_from_dict(data: Dictionary) -> void:
	super.load_from_dict(data)
	visited_nodes_v4 = []
	for value in data.get("visited_nodes_v4", data.get("visited_hubs", ["itubera"])):
		visited_nodes_v4.append(str(value))
	unlocked_nodes_v4 = []
	for value in data.get("unlocked_nodes_v4", ["itubera", "valenca", "nilo_pecanha", "camamu"]):
		unlocked_nodes_v4.append(str(value))
	active_route_blocks = data.get("active_route_blocks", {}).duplicate(true)
	_sync_legacy_hubs()

func _sync_legacy_hubs() -> void:
	unlocked_hubs = unlocked_nodes_v4.duplicate()
	visited_hubs = visited_nodes_v4.duplicate()

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}
