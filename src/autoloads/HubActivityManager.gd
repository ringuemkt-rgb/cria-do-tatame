extends Node

var activity_log := []

func reset() -> void:
	activity_log = []

func get_activity(activity_id: String) -> Dictionary:
	return DataRegistry.hub_activities.get("activities", {}).get(activity_id, {})

func execute_activity(activity_id: String) -> Dictionary:
	var activity := get_activity(activity_id)
	if activity.is_empty():
		return {"ok": false, "message": "Atividade inexistente."}
	var energy_cost := float(activity.get("energy_cost", 0))
	if WorldState.energy < energy_cost:
		return {"ok": false, "message": "Energia insuficiente."}
	WorldState.energy = max(0.0, WorldState.energy - energy_cost)
	WorldState.money += int(activity.get("money", 0))
	var effects: Dictionary = activity.get("effects", {})
	for axis in ["honra", "hype", "sombra", "legado", "moral", "raiz"]:
		if effects.has(axis):
			WorldState.modify_reputation(axis, float(effects[axis]))
	if effects.has("energy"):
		WorldState.energy = min(100.0, WorldState.energy + float(effects["energy"]))
	if effects.has("strain_level"):
		WorldState.strain_level = max(0, WorldState.strain_level + int(effects["strain_level"]))
	activity_log.append({"id": activity_id, "week": WorldState.week, "day": WorldState.days[WorldState.day_index]})
	var hours := int(activity.get("time_hours", 0))
	if hours >= 6:
		WorldState.advance_day()
	SaveManager.save_game(1)
	return {"ok": true, "message": "Atividade concluida: " + str(activity.get("name", activity_id))}

func roll_dynamic_event() -> Dictionary:
	var events: Array = DataRegistry.hub_activities.get("dynamic_events", [])
	var available := []
	for event in events:
		if _conditions_met(event.get("conditions", {})):
			available.append(event)
	if available.is_empty():
		return {}
	return available.pick_random()

func _conditions_met(conditions: Dictionary) -> bool:
	for key in conditions.keys():
		if key.ends_with("_min"):
			var axis := key.replace("_min", "")
			if WorldState.get_reputation(axis) < float(conditions[key]):
				return false
		elif key.ends_with("_max"):
			var axis := key.replace("_max", "")
			if WorldState.get_reputation(axis) > float(conditions[key]):
				return false
	return true

func to_dict() -> Dictionary:
	return {"activity_log": activity_log}

func load_from_dict(data: Dictionary) -> void:
	activity_log = data.get("activity_log", [])
