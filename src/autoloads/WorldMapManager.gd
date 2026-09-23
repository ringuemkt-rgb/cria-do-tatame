extends Node

const ResolverScript = preload("res://src/world/WorldRouteResolver.gd")
const VehicleServiceScript = preload("res://src/world/VehicleServiceModel.gd")
const TRAVEL_CONTRACT_PATH := "res://data/world/vehicle_world_travel_v1.json"
const WORLD_TRAVEL_STATE_VERSION := 1
const MAX_COMMITTED_PLAN_IDS := 64

var current_hub := "itubera"
var current_node := "itubera"
var visited_hubs := ["itubera"]
var travel_log := []
var unlocked_hubs := ["itubera", "salvador", "zambiapunga", "camamu_manguezal"]
var world_travel_state: Dictionary = {
	"version": WORLD_TRAVEL_STATE_VERSION,
	"vehicle_states": {},
	"route_mastery": {},
	"route_records": {},
	"pending_travel_plan": {},
	"arrival_condition": "fresh",
	"committed_plan_ids": [],
	"next_plan_sequence": 1,
	"route_unlocks": []
}

var _resolver = ResolverScript.new()
var _vehicle_service = VehicleServiceScript.new()
var _travel_contract: Dictionary = {}

func _ready() -> void:
	_ensure_travel_runtime()

func reset() -> void:
	current_hub = "itubera"
	current_node = "itubera"
	visited_hubs = ["itubera"]
	travel_log = []
	unlocked_hubs = ["itubera", "salvador", "zambiapunga", "camamu_manguezal"]
	world_travel_state = _default_world_travel_state()
	_ensure_travel_runtime()

func get_hub_data(hub_id: String) -> Dictionary:
	return DataRegistry.hubs_dense.get("hubs", {}).get(hub_id, {})

func can_travel_to(hub_id: String) -> bool:
	return unlocked_hubs.has(hub_id) and not get_hub_data(hub_id).is_empty()

# Legacy compatibility facade. The data-driven node flow migrates to
# prepare_travel() -> route gameplay/resolution -> commit_travel_outcome().
# Keep this path until the four legacy hub buttons are removed after VT3+ QA.
func travel_to(hub_id: String) -> Dictionary:
	if not can_travel_to(hub_id):
		return {"ok": false, "message": "Destino indisponivel."}
	var hub := get_hub_data(hub_id)
	var cost := int(hub.get("travel_cost", 0))
	if WorldState.money < cost:
		return {"ok": false, "message": "Dinheiro insuficiente para viajar."}
	WorldState.money -= cost
	current_hub = hub_id
	current_node = hub_id
	WorldState.current_hub = hub_id
	var first_visit := not visited_hubs.has(hub_id)
	if first_visit:
		visited_hubs.append(hub_id)
	var travel_entry := {
		"hub": hub_id,
		"week": WorldState.week,
		"day": WorldState.days[WorldState.day_index],
		"cost": cost,
		"legacy": true
	}
	travel_log.append(travel_entry)
	var hours := int(hub.get("travel_hours", 0))
	if hours >= int(DataRegistry.hubs_dense.get("travel_rules", {}).get("day_advance_threshold_hours", 8)):
		WorldState.advance_day()
	if SignalBus.has_signal("world_travel_completed"):
		SignalBus.world_travel_completed.emit(StringName(hub_id), first_visit, travel_entry.duplicate(true))
	SaveManager.save_game(1)
	return {"ok": true, "message": "Viagem para " + str(hub.get("name", hub_id)) + " concluida.", "hub": hub}

