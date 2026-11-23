extends SceneTree

const SimulationScript = preload("res://src/world/Rota101Simulation.gd")

var failures: Array[String] = []
var checks := 0

func _init() -> void:
	_run()

func _run() -> void:
	var base_plan := {
		"plan_id": "travel:test:itubera:valenca:kombi",
		"route_id": "itubera__valenca_test",
		"route_type": "terrestre",
		"route_class": "terrestrial_primary",
		"mode": "rota_101",
		"minigame": "rota_101",
		"distance_km": 1.0,
		"base_time_minutes": 5,
		"base_fuel_cost": 4.0,
		"vehicle_id": "kombi_terreiro",
		"vehicle_state_snapshot": {"fuel": 75.0, "condition": 100.0, "hard_damage": 0, "upgrades": []},
		"vehicle_stats_snapshot": {
			"fuel_capacity": 100.0,
			"condition_capacity": 100.0,
			"effects": {
				"road_grip_bonus": 0.0,
				"rough_road_condition_loss_multiplier": 1.0,
				"arrival_energy_loss_multiplier": 1.0
			}
		}
	}

	var clean_sim = SimulationScript.new()
	var clean_init: Dictionary = clean_sim.initialize(base_plan, {"hazard_generation": {"count": 0}})
	_check(bool(clean_init.get("ok", false)), "ROTA 101 initializes from terrestrial TravelPlan")
	_check(int(clean_init.get("hazard_count", -1)) == 0, "test override can disable procedural hazards")
	var clean_result := _drive_until_finished(clean_sim, {"throttle": 1.0, "steer": 0.0, "lane_assist": true}, 600)
	_check(bool(clean_result.get("finished", false)), "clean route reaches terminal state")
	var clean_outcome: Dictionary = clean_result.get("outcome", {})
	_check(bool(clean_outcome.get("success", false)), "clean route succeeds")
	_check(bool(clean_outcome.get("clean", false)), "safe straight drive is classified clean")
	_check(int(clean_outcome.get("collisions", -1)) == 0, "clean route has no collisions")
	_check(is_equal_approx(float(clean_outcome.get("fuel_delta", 0.0)), -4.0), "successful route consumes planned fuel exactly once")
	_check(is_equal_approx(float(clean_outcome.get("vehicle_condition_delta", 0.0)), 0.0), "clean route causes no condition loss")
	_check(str(clean_outcome.get("arrival_condition", "")) == "fresh", "clean undamaged arrival is fresh")
	_check(int(clean_outcome.get("elapsed_minutes", 0)) >= 5, "world elapsed time never beats canonical base time by reckless speed")
	_check(bool(clean_outcome.get("discoveries_complete", false)), "route without POIs can still complete discovery requirement")

	var hazard_plan: Dictionary = base_plan.duplicate(true)
	hazard_plan["plan_id"] = "travel:test:hazard"
	var hazard_sim = SimulationScript.new()
	var hazard_init: Dictionary = hazard_sim.initialize(hazard_plan, {
		"hazard_generation": {
			"fixed_hazards": [
				{"id": "road_hole_test", "progress": 0.20, "lane": 0.0, "poi": false, "condition_damage": 8.0, "speed_after_kmh": 35.0, "clean_penalty": 15.0}
			]
		}
	})
	_check(bool(hazard_init.get("ok", false)), "fixed hazard scenario initializes")
	var hazard_result := _drive_until_finished(hazard_sim, {"throttle": 1.0, "steer": 0.0}, 700)
	_check(bool(hazard_result.get("finished", false)), "hazard route reaches terminal state")
	var hazard_outcome: Dictionary = hazard_result.get("outcome", {})
	_check(bool(hazard_outcome.get("success", false)), "single pothole does not create campaign game over")
	_check(int(hazard_outcome.get("collisions", 0)) == 1, "lane collision is counted once")
	_check(float(hazard_outcome.get("vehicle_condition_delta", 0.0)) <= -8.0, "collision produces vehicle condition consequence")
	_check(not bool(hazard_outcome.get("clean", true)), "collision prevents clean-travel classification")
	_check(float(hazard_outcome.get("clean_score", 100.0)) < 100.0, "collision reduces clean-driving score")

	var poi_plan: Dictionary = base_plan.duplicate(true)
	poi_plan["plan_id"] = "travel:test:poi"
	poi_plan["distance_km"] = 0.25
	var poi_sim = SimulationScript.new()
	var poi_init: Dictionary = poi_sim.initialize(poi_plan, {
		"simulation": {
			"initial_speed_kmh": 20.0,
			"coast_loss_kmh_per_second": 0.0,
			"safe_poi_max_speed_kmh": 28.0
		},
		"hazard_generation": {
			"fixed_hazards": [
				{"id": "mirante_test", "progress": 0.20, "lane": 0.0, "poi": true, "condition_damage": 0.0, "speed_after_kmh": 0.0, "clean_penalty": 0.0}
			]
		}
	})
	_check(bool(poi_init.get("ok", false)), "safe POI scenario initializes")
	var poi_result := _drive_until_finished(poi_sim, {"throttle": 0.0, "steer": 0.0}, 900)
	var poi_outcome: Dictionary = poi_result.get("outcome", {})
	_check(bool(poi_outcome.get("success", false)), "POI route succeeds")
	_check(poi_outcome.get("discoveries", []).has("mirante_test"), "slow safe pull-off discovers POI")
	_check(bool(poi_outcome.get("discoveries_complete", false)), "all route POIs discovered marks discovery complete")
	_check(int(poi_outcome.get("collisions", -1)) == 0, "POI interaction is not a collision")

	var breakdown_plan: Dictionary = base_plan.duplicate(true)
	breakdown_plan["plan_id"] = "travel:test:breakdown"
	breakdown_plan["vehicle_state_snapshot"] = {"fuel": 75.0, "condition": 50.0, "hard_damage": 0, "upgrades": []}
	var breakdown_sim = SimulationScript.new()
	var breakdown_init: Dictionary = breakdown_sim.initialize(breakdown_plan, {
		"hazard_generation": {
			"fixed_hazards": [
				{"id": "branch_breakdown", "progress": 0.10, "lane": 0.0, "poi": false, "condition_damage": 60.0, "speed_after_kmh": 0.0, "clean_penalty": 40.0}
			]
		}
	})
	_check(bool(breakdown_init.get("ok", false)), "breakdown scenario initializes")
	var breakdown_result := _drive_until_finished(breakdown_sim, {"throttle": 1.0, "steer": 0.0}, 400)
	_check(bool(breakdown_result.get("finished", false)), "breakdown ends route deterministically")
	var breakdown_outcome: Dictionary = breakdown_result.get("outcome", {})
	_check(not bool(breakdown_outcome.get("success", true)), "breakdown returns failed TravelOutcome")
	_check(str(breakdown_outcome.get("failure_reason", "")) == "vehicle_breakdown", "breakdown reason is explicit")
	_check(str(breakdown_outcome.get("arrival_condition", "")) == "shaken", "breakdown arrival state is shaken")
	_check(int(breakdown_outcome.get("hard_damage_delta", 0)) == 1, "breakdown creates hard-damage consequence")
	_check(float(breakdown_outcome.get("route_progress", 1.0)) < 1.0, "breakdown outcome preserves partial route progress")

	var invalid_sim = SimulationScript.new()
	var maritime_plan: Dictionary = base_plan.duplicate(true)
	maritime_plan["route_type"] = "maritima"
	var invalid: Dictionary = invalid_sim.initialize(maritime_plan)
	_check(not bool(invalid.get("ok", true)), "ROTA 101 rejects maritime TravelPlan fail-closed")

	var safety_sim = SimulationScript.new()
	var safety_init: Dictionary = safety_sim.initialize(base_plan)
	_check(bool(safety_init.get("ok", false)), "default deterministic hazard generation initializes")
	var forbidden := ["pedestrian_target", "child_target", "cyclist_target"]
	var unsafe_found := false
	for hazard_value in safety_sim.hazards:
		if typeof(hazard_value) == TYPE_DICTIONARY and forbidden.has(str(hazard_value.get("id", "")).get_slice("_", 0)):
			unsafe_found = true
	_check(not unsafe_found, "generated hazards contain no vulnerable-road-user target mechanics")

	print("ROTA_101_SIMULATION_SMOKE checks=%d failures=%d" % [checks, failures.size()])
	for failure in failures:
		push_error(failure)
	quit(0 if failures.is_empty() else 1)

func _drive_until_finished(simulation, input: Dictionary, max_steps: int) -> Dictionary:
	var result: Dictionary = {}
	for _index in range(max_steps):
		result = simulation.step(input, 0.1)
		if bool(result.get("finished", false)):
			return result
	return result

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
