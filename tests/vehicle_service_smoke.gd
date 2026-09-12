extends SceneTree

var failures: Array[String] = []
var checks := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var map_manager = root.get_node("WorldMapManager")
	var world_state = root.get_node("WorldState")

	map_manager.reset()
	world_state.money = 200
	world_state.energy = 100.0
	world_state.act = 3
	world_state.current_hub = "itubera"
	world_state.story_flags = {}
	world_state.completed_missions = []
	world_state._sync_aliases()

	var initial: Dictionary = map_manager.get_vehicle_state("kombi_terreiro")
	_check(float(initial.get("fuel", -1.0)) == 75.0, "Kombi starts with canonical default fuel")
	_check(float(initial.get("condition", -1.0)) == 100.0, "Kombi starts in full condition")
	_check(int(initial.get("hard_damage", -1)) == 0, "Kombi starts without hard damage")
	_check(initial.get("upgrades", []).is_empty(), "Kombi starts without upgrades")

	var state_before_quote: Dictionary = initial.duplicate(true)
	var money_before_quote := int(world_state.money)
	var quote: Dictionary = map_manager.quote_vehicle_service("kombi_terreiro", {
		"install_upgrades": ["fuel_tank"],
		"refuel_to": 125.0
	})
	_check(bool(quote.get("ok", false)), "service quote succeeds")
	_check(int(quote.get("total_cost", -1)) == 50, "fuel tank plus 50 fuel units has deterministic economy cost")
	_check(float(quote.get("effective_stats", {}).get("fuel_capacity", 0.0)) == 125.0, "fuel tank raises effective capacity to 125")
	_check(float(quote.get("projected_state", {}).get("fuel", 0.0)) == 125.0, "quote can fill newly expanded tank")
	_check(map_manager.get_vehicle_state("kombi_terreiro") == state_before_quote, "quote is read-only")
	_check(int(world_state.money) == money_before_quote, "quote does not spend money")

	var serviced: Dictionary = map_manager.service_vehicle("kombi_terreiro", {
		"install_upgrades": ["fuel_tank"],
		"refuel_to": 125.0
	})
	_check(bool(serviced.get("ok", false)), "vehicle service commits atomically")
	_check(int(serviced.get("spent", -1)) == 50, "service spends quoted amount")
	_check(int(world_state.money) == 150, "service deducts money once")
	var upgraded: Dictionary = map_manager.get_vehicle_state("kombi_terreiro")
	_check(upgraded.get("upgrades", []).has("fuel_tank"), "fuel tank upgrade persists")
	_check(float(upgraded.get("fuel", 0.0)) == 125.0, "refuel persists")
	_check(float(map_manager.get_vehicle_effective_stats("kombi_terreiro").get("fuel_capacity", 0.0)) == 125.0, "effective stats expose installed upgrade")

	var noop: Dictionary = map_manager.service_vehicle("kombi_terreiro", {
		"install_upgrades": ["fuel_tank"],
		"refuel_to": 125.0
	})
	_check(bool(noop.get("ok", false)), "repeating completed service is safe")
	_check(int(noop.get("spent", -1)) == 0, "repeated completed service is a zero-cost no-op")
	_check(int(world_state.money) == 150, "no-op service does not spend again")

	var forbidden: Dictionary = map_manager.quote_vehicle_service("kombi_terreiro", {"install_upgrades": ["weapons"]})
	_check(not bool(forbidden.get("ok", true)), "weaponized upgrade is rejected")
	_check(str(forbidden.get("error", "")) == "upgrade_not_allowed", "forbidden upgrade fails with deterministic reason")

	var plan_result: Dictionary = map_manager.prepare_travel(
		"pancada_grande",
		"kombi_terreiro",
		{"act": 3, "flags": {}, "route_unlocks": [], "weather": "chuva"}
	)
	_check(bool(plan_result.get("ok", false)), "damaging travel scenario prepares")
	var plan: Dictionary = plan_result.get("plan", {})
	_check(float(plan.get("vehicle_stats_snapshot", {}).get("fuel_capacity", 0.0)) == 125.0, "TravelPlan snapshots upgraded vehicle stats")
	_check(float(plan.get("vehicle_state_snapshot", {}).get("fuel", 0.0)) == 125.0, "TravelPlan snapshots current fuel")

	var blocked_service: Dictionary = map_manager.quote_vehicle_service("kombi_terreiro", {"install_upgrades": ["tires"]})
	_check(not bool(blocked_service.get("ok", true)), "garage service is blocked while a TravelPlan is pending")
	_check(str(blocked_service.get("error", "")) == "vehicle_service_blocked_during_pending_travel", "pending-travel service has deterministic error")

	var failed_trip: Dictionary = map_manager.commit_travel_outcome(str(plan.get("plan_id", "")), {
		"success": false,
		"failure_reason": "vehicle_breakdown",
		"elapsed_minutes": 20,
		"money_delta": 0,
		"fuel_delta": 0.0,
		"vehicle_condition_delta": -20.0,
		"hard_damage_delta": 1,
		"energy_delta": 0.0,
		"arrival_condition": "shaken"
	})
	_check(bool(failed_trip.get("ok", false)), "damage outcome commits")
	var damaged: Dictionary = map_manager.get_vehicle_state("kombi_terreiro")
	_check(float(damaged.get("condition", 0.0)) == 80.0, "trip damage lowers condition")
	_check(int(damaged.get("hard_damage", 0)) == 1, "trip damage adds hard-damage level")

	var repair_quote: Dictionary = map_manager.quote_vehicle_service("kombi_terreiro", {
		"repair_condition_to": 100.0,
		"repair_hard_damage_to": 0
	})
	_check(bool(repair_quote.get("ok", false)), "repair quote succeeds")
	_check(int(repair_quote.get("total_cost", -1)) == 30, "condition and hard-damage repair cost is deterministic")
	var repaired: Dictionary = map_manager.service_vehicle("kombi_terreiro", {
		"repair_condition_to": 100.0,
		"repair_hard_damage_to": 0
	})
	_check(bool(repaired.get("ok", false)), "repair commits")
	_check(float(map_manager.get_vehicle_state("kombi_terreiro").get("condition", 0.0)) == 100.0, "repair restores condition")
	_check(int(map_manager.get_vehicle_state("kombi_terreiro").get("hard_damage", -1)) == 0, "repair clears hard damage")
	_check(int(world_state.money) == 120, "repair deducts only quoted cost")

	var bus_quote: Dictionary = map_manager.quote_vehicle_service("onibus_regional", {"refuel_to": 10})
	_check(not bool(bus_quote.get("ok", true)), "non-owned bus cannot be serviced as player vehicle")
	_check(str(bus_quote.get("error", "")) == "vehicle_has_no_persistent_state", "non-owned service fails closed")

	var state_before_broke: Dictionary = map_manager.get_vehicle_state("kombi_terreiro")
	world_state.money = 0
	world_state._sync_aliases()
	var broke_service: Dictionary = map_manager.service_vehicle("kombi_terreiro", {"install_upgrades": ["tires"]})
	_check(not bool(broke_service.get("ok", true)), "service fails when money is insufficient")
	_check(str(broke_service.get("error", "")) == "insufficient_money_for_vehicle_service", "insufficient-money service error is deterministic")
	_check(map_manager.get_vehicle_state("kombi_terreiro") == state_before_broke, "failed service is atomic and leaves vehicle unchanged")
	_check(int(world_state.money) == 0, "failed service does not create negative money")

	var serialized: Dictionary = map_manager.to_dict().duplicate(true)
	map_manager.reset()
	map_manager.load_from_dict(serialized)
	_check(map_manager.get_vehicle_state("kombi_terreiro") == state_before_broke, "vehicle upgrades and maintenance state survive round-trip")

	print("VEHICLE_SERVICE_SMOKE checks=%d failures=%d" % [checks, failures.size()])
	for failure in failures:
		push_error(failure)
	quit(0 if failures.is_empty() else 1)

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