func prepare_travel(destination_node: String, vehicle_id: String, world_context: Dictionary = {}) -> Dictionary:
	_ensure_travel_runtime()
	var pending: Dictionary = world_travel_state.get("pending_travel_plan", {})
	if not pending.is_empty():
		return _travel_error("travel_plan_already_pending", {"plan_id": str(pending.get("plan_id", ""))})

	var destination := destination_node.strip_edges()
	var vehicle := vehicle_id.strip_edges()
	if destination == "" or vehicle == "":
		return _travel_error("destination_or_vehicle_empty")

	var origin := current_node.strip_edges()
	if origin == "":
		origin = current_hub
	var context := _build_world_context(world_context)
	var resolved: Dictionary = _resolver.resolve_route(origin, destination, context)
	if not bool(resolved.get("ok", false)):
		return _travel_error(str(resolved.get("error", "route_resolution_failed")), resolved.get("details", {}))

	var route: Dictionary = resolved.get("route", {})
	if not bool(route.get("traversable", false)):
		return _travel_error("route_gated", {
			"route_id": str(route.get("id", "")),
			"reasons": route.get("gate_status", {}).get("reasons", []).duplicate()
		})

	var method_option := _find_method_option(route.get("method_options", []), vehicle)
	if method_option.is_empty():
		return _travel_error("vehicle_not_allowed_for_route", {
			"vehicle_id": vehicle,
			"route_class": str(route.get("route_class", ""))
		})

	var base_money_cost := maxi(0, int(route.get("base_money_cost", 0)))
	var base_fuel_cost := maxf(0.0, float(route.get("base_fuel_cost", 0.0)))
	if int(WorldState.money) < base_money_cost:
		return _travel_error("insufficient_money", {"required": base_money_cost, "available": int(WorldState.money)})

	var vehicle_state: Dictionary = world_travel_state.get("vehicle_states", {}).get(vehicle, {}).duplicate(true)
	if vehicle_state.has("fuel") and float(vehicle_state.get("fuel", 0.0)) < base_fuel_cost:
		return _travel_error("insufficient_fuel", {"required": base_fuel_cost, "available": float(vehicle_state.get("fuel", 0.0))})
	var vehicle_stats := _vehicle_service.get_effective_stats(vehicle, vehicle_state)

	var sequence := maxi(1, int(world_travel_state.get("next_plan_sequence", 1)))
	var plan_id := "travel:%08d:%s:%s:%s" % [sequence, origin, destination, vehicle]
	var plan := {
		"plan_id": plan_id,
		"origin_node": origin,
		"origin_hub": current_hub,
		"destination_node": destination,
		"route_id": str(route.get("id", "")),
		"route_type": str(route.get("type", "")),
		"route_subtype": str(route.get("subtype", "")),
		"route_class": str(route.get("route_class", "")),
		"vehicle_id": vehicle,
		"vehicle_state_snapshot": vehicle_state.duplicate(true),
		"vehicle_stats_snapshot": vehicle_stats.duplicate(true),
		"world_context_snapshot": route.get("world_context_snapshot", {}).duplicate(true),
		"base_time_minutes": maxi(0, int(route.get("base_time_minutes", 0))),
		"base_money_cost": base_money_cost,
		"base_fuel_cost": base_fuel_cost,
		"gates": route.get("gate_status", {}).duplicate(true),
		"mode": str(method_option.get("mode", "resolved_travel")),
		"minigame": str(route.get("minigame", "")),
		"prepared_week": int(WorldState.week),
		"prepared_day": str(WorldState.days[WorldState.day_index])
	}
	world_travel_state["pending_travel_plan"] = plan.duplicate(true)
	world_travel_state["next_plan_sequence"] = sequence + 1
	return {"ok": true, "plan": plan.duplicate(true)}

