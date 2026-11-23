extends RefCounted
class_name Rota101Simulation

const DEFAULT_CONFIG_PATH := "res://data/world/rota_101_v1.json"

var plan: Dictionary = {}
var config: Dictionary = {}
var state: Dictionary = {}
var hazards: Array = []
var terminal_outcome: Dictionary = {}
var _rng := RandomNumberGenerator.new()

func initialize(plan_override: Dictionary, config_override: Dictionary = {}) -> Dictionary:
	plan = plan_override.duplicate(true)
	var base_config := _load_json(DEFAULT_CONFIG_PATH)
	config = _deep_merge(base_config, config_override)
	terminal_outcome = {}
	hazards = []

	var errors: Array[String] = []
	if plan.is_empty():
		errors.append("travel_plan_missing")
	if str(plan.get("route_type", "")) != "terrestre":
		errors.append("rota_101_requires_terrestrial_plan")
	var mode := str(plan.get("mode", ""))
	var minigame := str(plan.get("minigame", ""))
	if mode != "rota_101" and minigame != "rota_101":
		errors.append("travel_plan_does_not_request_rota_101")
	if str(plan.get("plan_id", "")) == "":
		errors.append("travel_plan_id_missing")
	if config.is_empty() or config.get("contract_id") != "cria_rota_101_v1":
		errors.append("rota_101_config_missing_or_invalid")
	if not errors.is_empty():
		return {"ok": false, "errors": errors}

	var simulation: Dictionary = config.get("simulation", {})
	var vehicle_state: Dictionary = plan.get("vehicle_state_snapshot", {}).duplicate(true)
	var condition_capacity := float(plan.get("vehicle_stats_snapshot", {}).get("condition_capacity", 100.0))
	var initial_condition := float(vehicle_state.get("condition", condition_capacity))
	state = {
		"active": true,
		"finished": false,
		"success": false,
		"progress": 0.0,
		"distance_covered_km": 0.0,
		"elapsed_seconds": 0.0,
		"speed_kmh": clampf(float(simulation.get("initial_speed_kmh", 35.0)), 0.0, float(simulation.get("max_speed_kmh", 110.0))),
		"lateral": 0.0,
		"offroad_seconds": 0.0,
		"condition_loss": 0.0,
		"initial_condition": initial_condition,
		"collisions": 0,
		"clean_score": float(config.get("outcome", {}).get("base_clean_score", 100.0)),
		"discoveries": [],
		"poi_total": 0,
		"hazards_handled": 0,
		"breakdown": false,
		"horn_uses": 0
	}
	_rng.seed = _stable_seed(str(plan.get("plan_id", "")))
	_generate_hazards()
	state["poi_total"] = _count_pois()
	return {"ok": true, "seed": int(_rng.seed), "hazard_count": hazards.size(), "snapshot": get_snapshot()}

