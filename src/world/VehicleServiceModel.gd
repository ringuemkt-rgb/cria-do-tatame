extends RefCounted
class_name VehicleServiceModel

var vehicles: Dictionary = {}
var upgrade_policy: Dictionary = {}
var service_rules: Dictionary = {}

func initialize(vehicle_catalog: Dictionary, kombi_upgrade_policy: Dictionary, economy_data: Dictionary) -> Dictionary:
	vehicles = vehicle_catalog.duplicate(true)
	upgrade_policy = kombi_upgrade_policy.duplicate(true)
	service_rules = economy_data.get("vehicle_service", {}).duplicate(true)
	var errors: Array[String] = []
	if vehicles.is_empty():
		errors.append("vehicle_catalog_missing")
	if service_rules.is_empty():
		errors.append("vehicle_service_rules_missing")
	return {"ok": errors.is_empty(), "errors": errors}

func get_effective_stats(vehicle_id: String, state: Dictionary) -> Dictionary:
	var vehicle: Dictionary = vehicles.get(vehicle_id, {})
	if vehicle.is_empty():
		return {}
	var effects := {
		"fuel_capacity_bonus": 0.0,
		"cargo_capacity_bonus": 0.0,
		"road_grip_bonus": 0.0,
		"night_visibility_bonus": 0.0,
		"rough_road_condition_loss_multiplier": 1.0,
		"arrival_energy_loss_multiplier": 1.0,
		"roadside_repair_charges": 0,
		"cosmetic_only_upgrades": []
	}
	for upgrade_value in state.get("upgrades", []):
		var upgrade_id := str(upgrade_value)
		var definition: Dictionary = service_rules.get("upgrade_catalog", {}).get(upgrade_id, {})
		var upgrade_effects: Dictionary = definition.get("effects", {})
		for key_value in upgrade_effects.keys():
			var key := str(key_value)
			var value: Variant = upgrade_effects[key_value]
			match key:
				"fuel_capacity_bonus", "cargo_capacity_bonus", "road_grip_bonus", "night_visibility_bonus":
					effects[key] = float(effects.get(key, 0.0)) + float(value)
				"rough_road_condition_loss_multiplier", "arrival_energy_loss_multiplier":
					effects[key] = float(effects.get(key, 1.0)) * float(value)
				"roadside_repair_charges":
					effects[key] = int(effects.get(key, 0)) + int(value)
				"cosmetic_only":
					if bool(value):
						var cosmetic: Array = effects.get("cosmetic_only_upgrades", [])
						cosmetic.append(upgrade_id)
						effects["cosmetic_only_upgrades"] = cosmetic

	return {
		"vehicle_id": vehicle_id,
		"fuel_capacity": maxf(0.0, float(vehicle.get("fuel_capacity", 0.0)) + float(effects.get("fuel_capacity_bonus", 0.0))),
		"condition_capacity": maxf(0.0, float(vehicle.get("condition_capacity", 0.0))),
		"cargo_capacity": maxf(0.0, float(vehicle.get("cargo_capacity", 0.0)) + float(effects.get("cargo_capacity_bonus", 0.0))),
		"crew_capacity": maxi(0, int(vehicle.get("crew_capacity", 0))),
		"effects": effects
	}