func commit_travel_outcome(plan_id: String, outcome: Dictionary) -> Dictionary:
	_ensure_travel_runtime()
	var resolved_plan_id := plan_id.strip_edges()
	if resolved_plan_id == "":
		return _travel_error("plan_id_empty")
	if _was_plan_committed(resolved_plan_id):
		return _travel_error("plan_already_committed", {"plan_id": resolved_plan_id})

	var plan: Dictionary = world_travel_state.get("pending_travel_plan", {})
	if plan.is_empty():
		return _travel_error("no_pending_travel_plan")
	if str(plan.get("plan_id", "")) != resolved_plan_id:
		return _travel_error("pending_plan_mismatch", {
			"expected": str(plan.get("plan_id", "")),
			"received": resolved_plan_id
		})

	var success := bool(outcome.get("success", false))
	var money_delta := int(outcome.get("money_delta", -int(plan.get("base_money_cost", 0))))
	var energy_delta := float(outcome.get("energy_delta", 0.0))
	var next_money := int(WorldState.money) + money_delta
	if next_money < 0:
		return _travel_error("insufficient_money_at_commit", {"money_delta": money_delta, "available": int(WorldState.money)})
	var next_energy := clampf(float(WorldState.energy) + energy_delta, 0.0, 100.0)

	var vehicle_preview := _preview_vehicle_outcome(plan, outcome)
	if not bool(vehicle_preview.get("ok", false)):
		return _travel_error(str(vehicle_preview.get("error", "vehicle_outcome_invalid")), vehicle_preview.get("details", {}))

	var origin_hub := str(plan.get("origin_hub", current_hub))
	var destination_node := str(plan.get("destination_node", ""))
	var destination_hub := _resolve_destination_hub(destination_node, outcome)
	var first_hub_visit := false
	if success and destination_hub != "":
		first_hub_visit = not visited_hubs.has(destination_hub)

	# Atomic section starts only after all validations/previews above succeeded.
	WorldState.money = next_money
	WorldState.energy = next_energy
	WorldState._sync_aliases()
	_apply_vehicle_preview(str(plan.get("vehicle_id", "")), vehicle_preview.get("state", {}))

	if success:
		current_node = destination_node
		if destination_hub != "":
			current_hub = destination_hub
			WorldState.current_hub = destination_hub
			if first_hub_visit:
				visited_hubs.append(destination_hub)

	var elapsed_minutes := maxi(0, int(outcome.get("elapsed_minutes", plan.get("base_time_minutes", 0))))
	_apply_elapsed_time(elapsed_minutes, bool(outcome.get("advance_day", false)))

	var arrival_condition := _validated_arrival_condition(str(outcome.get("arrival_condition", "steady" if success else "shaken")))
	world_travel_state["arrival_condition"] = arrival_condition
	var mastery_change := _update_route_progress(plan, outcome, success, elapsed_minutes)

	var travel_entry := {
		"plan_id": resolved_plan_id,
		"route_id": str(plan.get("route_id", "")),
		"origin_node": str(plan.get("origin_node", "")),
		"destination_node": destination_node,
		"origin_hub": origin_hub,
		"destination_hub": destination_hub,
		"vehicle_id": str(plan.get("vehicle_id", "")),
		"mode": str(plan.get("mode", "")),
		"success": success,
		"elapsed_minutes": elapsed_minutes,
		"money_delta": money_delta,
		"energy_delta": energy_delta,
		"arrival_condition": arrival_condition,
		"discoveries": outcome.get("discoveries", []).duplicate() if typeof(outcome.get("discoveries", [])) == TYPE_ARRAY else [],
		"failure_reason": str(outcome.get("failure_reason", outcome.get("reason", ""))),
		"week": int(WorldState.week),
		"day": str(WorldState.days[WorldState.day_index]),
		"two_phase": true
	}
	travel_log.append(travel_entry)
	_mark_plan_committed(resolved_plan_id)
	world_travel_state["pending_travel_plan"] = {}

	_record_progression_travel_events(plan, outcome, travel_entry, mastery_change)
	if success and destination_hub != "" and destination_hub != origin_hub and SignalBus.has_signal("world_travel_completed"):
		SignalBus.world_travel_completed.emit(StringName(destination_hub), first_hub_visit, travel_entry.duplicate(true))

	SaveManager.save_game(1)
	return {
		"ok": true,
		"travel_success": success,
		"plan_id": resolved_plan_id,
		"travel_entry": travel_entry.duplicate(true),
		"route_mastery": mastery_change.get("entry", {}).duplicate(true)
	}

func cancel_pending_travel(plan_id: String = "") -> Dictionary:
	var pending: Dictionary = world_travel_state.get("pending_travel_plan", {})
	if pending.is_empty():
		return {"ok": true, "cancelled": false}
	if plan_id.strip_edges() != "" and str(pending.get("plan_id", "")) != plan_id.strip_edges():
		return _travel_error("pending_plan_mismatch", {"expected": str(pending.get("plan_id", "")), "received": plan_id})
	var cancelled_id := str(pending.get("plan_id", ""))
	world_travel_state["pending_travel_plan"] = {}
	return {"ok": true, "cancelled": true, "plan_id": cancelled_id}

