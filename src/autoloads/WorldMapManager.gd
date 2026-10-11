extends Node

# Existing runtime hubs in the approved playable Baixo Sul region.
# Story hubs outside this set remain readable for legacy save history.
const PLAYABLE_HUB_IDS := ["itubera", "zambiapunga", "camamu_manguezal"]

var current_hub := "itubera"
var visited_hubs := ["itubera"]
var travel_log := []
var unlocked_hubs := PLAYABLE_HUB_IDS.duplicate()

func reset() -> void:
	current_hub = "itubera"
	visited_hubs = ["itubera"]
	travel_log = []
	unlocked_hubs = PLAYABLE_HUB_IDS.duplicate()

func get_hub_data(hub_id: String) -> Dictionary:
	return DataRegistry.hubs_dense.get("hubs", {}).get(hub_id, {})

func can_travel_to(hub_id: String) -> bool:
	return PLAYABLE_HUB_IDS.has(hub_id) and unlocked_hubs.has(hub_id) and not get_hub_data(hub_id).is_empty()

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
	var first_visit := not visited_hubs.has(hub_id)
	if first_visit:
		visited_hubs.append(hub_id)
	var travel_entry := {
		"hub": hub_id,
		"week": WorldState.week,
		"day": WorldState.days[WorldState.day_index],
		"cost": cost
	}
	travel_log.append(travel_entry)
	var hours := int(hub.get("travel_hours", 0))
	if hours >= int(DataRegistry.hubs_dense.get("travel_rules", {}).get("day_advance_threshold_hours", 8)):
		WorldState.advance_day()
	if SignalBus.has_signal("world_travel_completed"):
		SignalBus.world_travel_completed.emit(StringName(hub_id), first_visit, travel_entry.duplicate(true))
	SaveManager.save_game(1)
	return {"ok": true, "message": "Viagem para " + str(hub.get("name", hub_id)) + " concluida.", "hub": hub}

func get_available_activities() -> Array:
	return get_hub_data(current_hub).get("activities", [])

func get_available_locations() -> Array:
	return get_hub_data(current_hub).get("locations", [])

func to_dict() -> Dictionary:
	return {"current_hub": current_hub, "visited_hubs": visited_hubs, "travel_log": travel_log, "unlocked_hubs": unlocked_hubs}

func load_from_dict(data: Dictionary) -> void:
	var saved_hub := str(data.get("current_hub", "itubera"))
	# Preserve old travel history without retaining a playable destination
	# outside Baixo Sul. Historical Salvador save loads safely into Ituberá.
	current_hub = saved_hub if PLAYABLE_HUB_IDS.has(saved_hub) and not get_hub_data(saved_hub).is_empty() else "itubera"
	var previous_visits = data.get("visited_hubs", ["itubera"])
	visited_hubs = previous_visits.duplicate() if typeof(previous_visits) == TYPE_ARRAY else ["itubera"]
	if not visited_hubs.has("itubera"):
		visited_hubs.append("itubera")
	var historical_travel = data.get("travel_log", [])
	travel_log = historical_travel.duplicate(true) if typeof(historical_travel) == TYPE_ARRAY else []
	var previously_unlocked = data.get("unlocked_hubs", PLAYABLE_HUB_IDS)
	unlocked_hubs = ["itubera"]
	if typeof(previously_unlocked) == TYPE_ARRAY:
		for hub_id_value in previously_unlocked:
			var id := str(hub_id_value)
			if PLAYABLE_HUB_IDS.has(id) and not unlocked_hubs.has(id):
				unlocked_hubs.append(id)
	WorldState.current_hub = current_hub