func quote(vehicle_id: String, state: Dictionary, request: Dictionary) -> Dictionary:
	if vehicles.get(vehicle_id, {}).is_empty():
		return _error("vehicle_unknown")
	if state.is_empty():
		return _error("vehicle_has_no_persistent_state")
	if service_rules.is_empty():
		return _error("vehicle_service_rules_missing")

	var projected := state.duplicate(true)
	var line_items: Array = []
	var total_cost := 0
	var requested_upgrades: Array = request.get("install_upgrades", [])
	var installed: Array = projected.get("upgrades", []).duplicate()
	var allowed := _allowed_upgrades(vehicle_id)
	for upgrade_value in requested_upgrades:
		var upgrade_id := str(upgrade_value)
		if upgrade_id == "":
			continue
		if not allowed.has(upgrade_id):
			return _error("upgrade_not_allowed", {"upgrade_id": upgrade_id})
		var definition: Dictionary = service_rules.get("upgrade_catalog", {}).get(upgrade_id, {})
		if definition.is_empty():
			return _error("upgrade_missing_from_economy", {"upgrade_id": upgrade_id})
		if installed.has(upgrade_id):
			continue
		var upgrade_cost := maxi(0, int(definition.get("cost", 0)))
		installed.append(upgrade_id)
		total_cost += upgrade_cost
		line_items.append({"type": "upgrade", "upgrade_id": upgrade_id, "cost": upgrade_cost})
	projected["upgrades"] = installed

	var stats := get_effective_stats(vehicle_id, projected)
	if request.has("refuel_to"):
		if not projected.has("fuel"):
			return _error("vehicle_does_not_track_fuel")
		var current_fuel := float(projected.get("fuel", 0.0))
		var target_fuel := clampf(float(request.get("refuel_to", current_fuel)), 0.0, float(stats.get("fuel_capacity", current_fuel)))
		if target_fuel + 0.001 < current_fuel:
			return _error("refuel_target_below_current")
		var fuel_units := maxf(0.0, target_fuel - current_fuel)
		var fuel_cost := _block_cost(
			fuel_units,
			float(service_rules.get("refuel_block_units", 10.0)),
			int(service_rules.get("refuel_block_cost", 0))
		)
		projected["fuel"] = target_fuel
		if fuel_units > 0.0:
			total_cost += fuel_cost
			line_items.append({"type": "refuel", "units": fuel_units, "cost": fuel_cost})

	if request.has("repair_condition_to"):
		if not projected.has("condition"):
			return _error("vehicle_does_not_track_condition")
		var current_condition := float(projected.get("condition", 0.0))
		var target_condition := clampf(float(request.get("repair_condition_to", current_condition)), 0.0, float(stats.get("condition_capacity", current_condition)))
		if target_condition + 0.001 < current_condition:
			return _error("repair_target_below_current_condition")
		var condition_units := maxf(0.0, target_condition - current_condition)
		var condition_cost := _block_cost(
			condition_units,
			float(service_rules.get("condition_repair_block_units", 10.0)),
			int(service_rules.get("condition_repair_block_cost", 0))
		)
		projected["condition"] = target_condition
		if condition_units > 0.0:
			total_cost += condition_cost
			line_items.append({"type": "repair_condition", "units": condition_units, "cost": condition_cost})

	if request.has("repair_hard_damage_to"):
		if not projected.has("hard_damage"):
			return _error("vehicle_does_not_track_hard_damage")
		var current_damage := int(projected.get("hard_damage", 0))
		var target_damage := clampi(int(request.get("repair_hard_damage_to", current_damage)), 0, 3)
		if target_damage > current_damage:
			return _error("repair_target_increases_hard_damage")
		var repaired_levels := current_damage - target_damage
		var hard_cost := repaired_levels * maxi(0, int(service_rules.get("hard_damage_repair_cost_per_level", 0)))
		projected["hard_damage"] = target_damage
		if repaired_levels > 0:
			total_cost += hard_cost
			line_items.append({"type": "repair_hard_damage", "levels": repaired_levels, "cost": hard_cost})

	return {
		"ok": true,
		"vehicle_id": vehicle_id,
		"total_cost": total_cost,
		"line_items": line_items,
		"projected_state": projected,
		"effective_stats": get_effective_stats(vehicle_id, projected),
		"no_op": line_items.is_empty()
	}

func _allowed_upgrades(vehicle_id: String) -> Array:
	var vehicle: Dictionary = vehicles.get(vehicle_id, {})
	if vehicle.has("allowed_upgrades"):
		return vehicle.get("allowed_upgrades", []).duplicate()
	if vehicle_id == "kombi_terreiro":
		return upgrade_policy.get("allowed", []).duplicate()
	return []

func _block_cost(units: float, block_units: float, block_cost: int) -> int:
	if units <= 0.0 or block_units <= 0.0 or block_cost <= 0:
		return 0
	return int(ceil(units / block_units)) * block_cost

func _error(code: String, details: Dictionary = {}) -> Dictionary:
	return {"ok": false, "error": code, "details": details.duplicate(true)}