func step(input: Dictionary, delta: float) -> Dictionary:
	if state.is_empty() or not bool(state.get("active", false)):
		return {"ok": false, "error": "simulation_not_active", "snapshot": get_snapshot()}
	if bool(state.get("finished", false)):
		return {"ok": true, "finished": true, "outcome": terminal_outcome.duplicate(true), "snapshot": get_snapshot()}
	if delta <= 0.0:
		return {"ok": true, "finished": false, "snapshot": get_snapshot()}

	var simulation: Dictionary = config.get("simulation", {})
	var previous_progress := float(state.get("progress", 0.0))
	var speed := float(state.get("speed_kmh", 0.0))
	var throttle := clampf(float(input.get("throttle", 0.0)), 0.0, 1.0)
	var brake := clampf(float(input.get("brake", 0.0)), 0.0, 1.0)
	if bool(input.get("auto_accelerate", false)) and brake <= 0.0:
		throttle = maxf(throttle, 0.72)

	if brake > 0.0:
		speed -= float(simulation.get("brake_kmh_per_second", 45.0)) * brake * delta
	elif throttle > 0.0:
		speed += float(simulation.get("acceleration_kmh_per_second", 28.0)) * throttle * delta
	else:
		speed -= float(simulation.get("coast_loss_kmh_per_second", 7.0)) * delta
	speed = clampf(speed, 0.0, float(simulation.get("max_speed_kmh", 110.0)))

	var steer := clampf(float(input.get("steer", 0.0)), -1.0, 1.0)
	var effects: Dictionary = plan.get("vehicle_stats_snapshot", {}).get("effects", {})
	var grip_bonus := maxf(0.0, float(effects.get("road_grip_bonus", 0.0)))
	var steer_rate := float(simulation.get("steer_units_per_second", 1.35)) * (1.0 + grip_bonus)
	var lateral := float(state.get("lateral", 0.0)) + steer * steer_rate * delta
	if absf(steer) < 0.05 and bool(input.get("lane_assist", false)):
		lateral = move_toward(lateral, 0.0, steer_rate * 0.32 * delta)
	lateral = clampf(lateral, -1.2, 1.2)

	var offroad_threshold := float(simulation.get("offroad_threshold", 0.92))
	var hard_edge_threshold := float(simulation.get("hard_edge_threshold", 1.08))
	if absf(lateral) > offroad_threshold:
		state["offroad_seconds"] = float(state.get("offroad_seconds", 0.0)) + delta
		speed *= pow(float(simulation.get("offroad_speed_multiplier", 0.72)), delta)
		var suspension_multiplier := float(effects.get("rough_road_condition_loss_multiplier", 1.0))
		var condition_tick := float(simulation.get("offroad_condition_loss_per_second", 0.8)) * suspension_multiplier * delta
		if absf(lateral) > hard_edge_threshold:
			condition_tick *= 1.75
		state["condition_loss"] = float(state.get("condition_loss", 0.0)) + condition_tick
		state["clean_score"] = maxf(0.0, float(state.get("clean_score", 100.0)) - float(config.get("outcome", {}).get("offroad_clean_penalty_per_second", 2.0)) * delta)

	state["speed_kmh"] = speed
	state["lateral"] = lateral
	state["elapsed_seconds"] = float(state.get("elapsed_seconds", 0.0)) + delta
	if bool(input.get("horn", false)):
		state["horn_uses"] = int(state.get("horn_uses", 0)) + 1

	_advance_progress(delta)
	_process_crossed_hazards(previous_progress, float(state.get("progress", 0.0)))
	_check_terminal_state()

	return {
		"ok": true,
		"finished": bool(state.get("finished", false)),
		"outcome": terminal_outcome.duplicate(true),
		"snapshot": get_snapshot()
	}

func get_snapshot() -> Dictionary:
	return {
		"state": state.duplicate(true),
		"hazards": hazards.duplicate(true),
		"plan_id": str(plan.get("plan_id", "")),
		"route_id": str(plan.get("route_id", ""))
	}

func get_outcome() -> Dictionary:
	return terminal_outcome.duplicate(true)

func _advance_progress(delta: float) -> void:
	var simulation: Dictionary = config.get("simulation", {})
	var speed := float(state.get("speed_kmh", 0.0))
	var distance_km := maxf(0.0, float(plan.get("distance_km", 0.0)))
	if distance_km <= 0.0:
		distance_km = maxf(0.0, float(plan.get("route_distance_km", 0.0)))
	var time_scale := maxf(1.0, float(simulation.get("world_time_scale", 45.0)))
	if distance_km > 0.0:
		var delta_km := speed * (delta * time_scale / 3600.0)
		state["distance_covered_km"] = float(state.get("distance_covered_km", 0.0)) + delta_km
		state["progress"] = clampf(float(state.get("distance_covered_km", 0.0)) / distance_km, 0.0, 1.0)
		return
	var fallback_duration := maxf(1.0, float(simulation.get("fallback_gameplay_duration_seconds", 60.0)))
	var nominal_speed := maxf(1.0, float(simulation.get("nominal_cruise_kmh", 85.0)))
	var speed_factor := clampf(speed / nominal_speed, 0.0, 1.25)
	state["progress"] = clampf(float(state.get("progress", 0.0)) + (delta / fallback_duration) * speed_factor, 0.0, 1.0)

