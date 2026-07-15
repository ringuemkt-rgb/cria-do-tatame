extends Node

var activity_log: Array = []

func reset() -> void:
	activity_log = []

func get_activity(activity_id: String) -> Dictionary:
	var activities: Dictionary = DataRegistry.hub_activities.get("activities", {})
	return activities.get(activity_id, {})

func get_available_for_hub(hub_id: String) -> Array:
	var output: Array = []
	for activity_id_value in DataRegistry.hub_activities.get("activities", {}).keys():
		var activity_id: String = str(activity_id_value)
		var activity: Dictionary = get_activity(activity_id)
		var activity_hub: String = str(activity.get("hub", "any"))
		if activity_hub == "any" or activity_hub == hub_id:
			var item: Dictionary = activity.duplicate(true)
			item["id"] = activity_id
			output.append(item)
	output.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.get("name", "")) < str(b.get("name", "")))
	return output

func execute_activity(activity_id: String) -> Dictionary:
	var activity: Dictionary = get_activity(activity_id)
	if activity.is_empty():
		return {"ok": false, "message": "Atividade inexistente."}
	var required_hub: String = str(activity.get("hub", "any"))
	var current_hub: String = str(WorldMapManager.current_hub)
	if required_hub != "any" and required_hub != current_hub:
		return {"ok": false, "message": "Esta atividade não está disponível neste território."}
	var energy_cost: float = maxf(0.0, float(activity.get("energy_cost", 0.0)))
	if WorldState.energy < energy_cost:
		return {"ok": false, "message": "Energia insuficiente."}
	var money_delta: int = int(activity.get("money", 0))
	if money_delta < 0 and WorldState.money < absi(money_delta):
		return {"ok": false, "message": "Dinheiro insuficiente."}
	var gear_result: Dictionary = {}
	var gear_id: String = str(activity.get("gear_id", ""))
	if gear_id != "":
		if GearManager.inventory.has(gear_id):
			gear_result = {"ok": true, "message": "Item já pertence ao inventário."}
		else:
			gear_result = GearManager.buy_item(gear_id)
			if not bool(gear_result.get("ok", false)):
				return gear_result
	WorldState.energy = maxf(0.0, WorldState.energy - energy_cost)
	WorldState.money += money_delta
	var effects: Dictionary = activity.get("effects", {})
	for axis_value in ["honra", "hype", "sombra", "legado", "moral", "raiz"]:
		var axis: String = str(axis_value)
		if effects.has(axis):
			WorldState.modify_reputation(axis, float(effects[axis]))
	if effects.has("energy"):
		WorldState.energy = clampf(WorldState.energy + float(effects["energy"]), 0.0, 100.0)
	if effects.has("strain_level"):
		WorldState.strain_level = maxi(0, WorldState.strain_level + int(effects["strain_level"]))
	if effects.has("skill_points"):
		WorldState.skill_points = maxi(0, WorldState.skill_points + int(effects["skill_points"]))
	var story_flag: String = str(activity.get("story_flag", ""))
	if story_flag != "":
		WorldState.story_flags[story_flag] = true
	var risk_result: Dictionary = _apply_risk(activity_id, activity.get("risk", {}))
	var live_context: String = str(activity.get("cria_live_context", ""))
	if live_context != "":
		CriaLiveManager.generate_post(live_context, {
			"activity_id": activity_id,
			"hub_id": current_hub,
			"text": str(activity.get("live_text", "Atividade registrada no território."))
		})
	activity_log.append({
		"id": activity_id,
		"hub": current_hub,
		"week": WorldState.week,
		"day": WorldState.days[WorldState.day_index],
		"risk_triggered": bool(risk_result.get("triggered", false))
	})
	var hours: int = maxi(0, int(activity.get("time_hours", 0)))
	if hours >= 6:
		WorldState.advance_day()
	WorldState._sync_aliases()
	SaveManager.save_game(1)
	var message: String = "Atividade concluída: " + str(activity.get("name", activity_id))
	if not gear_result.is_empty():
		message += " • " + str(gear_result.get("message", "Equipamento atualizado."))
	if bool(risk_result.get("triggered", false)):
		message += " • Houve consequência física ou social."
	return {"ok": true, "message": message, "activity": activity, "risk": risk_result, "gear": gear_result}

func _apply_risk(activity_id: String, risk_value) -> Dictionary:
	if typeof(risk_value) != TYPE_DICTIONARY:
		return {"triggered": false}
	var risk: Dictionary = risk_value
	var probability: float = clampf(float(risk.get("strain", 0.0)), 0.0, 1.0)
	if probability <= 0.0:
		if risk.has("sombra"):
			WorldState.modify_reputation("sombra", float(risk["sombra"]))
		return {"triggered": false}
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(hash("%s|%s|%s|%s" % [activity_id, WorldState.week, WorldState.day_index, activity_log.size()]))
	var triggered: bool = rng.randf() <= probability
	if triggered:
		WorldState.strain_level = mini(5, WorldState.strain_level + 1)
		if risk.has("sombra"):
			WorldState.modify_reputation("sombra", float(risk["sombra"]))
	return {"triggered": triggered, "probability": probability}

func roll_dynamic_event() -> Dictionary:
	var events: Array = DataRegistry.hub_activities.get("dynamic_events", [])
	var available: Array = []
	for event_value in events:
		if typeof(event_value) != TYPE_DICTIONARY:
			continue
		var event: Dictionary = event_value
		if _conditions_met(event.get("conditions", {})):
			available.append(event)
	if available.is_empty():
		return {}
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(hash("hub_event|%s|%s|%s" % [WorldMapManager.current_hub, WorldState.week, WorldState.day_index]))
	return available[rng.randi_range(0, available.size() - 1)].duplicate(true)

func _conditions_met(conditions: Dictionary) -> bool:
	for key_value in conditions.keys():
		var key: String = str(key_value)
		if key.ends_with("_min"):
			var axis_min: String = key.replace("_min", "")
			if WorldState.get_reputation(axis_min) < float(conditions[key]):
				return false
		elif key.ends_with("_max"):
			var axis_max: String = key.replace("_max", "")
			if WorldState.get_reputation(axis_max) > float(conditions[key]):
				return false
	return true

func to_dict() -> Dictionary:
	return {"activity_log": activity_log.duplicate(true)}

func load_from_dict(data: Dictionary) -> void:
	activity_log = data.get("activity_log", []).duplicate(true)