func get_pending_travel_plan() -> Dictionary:
	return world_travel_state.get("pending_travel_plan", {}).duplicate(true)

func get_route_mastery(route_id: String) -> Dictionary:
	return world_travel_state.get("route_mastery", {}).get(route_id, {}).duplicate(true)

func get_vehicle_state(vehicle_id: String) -> Dictionary:
	_ensure_travel_runtime()
	return world_travel_state.get("vehicle_states", {}).get(vehicle_id, {}).duplicate(true)

func get_vehicle_effective_stats(vehicle_id: String) -> Dictionary:
	_ensure_travel_runtime()
	return _vehicle_service.get_effective_stats(vehicle_id, get_vehicle_state(vehicle_id))

func quote_vehicle_service(vehicle_id: String, request: Dictionary) -> Dictionary:
	_ensure_travel_runtime()
	if not get_pending_travel_plan().is_empty():
		return _travel_error("vehicle_service_blocked_during_pending_travel", {"plan_id": str(get_pending_travel_plan().get("plan_id", ""))})
	return _vehicle_service.quote(vehicle_id, get_vehicle_state(vehicle_id), request)

func service_vehicle(vehicle_id: String, request: Dictionary) -> Dictionary:
	var quote: Dictionary = quote_vehicle_service(vehicle_id, request)
	if not bool(quote.get("ok", false)):
		return quote
	var total_cost := maxi(0, int(quote.get("total_cost", 0)))
	if int(WorldState.money) < total_cost:
		return _travel_error("insufficient_money_for_vehicle_service", {"required": total_cost, "available": int(WorldState.money)})
	if bool(quote.get("no_op", false)):
		return {
			"ok": true,
			"vehicle_id": vehicle_id,
			"spent": 0,
			"state": get_vehicle_state(vehicle_id),
			"effective_stats": get_vehicle_effective_stats(vehicle_id),
			"line_items": []
		}

	var vehicle_states: Dictionary = world_travel_state.get("vehicle_states", {})
	vehicle_states[vehicle_id] = quote.get("projected_state", {}).duplicate(true)
	world_travel_state["vehicle_states"] = vehicle_states
	WorldState.money -= total_cost
	WorldState._sync_aliases()
	SaveManager.save_game(1)
	return {
		"ok": true,
		"vehicle_id": vehicle_id,
		"spent": total_cost,
		"state": get_vehicle_state(vehicle_id),
		"effective_stats": get_vehicle_effective_stats(vehicle_id),
		"line_items": quote.get("line_items", []).duplicate(true)
	}

func get_available_activities() -> Array:
	return get_hub_data(current_hub).get("activities", [])

func get_available_locations() -> Array:
	return get_hub_data(current_hub).get("locations", [])

func to_dict() -> Dictionary:
	return {
		"current_hub": current_hub,
		"current_node": current_node,
		"visited_hubs": visited_hubs.duplicate(),
		"travel_log": travel_log.duplicate(true),
		"unlocked_hubs": unlocked_hubs.duplicate(),
		"world_travel_state": world_travel_state.duplicate(true)
	}

func load_from_dict(data: Dictionary) -> void:
	current_hub = str(data.get("current_hub", "itubera"))
	current_node = str(data.get("current_node", current_hub))
	visited_hubs = data.get("visited_hubs", ["itubera"]).duplicate()
	travel_log = data.get("travel_log", []).duplicate(true)
	unlocked_hubs = data.get("unlocked_hubs", unlocked_hubs).duplicate()
	world_travel_state = _default_world_travel_state()
	var saved_travel_state: Dictionary = data.get("world_travel_state", {})
	for key_value in saved_travel_state.keys():
		world_travel_state[str(key_value)] = saved_travel_state[key_value].duplicate(true) if typeof(saved_travel_state[key_value]) in [TYPE_DICTIONARY, TYPE_ARRAY] else saved_travel_state[key_value]
	_ensure_travel_runtime()

func _ensure_travel_runtime() -> void:
	if _travel_contract.is_empty():
		_travel_contract = _load_json(TRAVEL_CONTRACT_PATH)
	if _resolver.map_data.is_empty() or _resolver.travel_contract.is_empty():
		_resolver.initialize({}, _travel_contract)
	_vehicle_service.initialize(
		_travel_contract.get("vehicles", {}),
		_travel_contract.get("kombi_upgrades", {}),
		DataRegistry.economy if has_node("/root/DataRegistry") else {}
	)
	_ensure_world_travel_state()