func _process_crossed_hazards(previous_progress: float, current_progress: float) -> void:
	if current_progress <= previous_progress:
		return
	var collision_window := float(config.get("simulation", {}).get("collision_progress_window", 0.018))
	for index in range(hazards.size()):
		var hazard: Dictionary = hazards[index]
		if bool(hazard.get("handled", false)):
			continue
		var hazard_progress := float(hazard.get("progress", 0.0))
		if hazard_progress > current_progress + collision_window:
			continue
		if hazard_progress + collision_window < previous_progress:
			hazard["handled"] = true
			hazards[index] = hazard
			continue
		var lane_distance := absf(float(state.get("lateral", 0.0)) - float(hazard.get("lane", 0.0)))
		if bool(hazard.get("poi", false)):
			if lane_distance <= 0.34 and float(state.get("speed_kmh", 0.0)) <= float(config.get("simulation", {}).get("safe_poi_max_speed_kmh", 28.0)):
				var discoveries: Array = state.get("discoveries", []).duplicate()
				var discovery_id := str(hazard.get("id", "poi_%d" % index))
				if not discoveries.has(discovery_id):
					discoveries.append(discovery_id)
				state["discoveries"] = discoveries
		else:
			if lane_distance <= 0.30:
				_apply_collision(hazard)
		hazard["handled"] = true
		hazards[index] = hazard
		state["hazards_handled"] = int(state.get("hazards_handled", 0)) + 1

func _apply_collision(hazard: Dictionary) -> void:
	var effects: Dictionary = plan.get("vehicle_stats_snapshot", {}).get("effects", {})
	var suspension_multiplier := float(effects.get("rough_road_condition_loss_multiplier", 1.0))
	var damage := maxf(0.0, float(hazard.get("condition_damage", 0.0))) * suspension_multiplier
	state["condition_loss"] = float(state.get("condition_loss", 0.0)) + damage
	state["collisions"] = int(state.get("collisions", 0)) + 1
	state["clean_score"] = maxf(0.0, float(state.get("clean_score", 100.0)) - maxf(0.0, float(hazard.get("clean_penalty", 0.0))))
	var speed_after := maxf(0.0, float(hazard.get("speed_after_kmh", 0.0)))
	if speed_after > 0.0:
		state["speed_kmh"] = minf(float(state.get("speed_kmh", 0.0)), speed_after)

func _check_terminal_state() -> void:
	var available_condition := maxf(0.0, float(state.get("initial_condition", 100.0)))
	var breakdown_loss := minf(available_condition, float(config.get("simulation", {}).get("breakdown_condition_loss", 100.0)))
	if float(state.get("condition_loss", 0.0)) >= breakdown_loss and breakdown_loss > 0.0:
		state["breakdown"] = true
		_finish(false, "vehicle_breakdown")
		return
	if float(state.get("progress", 0.0)) >= 1.0:
		_finish(true, "")

func _finish(success: bool, failure_reason: String) -> void:
	if bool(state.get("finished", false)):
		return
	state["finished"] = true
	state["active"] = false
	state["success"] = success
	terminal_outcome = _build_outcome(success, failure_reason)

