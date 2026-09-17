class_name CombatCoreV2Coordinator
extends RefCounted

const DeckRuntimeScript = preload("res://src/combat/CombatDeckRuntimeV2.gd")
const ScoutingScript = preload("res://src/combat/ScoutingSystem.gd")
const CornerScript = preload("res://src/combat/CornerSystem.gd")
const ComebackScript = preload("res://src/combat/ComebackSystem.gd")
const PostFightScript = preload("res://src/combat/PostFightCombatBridgeV2.gd")

var deck_runtime
var scouting
var corner
var comeback
var post_fight

var techniques: Dictionary = {}
var rival_profiles: Dictionary = {}
var scouting_profiles: Dictionary = {}
var timer_profiles: Dictionary = {}
var current_plan: Dictionary = {}
var action_log: Array = []
var started_at_msec: int = 0
var virada_used := false

func configure(
	technique_catalog: Dictionary,
	rival_profile_data: Dictionary,
	position_value_data: Dictionary,
	scouting_profile_data: Dictionary,
	timer_profile_data: Dictionary
) -> void:
	techniques = technique_catalog.duplicate(true)
	rival_profiles = rival_profile_data.duplicate(true)
	scouting_profiles = scouting_profile_data.duplicate(true)
	timer_profiles = timer_profile_data.duplicate(true)
	deck_runtime = DeckRuntimeScript.new()
	scouting = ScoutingScript.new()
	corner = CornerScript.new()
	corner.configure(position_value_data, techniques)
	comeback = ComebackScript.new()
	post_fight = PostFightScript.new()

func build_pre_fight_plan(
	opponent_id: String,
	available_techniques: Array,
	selection: Array,
	social_state: Dictionary,
	seed: int,
	ruleset: String,
	gi: bool,
	arena_id: String
) -> Dictionary:
	if deck_runtime == null:
		return {"ok": false, "reason": "coordinator_not_configured"}
	var deck_result: Dictionary = deck_runtime.build_deck(available_techniques, selection)
	if not bool(deck_result.get("ok", false)):
		return deck_result
	var rival_profile: Dictionary = rival_profiles.get(opponent_id, {})
	var overlay: Dictionary = scouting_profiles.get(opponent_id, {})
	var report: Dictionary = scouting.build_report(opponent_id, rival_profile, overlay, social_state)
	var timer: Dictionary = timer_profiles.get(ruleset, {})
	if timer.is_empty():
		return {"ok": false, "reason": "ruleset_timer_missing", "ruleset": ruleset}
	current_plan = {
		"opponent_id": opponent_id,
		"arena_id": arena_id,
		"ruleset": ruleset,
		"gi": gi,
		"seed": seed,
		"scouting": report,
		"timer_profile": timer.duplicate(true),
		"deck": deck_runtime.deck.duplicate()
	}
	var suggestion: Dictionary = corner.suggest_action(
		{"p1": {"gas": 100.0}},
		deck_runtime.deck,
		report
	)
	current_plan["corner_preview"] = suggestion
	return {"ok": true, "plan": current_plan.duplicate(true)}

func begin_fight() -> Dictionary:
	if current_plan.is_empty():
		return {"ok": false, "reason": "pre_fight_plan_missing"}
	deck_runtime.shuffle_deck(int(current_plan.get("seed", 0)))
	var hand: Array = deck_runtime.draw_hand()
	scouting.reset_fight()
	comeback.reset()
	action_log.clear()
	started_at_msec = Time.get_ticks_msec()
	virada_used = false
	return {
		"ok": true,
		"hand": hand,
		"timer_sec": int(current_plan.get("timer_profile", {}).get("duration_sec", 0)),
		"overtime": bool(current_plan.get("timer_profile", {}).get("overtime", false))
	}

func is_active() -> bool:
	return not current_plan.is_empty()

func card_available(technique_id: String) -> bool:
	return is_active() and deck_runtime.contains_in_hand(technique_id)

func consume_card(technique_id: String) -> Array:
	if not deck_runtime.play_card(technique_id):
		return deck_runtime.hand.duplicate()
	return deck_runtime.refill_hand()

func corner_suggestion(state: Dictionary) -> Dictionary:
	if not is_active():
		return {}
	return corner.suggest_action(state, deck_runtime.hand, current_plan.get("scouting", {}))

func observe_technique(technique_id: String) -> Dictionary:
	return scouting.observe_runtime(technique_id)

func activate_virada(state: Dictionary, player: int) -> Dictionary:
	var result: Dictionary = comeback.activate(state, player)
	if bool(result.get("ok", false)):
		virada_used = true
	return result

func append_action(event: Dictionary) -> void:
	action_log.append(event.duplicate(true))
	while action_log.size() > 96:
		action_log.pop_front()

func finish_result(base_result: Dictionary) -> Dictionary:
	var duration_sec := 0
	if started_at_msec > 0:
		duration_sec = maxi(0, int((Time.get_ticks_msec() - started_at_msec) / 1000))
	return post_fight.enrich_result(base_result, action_log, duration_sec, virada_used)

func snapshot() -> Dictionary:
	return {
		"active": is_active(),
		"plan": current_plan.duplicate(true),
		"deck": deck_runtime.to_dict() if deck_runtime != null else {},
		"scouting_runtime": scouting.to_dict() if scouting != null else {},
		"comeback": comeback.to_dict() if comeback != null else {},
		"action_log": action_log.duplicate(true),
		"virada_used": virada_used
	}

func clear() -> void:
	current_plan.clear()
	action_log.clear()
	started_at_msec = 0
	virada_used = false