func _default_world_travel_state() -> Dictionary:
	return {
		"version": WORLD_TRAVEL_STATE_VERSION,
		"vehicle_states": {},
		"route_mastery": {},
		"route_records": {},
		"pending_travel_plan": {},
		"arrival_condition": "fresh",
		"committed_plan_ids": [],
		"next_plan_sequence": 1,
		"route_unlocks": []
	}

func _ensure_world_travel_state() -> void:
	var defaults := _default_world_travel_state()
	for key_value in defaults.keys():
		var key := str(key_value)
		if not world_travel_state.has(key):
			var default_value: Variant = defaults[key]
			world_travel_state[key] = default_value.duplicate(true) if typeof(default_value) in [TYPE_DICTIONARY, TYPE_ARRAY] else default_value
	world_travel_state["version"] = WORLD_TRAVEL_STATE_VERSION

	var vehicle_states: Dictionary = world_travel_state.get("vehicle_states", {})
	for vehicle_id_value in _travel_contract.get("vehicles", {}).keys():
		var vehicle_id := str(vehicle_id_value)
		if not vehicle_states.has(vehicle_id):
			var vehicle: Dictionary = _travel_contract.get("vehicles", {}).get(vehicle_id_value, {})
			var default_state: Dictionary = vehicle.get("default_state", {})
			if not default_state.is_empty():
				vehicle_states[vehicle_id] = default_state.duplicate(true)
	world_travel_state["vehicle_states"] = vehicle_states

func _build_world_context(override: Dictionary) -> Dictionary:
	var context := override.duplicate(true)
	if not context.has("act"):
		context["act"] = int(WorldState.act)
	if not context.has("sombra"):
		context["sombra"] = int(WorldState.get_reputation("sombra"))
	if not context.has("hype"):
		context["hype"] = int(WorldState.get_reputation("hype"))
	if not context.has("honra"):
		context["honra"] = int(WorldState.get_reputation("honra"))
	if not context.has("flags"):
		context["flags"] = WorldState.story_flags.duplicate(true)
	if not context.has("completed_missions"):
		context["completed_missions"] = WorldState.completed_missions.duplicate()
	if not context.has("route_unlocks"):
		context["route_unlocks"] = world_travel_state.get("route_unlocks", []).duplicate()
	if not context.has("weather") and has_node("/root/WorldDirectorManager"):
		context["weather"] = WorldDirectorManager.get_weather_for_hub(current_hub)
	return context

func _find_method_option(options: Array, vehicle_id: String) -> Dictionary:
	for option_value in options:
		if typeof(option_value) != TYPE_DICTIONARY:
			continue
		var option: Dictionary = option_value
		if str(option.get("vehicle_id", "")) == vehicle_id:
			return option.duplicate(true)
	return {}

func _preview_vehicle_outcome(plan: Dictionary, outcome: Dictionary) -> Dictionary:
	var vehicle_id := str(plan.get("vehicle_id", ""))
	var current_state: Dictionary = world_travel_state.get("vehicle_states", {}).get(vehicle_id, {}).duplicate(true)
	if current_state.is_empty():
		return {"ok": true, "state": {}}
	var effective_stats := _vehicle_service.get_effective_stats(vehicle_id, current_state)

	var next_state := current_state.duplicate(true)
	if current_state.has("fuel"):
		var fuel_delta := float(outcome.get("fuel_delta", -float(plan.get("base_fuel_cost", 0.0))))
		var next_fuel := float(current_state.get("fuel", 0.0)) + fuel_delta
		if next_fuel < -0.001:
			return {"ok": false, "error": "insufficient_fuel_at_commit", "details": {"fuel_delta": fuel_delta, "available": float(current_state.get("fuel", 0.0))}}
		var fuel_capacity := float(effective_stats.get("fuel_capacity", _travel_contract.get("vehicles", {}).get(vehicle_id, {}).get("fuel_capacity", 100.0)))
		next_state["fuel"] = clampf(next_fuel, 0.0, fuel_capacity)
	if current_state.has("condition"):
		var condition_delta := float(outcome.get("vehicle_condition_delta", 0.0))
		var condition_capacity := float(effective_stats.get("condition_capacity", _travel_contract.get("vehicles", {}).get(vehicle_id, {}).get("condition_capacity", 100.0)))
		next_state["condition"] = clampf(float(current_state.get("condition", 100.0)) + condition_delta, 0.0, condition_capacity)
	if current_state.has("hard_damage"):
		next_state["hard_damage"] = clampi(int(current_state.get("hard_damage", 0)) + int(outcome.get("hard_damage_delta", 0)), 0, 3)
	return {"ok": true, "state": next_state}