func _build_outcome(success: bool, failure_reason: String) -> Dictionary:
	var outcome_config: Dictionary = config.get("outcome", {})
	var progress := clampf(float(state.get("progress", 0.0)), 0.0, 1.0)
	var base_fuel_cost := maxf(0.0, float(plan.get("base_fuel_cost", 0.0)))
	var fuel_used := base_fuel_cost * progress
	if success:
		fuel_used = base_fuel_cost
	var condition_loss := maxf(0.0, float(state.get("condition_loss", 0.0)))
	var hard_damage_delta := 1 if condition_loss >= float(outcome_config.get("hard_damage_condition_loss_threshold", 35.0)) or bool(state.get("breakdown", false)) else 0
	var clean := success \
		and int(state.get("collisions", 0)) == 0 \
		and float(state.get("offroad_seconds", 0.0)) <= float(config.get("simulation", {}).get("clean_offroad_seconds_max", 1.0)) \
		and float(state.get("clean_score", 0.0)) >= float(outcome_config.get("minimum_clean_score", 75.0))
	var arrival := _arrival_condition(success, condition_loss, clean)
	var effects: Dictionary = plan.get("vehicle_stats_snapshot", {}).get("effects", {})
	var energy_multiplier := clampf(float(effects.get("arrival_energy_loss_multiplier", 1.0)), 0.1, 2.0)
	var base_energy := float(config.get("simulation", {}).get("base_energy_loss_success" if success else "base_energy_loss_failure", 3.0 if success else 5.0))
	var elapsed_minutes := _world_elapsed_minutes(progress)
	var discoveries: Array = state.get("discoveries", []).duplicate()
	var poi_total := int(state.get("poi_total", 0))
	return {
		"success": success,
		"failure_reason": failure_reason,
		"elapsed_minutes": elapsed_minutes,
		"fuel_delta": -fuel_used,
		"vehicle_condition_delta": -condition_loss,
		"hard_damage_delta": hard_damage_delta,
		"energy_delta": -base_energy * energy_multiplier,
		"arrival_condition": arrival,
		"clean": clean,
		"clean_score": clampf(float(state.get("clean_score", 0.0)), 0.0, 100.0),
		"collisions": int(state.get("collisions", 0)),
		"offroad_seconds": float(state.get("offroad_seconds", 0.0)),
		"discoveries": discoveries,
		"discoveries_complete": poi_total == 0 or discoveries.size() >= poi_total,
		"route_progress": progress,
		"driving_seconds": float(state.get("elapsed_seconds", 0.0))
	}

func _world_elapsed_minutes(progress: float) -> int:
	var base_minutes := maxi(0, int(plan.get("base_time_minutes", 0)))
	if base_minutes <= 0:
		return 0
	var simulation: Dictionary = config.get("simulation", {})
	var distance_km := maxf(0.0, float(plan.get("distance_km", plan.get("route_distance_km", 0.0))))
	var ideal_game_seconds := 0.0
	if distance_km > 0.0:
		var nominal := maxf(1.0, float(simulation.get("nominal_cruise_kmh", 85.0)))
		var time_scale := maxf(1.0, float(simulation.get("world_time_scale", 45.0)))
		ideal_game_seconds = (distance_km / nominal * 3600.0) / time_scale
	else:
		ideal_game_seconds = float(simulation.get("fallback_gameplay_duration_seconds", 60.0))
	var elapsed := float(state.get("elapsed_seconds", 0.0))
	var delay_seconds := maxf(0.0, elapsed - ideal_game_seconds * progress)
	var delay_world_minutes := int(ceil(delay_seconds * float(simulation.get("world_time_scale", 45.0)) / 60.0))
	return maxi(0, int(ceil(float(base_minutes) * progress)) + delay_world_minutes)

func _arrival_condition(success: bool, condition_loss: float, clean: bool) -> String:
	if not success or bool(state.get("breakdown", false)):
		return "shaken"
	var outcome_config: Dictionary = config.get("outcome", {})
	if clean and condition_loss <= float(outcome_config.get("fresh_max_condition_loss", 2.0)):
		return "fresh"
	if condition_loss <= float(outcome_config.get("steady_max_condition_loss", 10.0)):
		return "steady"
	if condition_loss <= float(outcome_config.get("tired_max_condition_loss", 25.0)):
		return "tired"
	return "shaken"

