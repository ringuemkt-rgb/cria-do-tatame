extends SceneTree

var failures: Array[String] = []
var checks := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var map_manager = root.get_node("WorldMapManager")
	var world_state = root.get_node("WorldState")
	var progression = root.get_node("ProgressionOS")

	map_manager.reset()
	progression.reset()
	world_state.money = 500
	world_state.energy = 100.0
	world_state.act = 3
	world_state.story_flags = {}
	world_state.completed_missions = []
	world_state.current_hub = "itubera"
	world_state._sync_aliases()

	var hub_before := str(map_manager.current_hub)
	var node_before := str(map_manager.current_node)
	var money_before := int(world_state.money)
	var energy_before := float(world_state.energy)
	var log_before := map_manager.travel_log.size()

	var prepared: Dictionary = map_manager.prepare_travel(
		"pancada_grande",
		"kombi_terreiro",
		{"act": 3, "flags": {}, "route_unlocks": [], "weather": "nublado_quente"}
	)
	_check(bool(prepared.get("ok", false)), "prepare succeeds for traversable terrestrial route")
	var plan: Dictionary = prepared.get("plan", {})
	var plan_id := str(plan.get("plan_id", ""))
	_check(plan_id != "", "prepare creates stable plan id")
	_check(str(plan.get("origin_node", "")) == "itubera", "plan captures origin node")
	_check(str(plan.get("destination_node", "")) == "pancada_grande", "plan captures destination node")
	_check(str(plan.get("vehicle_id", "")) == "kombi_terreiro", "plan captures vehicle")
	_check(str(plan.get("route_type", "")) == "terrestre", "plan captures normalized route type")
	_check(str(map_manager.current_hub) == hub_before, "prepare does not move hub")
	_check(str(map_manager.current_node) == node_before, "prepare does not move node")
	_check(int(world_state.money) == money_before, "prepare does not spend money")
	_check(is_equal_approx(float(world_state.energy), energy_before), "prepare does not spend energy")
	_check(map_manager.travel_log.size() == log_before, "prepare does not append completed travel")
	_check(str(map_manager.get_pending_travel_plan().get("plan_id", "")) == plan_id, "prepare stores only pending contract state")

	var second_prepare: Dictionary = map_manager.prepare_travel("pancada_grande", "kombi_terreiro", {"act": 3})
	_check(not bool(second_prepare.get("ok", true)), "second prepare fails while plan is pending")
	_check(str(second_prepare.get("error", "")) == "travel_plan_already_pending", "pending-plan error is deterministic")

	var committed: Dictionary = map_manager.commit_travel_outcome(plan_id, {
		"success": true,
		"elapsed_minutes": 42,
		"money_delta": 0,
		"fuel_delta": 0.0,
		"vehicle_condition_delta": 0.0,
		"hard_damage_delta": 0,
		"energy_delta": -4.0,
		"arrival_condition": "steady",
		"clean": true,
		"discoveries": ["mirante_cacau"]
	})
	_check(bool(committed.get("ok", false)), "commit accepts matching pending plan")
	_check(bool(committed.get("travel_success", false)), "commit reports travel success")
	_check(str(map_manager.current_node) == "pancada_grande", "successful commit moves current node")
	_check(str(map_manager.current_hub) == "itubera", "local route preserves owning hub")
	_check(is_equal_approx(float(world_state.energy), 96.0), "commit applies actual energy delta once")
	_check(map_manager.get_pending_travel_plan().is_empty(), "commit clears pending plan")
	_check(map_manager.world_travel_state.get("committed_plan_ids", []).has(plan_id), "commit tombstones plan id")
	_check(map_manager.travel_log.size() == log_before + 1, "commit appends one travel entry")
	var mastery: Dictionary = map_manager.get_route_mastery(str(plan.get("route_id", "")))
	_check(str(mastery.get("level", "")) == "known", "first clean success discovers route")
	_check(int(mastery.get("completions", 0)) == 1, "route completion count increments once")
	_check(mastery.get("discoveries", []).has("mirante_cacau"), "route discovery is persisted")
	_check(int(progression.counters.get("travel_completed", 0)) == 1, "ProgressionOS records travel_completed once")
	_check(int(progression.counters.get("travel_clean", 0)) == 1, "ProgressionOS records clean travel once")
	_check(int(progression.counters.get("route_discovered", 0)) == 1, "ProgressionOS records route discovery once")

	var money_after_commit := int(world_state.money)
	var energy_after_commit := float(world_state.energy)
	var log_after_commit := map_manager.travel_log.size()
	var progression_after_commit := int(progression.counters.get("travel_completed", 0))
	var duplicate: Dictionary = map_manager.commit_travel_outcome(plan_id, {"success": true, "energy_delta": -50.0})
	_check(not bool(duplicate.get("ok", true)), "duplicate commit is rejected")
	_check(str(duplicate.get("error", "")) == "plan_already_committed", "duplicate commit has deterministic error")
	_check(int(world_state.money) == money_after_commit, "duplicate commit does not spend money")
	_check(is_equal_approx(float(world_state.energy), energy_after_commit), "duplicate commit does not spend energy")
	_check(map_manager.travel_log.size() == log_after_commit, "duplicate commit does not duplicate travel log")
	_check(int(progression.counters.get("travel_completed", 0)) == progression_after_commit, "duplicate commit does not duplicate progression event")

	var serialized: Dictionary = map_manager.to_dict().duplicate(true)
	map_manager.reset()
	map_manager.load_from_dict(serialized)
	_check(str(map_manager.current_node) == "pancada_grande", "world travel state round-trips current node")
	_check(map_manager.world_travel_state.get("committed_plan_ids", []).has(plan_id), "world travel state round-trips committed plan tombstone")
	_check(str(map_manager.get_route_mastery(str(plan.get("route_id", ""))).get("level", "")) == "known", "route mastery survives round-trip")

	# Hard failure consumes the plan but must never teleport the player.
	map_manager.reset()
	progression.reset()
	world_state.money = 500
	world_state.energy = 100.0
	world_state.current_hub = "itubera"
	world_state.act = 3
	world_state._sync_aliases()
	var failure_prepare: Dictionary = map_manager.prepare_travel(
		"pancada_grande",
		"kombi_terreiro",
		{"act": 3, "flags": {}, "route_unlocks": [], "weather": "chuva"}
	)
	_check(bool(failure_prepare.get("ok", false)), "failure scenario still prepares normally")
	var failure_plan_id := str(failure_prepare.get("plan", {}).get("plan_id", ""))
	var failed_commit: Dictionary = map_manager.commit_travel_outcome(failure_plan_id, {
		"success": false,
		"failure_reason": "vehicle_breakdown",
		"elapsed_minutes": 25,
		"money_delta": 0,
		"fuel_delta": 0.0,
		"vehicle_condition_delta": -20.0,
		"hard_damage_delta": 1,
		"energy_delta": -3.0,
		"arrival_condition": "shaken"
	})
	_check(bool(failed_commit.get("ok", false)), "failed journey still commits its real outcome")
	_check(not bool(failed_commit.get("travel_success", true)), "failed journey remains a travel failure")
	_check(str(map_manager.current_node) == "itubera", "failed journey returns/stays at origin")
	_check(str(map_manager.current_hub) == "itubera", "failed journey never changes hub")
	_check(map_manager.get_pending_travel_plan().is_empty(), "failed outcome clears consumed pending plan")
	_check(int(progression.counters.get("travel_breakdown", 0)) == 1, "breakdown is recorded in progression ledger")

	print("WORLD_TRAVEL_TWO_PHASE_SMOKE checks=%d failures=%d" % [checks, failures.size()])
	for failure in failures:
		push_error(failure)
	quit(0 if failures.is_empty() else 1)

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