func _apply_vehicle_preview(vehicle_id: String, state: Dictionary) -> void:
	if state.is_empty():
		return
	var vehicle_states: Dictionary = world_travel_state.get("vehicle_states", {})
	vehicle_states[vehicle_id] = state.duplicate(true)
	world_travel_state["vehicle_states"] = vehicle_states

func _resolve_destination_hub(destination_node: String, outcome: Dictionary) -> String:
	var explicit_hub := str(outcome.get("destination_hub", "")).strip_edges()
	if explicit_hub != "":
		return explicit_hub
	if not get_hub_data(destination_node).is_empty():
		return destination_node
	var nodes: Array = _resolver.map_data.get("nodes", _resolver.map_data.get("nos", []))
	for node_value in nodes:
		if typeof(node_value) != TYPE_DICTIONARY:
			continue
		var node: Dictionary = node_value
		if str(node.get("id", "")) != destination_node:
			continue
		var municipality := str(node.get("mun", node.get("municipio", "")))
		if municipality != "" and not get_hub_data(municipality).is_empty():
			return municipality
	return ""

func _validated_arrival_condition(candidate: String) -> String:
	var allowed: Array = _travel_contract.get("arrival_outcome", {}).get("arrival_condition_values", ["fresh", "steady", "tired", "shaken"])
	return candidate if allowed.has(candidate) else "steady"

func _apply_elapsed_time(elapsed_minutes: int, force_day: bool) -> void:
	var threshold_hours := int(DataRegistry.hubs_dense.get("travel_rules", {}).get("day_advance_threshold_hours", 8))
	if force_day or (threshold_hours > 0 and elapsed_minutes >= threshold_hours * 60):
		WorldState.advance_day()
	elif elapsed_minutes >= 180 and has_node("/root/WorldDirectorManager"):
		WorldDirectorManager.advance_time_block()

func _is_clean_outcome(outcome: Dictionary, success: bool) -> bool:
	if not success:
		return false
	if outcome.has("clean"):
		return bool(outcome.get("clean", false))
	return float(outcome.get("vehicle_condition_delta", 0.0)) >= 0.0 and int(outcome.get("hard_damage_delta", 0)) <= 0

func _update_route_progress(plan: Dictionary, outcome: Dictionary, success: bool, elapsed_minutes: int) -> Dictionary:
	var route_id := str(plan.get("route_id", ""))
	var route_mastery: Dictionary = world_travel_state.get("route_mastery", {})
	var entry: Dictionary = route_mastery.get(route_id, {
		"route_id": route_id,
		"level": "unknown",
		"completions": 0,
		"clean_completions": 0,
		"discoveries": []
	}).duplicate(true)
	var old_level := str(entry.get("level", "unknown"))
	var clean := _is_clean_outcome(outcome, success)
	if success:
		entry["completions"] = int(entry.get("completions", 0)) + 1
		if clean:
			entry["clean_completions"] = int(entry.get("clean_completions", 0)) + 1
		var discoveries: Array = entry.get("discoveries", []).duplicate()
		for discovery_value in outcome.get("discoveries", []):
			var discovery := str(discovery_value)
			if discovery != "" and not discoveries.has(discovery):
				discoveries.append(discovery)
		entry["discoveries"] = discoveries
		entry["level"] = "known"
		if int(entry.get("clean_completions", 0)) >= 2:
			entry["level"] = "familiar"
		if int(entry.get("clean_completions", 0)) >= 4 and bool(outcome.get("discoveries_complete", false)):
			entry["level"] = "mastered"
	entry["last_plan_id"] = str(plan.get("plan_id", ""))
	entry["last_success"] = success
	route_mastery[route_id] = entry
	world_travel_state["route_mastery"] = route_mastery

	var records: Dictionary = world_travel_state.get("route_records", {})
	var record: Dictionary = records.get(route_id, {"attempts": 0, "successes": 0, "best_time_minutes": 0}).duplicate(true)
	record["attempts"] = int(record.get("attempts", 0)) + 1
	if success:
		record["successes"] = int(record.get("successes", 0)) + 1
		var best := int(record.get("best_time_minutes", 0))
		if elapsed_minutes > 0 and (best <= 0 or elapsed_minutes < best):
			record["best_time_minutes"] = elapsed_minutes
	record["last_plan_id"] = str(plan.get("plan_id", ""))
	record["last_success"] = success
	records[route_id] = record
	world_travel_state["route_records"] = records
	return {"old_level": old_level, "new_level": str(entry.get("level", old_level)), "clean": clean, "entry": entry.duplicate(true)}