func _generate_hazards() -> void:
	var generation: Dictionary = config.get("hazard_generation", {})
	var fixed: Array = generation.get("fixed_hazards", [])
	if not fixed.is_empty():
		for hazard_value in fixed:
			if typeof(hazard_value) == TYPE_DICTIONARY:
				var hazard: Dictionary = hazard_value.duplicate(true)
				hazard["handled"] = false
				hazards.append(hazard)
		hazards.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.get("progress", 0.0)) < float(b.get("progress", 0.0)))
		return

	var target_count := maxi(0, int(generation.get("count", 8)))
	var types: Array = generation.get("types", [])
	var lanes: Array = generation.get("lanes", [-0.62, 0.0, 0.62])
	if target_count == 0 or types.is_empty() or lanes.is_empty():
		return
	var min_progress := clampf(float(generation.get("min_progress", 0.10)), 0.0, 1.0)
	var max_progress := clampf(float(generation.get("max_progress", 0.92)), min_progress, 1.0)
	var min_spacing := maxf(0.0, float(generation.get("min_spacing", 0.075)))
	var attempts := 0
	while hazards.size() < target_count and attempts < target_count * 40:
		attempts += 1
		var progress := _rng.randf_range(min_progress, max_progress)
		if not _progress_has_spacing(progress, min_spacing):
			continue
		var type_def := _weighted_hazard_type(types)
		if type_def.is_empty():
			break
		var lane := float(lanes[_rng.randi_range(0, lanes.size() - 1)])
		var hazard := type_def.duplicate(true)
		hazard["progress"] = progress
		hazard["lane"] = lane
		hazard["handled"] = false
		hazard["id"] = "%s_%02d" % [str(type_def.get("id", "hazard")), hazards.size() + 1]
		hazards.append(hazard)
	hazards.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.get("progress", 0.0)) < float(b.get("progress", 0.0)))

func _weighted_hazard_type(types: Array) -> Dictionary:
	var total := 0.0
	for type_value in types:
		if typeof(type_value) == TYPE_DICTIONARY:
			total += maxf(0.0, float(type_value.get("weight", 1.0)))
	if total <= 0.0:
		return {}
	var roll := _rng.randf_range(0.0, total)
	var cursor := 0.0
	for type_value in types:
		if typeof(type_value) != TYPE_DICTIONARY:
			continue
		var definition: Dictionary = type_value
		cursor += maxf(0.0, float(definition.get("weight", 1.0)))
		if roll <= cursor:
			return definition.duplicate(true)
	return types.back().duplicate(true) if typeof(types.back()) == TYPE_DICTIONARY else {}

func _progress_has_spacing(candidate: float, min_spacing: float) -> bool:
	for hazard_value in hazards:
		if typeof(hazard_value) == TYPE_DICTIONARY and absf(float(hazard_value.get("progress", 0.0)) - candidate) < min_spacing:
			return false
	return true

func _count_pois() -> int:
	var count := 0
	for hazard_value in hazards:
		if typeof(hazard_value) == TYPE_DICTIONARY and bool(hazard_value.get("poi", false)):
			count += 1
	return count

func _stable_seed(text: String) -> int:
	var value: int = 2166136261
	for index in range(text.length()):
		value = int((value ^ text.unicode_at(index)) * 16777619) % 2147483647
	if value <= 0:
		value = 1
	return value

func _deep_merge(base: Dictionary, override: Dictionary) -> Dictionary:
	var output := base.duplicate(true)
	for key_value in override.keys():
		var key := str(key_value)
		var override_value: Variant = override[key_value]
		if output.has(key) and typeof(output[key]) == TYPE_DICTIONARY and typeof(override_value) == TYPE_DICTIONARY:
			output[key] = _deep_merge(output[key], override_value)
		else:
			output[key] = override_value.duplicate(true) if typeof(override_value) in [TYPE_DICTIONARY, TYPE_ARRAY] else override_value
	return output

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}
