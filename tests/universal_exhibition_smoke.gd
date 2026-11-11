extends SceneTree

## End-to-end headless smoke. Checks all canonical matchup metadata and
## gameplay on multiple non-Ruan pairs without awarding campaign progression.
const ProfilesScript = preload("res://src/combat/FighterCombatProfileRegistryV1.gd")
const BridgeScript = preload("res://src/combat/TechniqueIdentityBridgeUniversalV1.gd")
const AIScript = preload("res://src/combat/DaviAIController.gd")
const FighterScript = preload("res://src/characters/FighterPlaceholder.gd")
const PairScript = preload("res://src/animation/CombatPairTimelineV1.gd")

var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures.append(description)
		push_error("[UniversalExhibition] " + description)

func _run() -> void:
	await process_frame
	var registry = ProfilesScript.new()
	_check(registry.ready(), "all profile schemas and IDs validated")
	_check(registry.fighter_ids().size() == 17, "17 canonical fighters registered, no invented 18th")
	var fighter_ids := registry.fighter_ids()
	for fighter_id in fighter_ids:
		var p: Dictionary = registry.profile(fighter_id)
		_check(p.get("preferred_actions", []).size() >= 3, "tactical style actions for " + fighter_id)
		_check(p.get("attributes", {}).size() >= 10, "candidate attributes for " + fighter_id)
		for other_id in fighter_ids:
			if other_id == fighter_id:
				continue
			var candidate: Dictionary = registry.prepare_exhibition(fighter_id, other_id, "arena_do_dique")
			_check(bool(candidate.get("ok", false)) and not bool(candidate.get("shipping", true)), "pair metadata " + fighter_id + " v " + other_id)
	_check(not bool(registry.prepare_exhibition("leoa", "leoa", "arena_do_dique").get("ok", true)), "same fighter rejected")
	_check(not bool(registry.prepare_exhibition("invented", "leoa", "arena_do_dique").get("ok", true)), "unknown fighter rejected")
	_check(not registry.action_allowed("leoa", "silverback_grip"), "only canonical owner has Silverback Grip")
	_check(registry.action_allowed("ruan_macacao", "silverback_grip"), "Ruan retains Silverback Grip")

	var bridge = BridgeScript.new()
	_check(bridge.ready(), "technique bridge covers master catalog and shadow mappings")
	var baiana: Dictionary = bridge.resolve("baiana", "PLAYER_STANDING_NEUTRAL")
	_check(baiana.get("candidate_bjj_id") == "t001", "legacy Baiana maps to candidate t001")
	_check(baiana.get("mapping_status") == "KNOWN_SEMANTIC_DELTA", "Baiana state delta remains explicit")
	_check(not bool(baiana.get("safe_to_promote_reducer_authority", true)), "bridge cannot change scoring")
	_check(bridge.resolve("sprawl").get("mapping_status") == "KNOWN_SEMANTIC_DELTA", "Sprawl counter mismatch is visible")
	_check(not bool(bridge.resolve("unknown_technique").get("ok", true)), "unknown technique fails closed")
	_check(not bool(bridge.resolve("baiana", "PLAYER_TOP_MOUNT").get("ok", true)), "entry state mismatch fails closed")
	var cm: Node = root.get_node_or_null("CombatManager")
	_check(cm != null, "canonical CombatManager autoload exists")
	if cm == null:
		_report()
		return
	var world: Node = root.get_node("WorldState")
	var money_before: int = int(world.money)
	var victories_before: int = int(world.fights_won)
	var defeats_before: int = int(world.fights_lost)
	var week_before: int = int(world.week)
	var progression_snapshot := {}
	var progression_node := root.get_node_or_null("ProgressionOS")
	if progression_node != null and progression_node.has_method("to_dict"):
		progression_snapshot = progression_node.to_dict()
	var results: Array[Dictionary] = []
	for matchup in [["leoa", "jacare_do_mangue"], ["miyao", "viera"], ["leoa", "jacare_do_mangue"]]:
		var a := str(matchup[0])
		var b := str(matchup[1])
		var plan: Dictionary = cm.prepare_exhibition_match(a, b, "arena_do_dique")
		_check(bool(plan.get("ok", false)), "live exhibition match plan " + a + " v " + b)
		if not bool(plan.get("ok", false)):
			continue
		var start: Dictionary = cm.start_combat("arena_do_dique", a, b)
		_check(bool(start.get("ok", false)), "live combat starts " + a + " v " + b)
		if not bool(start.get("ok", false)):
			continue
		_check(bool(cm.is_exhibition) and cm.player_id == a and cm.opponent_id == b, "combat manager uses selected fighters")
		_check(cm.get_pending_exhibition_match().is_empty(), "match request consumed without carry-over")
		_check(cm.fighters.has(a) and cm.fighters.has(b), "fighter resources generated for pair")
		var available: Array = cm.get_available_techniques()
		_check(not available.is_empty(), "player gets valid techniques")
		var denied: Dictionary = cm.apply_opponent_action("silverback_grip")
		_check(str(denied.get("error", "")) == "fighter_repertoire_restricted", "Ruan-only ultimate barred for opponent")
		_check(not cm.get_available_techniques(b).is_empty(), "opponent gets valid techniques")

		var ai = AIScript.new()
		root.add_child(ai)
		ai.setup(b, "normal", 412)
		_check(str(ai.profile.get("display_name", "")) == str(registry.profile(b).get("display_name", "")), "AI uses selected fighter's own profile")
		var rival_action: Dictionary = ai.choose_technique(cm)
		_check(not rival_action.is_empty(), "AI chooses legal, affordable opponent action")
		if not rival_action.is_empty():
			_check(registry.action_allowed(b, str(rival_action.get("id", ""))), "AI stays within opponent repertoire")
		ai.queue_free()
		var result: Dictionary = cm.apply_player_action("grip_de_ferro")
		_check(not result.has("error"), "fighter executes canonical technique in neutral state")
		results.append({"pair": [a, b], "success": bool(result.get("success", false)), "state_to": str(result.get("state_to", ""))})
		cm.finish_combat({"winner": a, "loser": b, "method": "fixture", "technical": false})
		_check(bool(cm.last_result.get("exhibition", false)), "final result marked exhibition")
		_check(not cm.is_running, "combat stops after result")
	_check(results.size() == 3, "three independent matchup samples completed")
	if results.size() == 3:
		_check(results[0] == results[2], "repeated seed and pair produce deterministic outcome")
	_check(int(world.money) == money_before and int(world.fights_won) == victories_before and int(world.fights_lost) == defeats_before and int(world.week) == week_before, "exhibition leaves campaign money, results, week untouched")
	if progression_node != null and progression_node.has_method("to_dict"):
		_check(progression_snapshot == progression_node.to_dict(), "exhibition grants no progression XP")

	# Validate the actual visual clock with a NON-Ruan pair and either acting role.
	var first = FighterScript.new()
	first.fighter_id = "leoa"
	first.display_name = "Leoa"
	root.add_child(first)
	var second = FighterScript.new()
	second.fighter_id = "jacare_do_mangue"
	second.display_name = "Jacare"
	root.add_child(second)
	var paired = PairScript.new()
	root.add_child(paired)
	_check(paired.configure_views(first, second), "shared six-phase clock accepts any canonical pair")
	var f: Dictionary = paired.plan_for("baiana", "leoa", true, true, "PLAYER_STANDING_NEUTRAL", "PLAYER_TOP_GUARD")
	var g: Dictionary = paired.plan_for("baiana", "jacare_do_mangue", true, true, "PLAYER_STANDING_NEUTRAL", "PLAYER_BOTTOM_GUARD")
	_check(f.get("phases", []).size() == 6 and g.get("phases", []).size() == 6, "both acting directions have six shared phases")
	_check(not bool(f.get("authoritative", true)) and not bool(f.get("shipping", true)), "paired preview never decides combat")
	_check(paired.plan_for("baiana", "davi_relampago", true, true, "PLAYER_STANDING_NEUTRAL", "PLAYER_TOP_GUARD").is_empty(), "outside actor rejected")
	paired.queue_free()
	first.queue_free()
	second.queue_free()
	_report()

func _report() -> void:
	if failures.is_empty():
		print("[UniversalExhibition] PASS checks=%d" % checks)
		quit(0)
	else:
		print("[UniversalExhibition] FAIL checks=%d failures=%d" % [checks, failures.size()])
		quit(1)