func _record_progression_travel_events(plan: Dictionary, outcome: Dictionary, travel_entry: Dictionary, mastery_change: Dictionary) -> void:
	if not has_node("/root/ProgressionOS"):
		return
	var plan_id := str(plan.get("plan_id", ""))
	var route_id := str(plan.get("route_id", ""))
	var success := bool(travel_entry.get("success", false))
	var base_context := {
		"domain": "exploration",
		"domain_xp": 0.0,
		"respect": 0,
		"route_id": route_id,
		"plan_id": plan_id,
		"vehicle_id": str(plan.get("vehicle_id", "")),
		"travel": travel_entry.duplicate(true)
	}
	ProgressionOS.record_event("travel_completed", "exploration", 0.0, base_context, "travel:%s:completed" % plan_id)
	if bool(mastery_change.get("clean", false)):
		ProgressionOS.record_event("travel_clean", "exploration", 0.0, base_context, "travel:%s:clean" % plan_id)
	if not success and str(travel_entry.get("failure_reason", "")) == "vehicle_breakdown":
		ProgressionOS.record_event("travel_breakdown", "exploration", 0.0, base_context, "travel:%s:breakdown" % plan_id)
	var old_level := str(mastery_change.get("old_level", "unknown"))
	var new_level := str(mastery_change.get("new_level", old_level))
	if success and old_level == "unknown" and new_level != "unknown":
		var discovery_context := base_context.duplicate(true)
		discovery_context["discovery_id"] = "route:%s" % route_id
		ProgressionOS.record_event("route_discovered", "exploration", 0.0, discovery_context, "route:%s:discovered" % route_id)
	if new_level != old_level:
		var mastery_context := base_context.duplicate(true)
		mastery_context["old_level"] = old_level
		mastery_context["new_level"] = new_level
		ProgressionOS.record_event("route_mastery_changed", "exploration", 0.0, mastery_context, "travel:%s:mastery:%s" % [plan_id, new_level])
	for discovery_value in outcome.get("discoveries", []):
		var discovery := str(discovery_value)
		if discovery == "":
			continue
		var poi_context := base_context.duplicate(true)
		poi_context["discovery_id"] = "travel_poi:%s:%s" % [route_id, discovery]
		poi_context["poi_id"] = discovery
		ProgressionOS.record_event("travel_poi_discovered", "exploration", 0.0, poi_context, "travel:%s:poi:%s" % [plan_id, discovery])

func _was_plan_committed(plan_id: String) -> bool:
	return world_travel_state.get("committed_plan_ids", []).has(plan_id)

func _mark_plan_committed(plan_id: String) -> void:
	var committed: Array = world_travel_state.get("committed_plan_ids", []).duplicate()
	if not committed.has(plan_id):
		committed.append(plan_id)
	while committed.size() > MAX_COMMITTED_PLAN_IDS:
		committed.pop_front()
	world_travel_state["committed_plan_ids"] = committed

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

func _travel_error(code: String, details: Dictionary = {}) -> Dictionary:
	return {"ok": false, "error": code, "details": details.duplicate(true)}
