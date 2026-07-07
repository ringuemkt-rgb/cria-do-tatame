extends Node

var current_hub := "itubera"
var visited_hubs := ["itubera"]
var travel_log := []
var unlocked_hubs := ["itubera", "salvador", "zambiapunga", "camamu_manguezal"]

func reset() -> void:
	current_hub = "itubera"
	visited_hubs = ["itubera"]
	travel_log = []
	unlocked_hubs = ["itubera", "salvador", "zambiapunga", "camamu_manguezal"]

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

func to_dict() -> Dictionary:
	return {"current_hub": current_hub, "visited_hubs": visited_hubs, "travel_log": travel_log, "unlocked_hubs": unlocked_hubs}

func load_from_dict(data: Dictionary) -> void:
	current_hub = str(data.get("current_hub", "itubera"))
	visited_hubs = data.get("visited_hubs", ["itubera"])
	travel_log = data.get("travel_log", [])
	unlocked_hubs = data.get("unlocked_hubs", unlocked_hubs)
