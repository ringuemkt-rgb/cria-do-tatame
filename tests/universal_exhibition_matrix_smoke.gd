extends SceneTree

## Starts and resolves every ordered canonical pairing in the actual CombatManager.
## NO claim that final art, full BJJ graph or Android QA is complete.
const Registry = preload("res://src/combat/FighterCombatProfileRegistryV1.gd")

var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(verified: bool, label: String) -> void:
	checks += 1
	if not verified:
		failures.append(label)
		push_error("[UniversalMatrix] " + label)

func _run() -> void:
	await process_frame
	var profiles = Registry.new()
	_check(profiles.ready(), "canonical fighter profiles available")
	if not profiles.ready():
		_report()
		return
	var cm = root.get_node("CombatManager")
	var world = root.get_node("WorldState")
	var money: int = int(world.money)
	var wins: int = int(world.fights_won)
	var losses: int = int(world.fights_lost)
	var week: int = int(world.week)
	var result_before: Dictionary = world.last_combat_result.duplicate(true)
	var count := 0
	for first in profiles.fighter_ids():
		for second in profiles.fighter_ids():
			if first == second:
				continue
			var plan: Dictionary = cm.prepare_exhibition_match(first, second, "arena_do_dique")
			_check(bool(plan.get("ok", false)), "plan " + first + " v " + second)
			if not bool(plan.get("ok", false)):
				continue
			var start: Dictionary = cm.start_combat("arena_do_dique", first, second)
			_check(bool(start.get("ok", false)), "start " + first + " v " + second)
			if not bool(start.get("ok", false)):
				cm.cancel_exhibition_match()
				continue
			_check(cm.is_running and cm.is_exhibition, "live exhibition " + first + " v " + second)
			_check(cm.fighters.has(first) and cm.fighters.has(second), "both resources " + first + " v " + second)
			var eligible: Array = cm.get_available_techniques()
			var known := false
			for technique in eligible:
				if str(technique.get("id", "")) == "grip_de_ferro":
					known = true
			_check(known, "common legal opening for " + first)
			var move: Dictionary = cm.apply_player_action("grip_de_ferro")
			_check(not move.has("error"), "legal opening resolves " + first + " v " + second)
			cm.finish_combat({"winner": first, "loser": second, "method": "test_fixture"})
			_check(not cm.is_running and bool(cm.last_result.get("exhibition", false)), "finished in isolated mode")
			count += 1
	_check(count == profiles.fighter_ids().size() * (profiles.fighter_ids().size() - 1), "all 272 directed pairings reached combat")
	_check(int(world.money) == money and int(world.fights_won) == wins and int(world.fights_lost) == losses and int(world.week) == week, "no campaign counters changed")
	_check(world.last_combat_result == result_before, "campaign result object remains untouched")
	_report()

func _report() -> void:
	if failures.is_empty():
		print("[UniversalMatrix] PASS directed_pairs=272 checks=%d" % checks)
		quit(0)
	else:
		print("[UniversalMatrix] FAIL failures=%d checks=%d" % [failures.size(), checks])
		quit(1)
