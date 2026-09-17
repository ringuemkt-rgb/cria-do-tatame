extends SceneTree

const DeckScript = preload("res://src/combat/CombatDeckRuntimeV2.gd")
const ScoutingScript = preload("res://src/combat/ScoutingSystem.gd")
const CornerScript = preload("res://src/combat/CornerSystem.gd")
const ComebackScript = preload("res://src/combat/ComebackSystem.gd")
const PostFightScript = preload("res://src/combat/PostFightCombatBridgeV2.gd")
const ReducerScript = preload("res://src/combat/BJJGraphReducerV2.gd")

func _init() -> void:
	if not _test_deck():
		return
	if not _test_scouting_corner():
		return
	if not _test_comeback():
		return
	if not _test_post_fight():
		return
	if not _test_reducer_determinism_50():
		return
	print("COMBAT_CORE_V2_SMOKE_OK")
	quit(0)

func _test_deck() -> bool:
	var available := ["t001", "t005", "t025", "t049", "t057", "slice_sprawl", "slice_side_to_mount", "slice_heel_hook"]
	var deck_a = DeckScript.new()
	var deck_b = DeckScript.new()
	if not bool(deck_a.build_deck(available, available).get("ok", false)):
		return _fail("deck_build_failed")
	if not bool(deck_b.build_deck(available, available).get("ok", false)):
		return _fail("deck_build_failed_b")
	deck_a.shuffle_deck(20260917)
	deck_b.shuffle_deck(20260917)
	var hand_a: Array = deck_a.draw_hand()
	var hand_b: Array = deck_b.draw_hand()
	if hand_a != hand_b or hand_a.size() != 6:
		return _fail("seeded_hand_not_deterministic")
	var first := str(hand_a[0])
	if not deck_a.play_card(first):
		return _fail("play_card_failed")
	if deck_a.refill_hand().size() != 6:
		return _fail("hand_not_refilled")
	var too_small = DeckScript.new()
	if bool(too_small.build_deck(available, available.slice(0, 5)).get("ok", true)):
		return _fail("small_deck_accepted")
	return true

func _test_scouting_corner() -> bool:
	var scouting = ScoutingScript.new()
	var report: Dictionary = scouting.build_report(
		"davi_relampago",
		{"display_name": "Davi Relampago", "archetype": "speedster", "preferred_actions": ["slice_sprawl"]},
		{"style": "velocidade_apelacao", "weaknesses": ["half_guard_top"], "signature_chain": "chain_relampago", "faction": "ALE"},
		{"technique_exposure": {"t025": 2, "t001": 1}}
	)
	if not report.get("counters_known", []).has("t025"):
		return _fail("nemesis_counter_missing")
	if report.get("counters_known", []).has("t001"):
		return _fail("nemesis_learned_too_early")
	var observed_a: Dictionary = scouting.observe_runtime("t001")
	var observed_b: Dictionary = scouting.observe_runtime("t001")
	if bool(observed_a.get("counter_suggestion_unlocked", true)):
		return _fail("runtime_scout_unlocked_early")
	if not bool(observed_b.get("counter_suggestion_unlocked", false)):
		return _fail("runtime_scout_not_unlocked")
	var kg := _load_json("res://data/bjj/bjj_kg_slice_ruan_davi_v1.json")
	var techniques := {}
	for row_value in kg.get("techniques", []):
		if typeof(row_value) == TYPE_DICTIONARY:
			var row: Dictionary = row_value
			techniques[str(row.get("id", ""))] = row
	var corner = CornerScript.new()
	corner.configure(_load_json("res://data/combat/bjj_position_values_v1.json"), techniques)
	var suggestion: Dictionary = corner.suggest_action(
		{"p1": {"gas": 25.0}},
		["t001", "t005", "t025", "t049", "t057", "slice_sprawl"],
		report
	)
	if suggestion.is_empty():
		return _fail("corner_no_suggestion")
	return true

func _test_comeback() -> bool:
	var comeback = ComebackScript.new()
	var state := {
		"winner": 0,
		"p1": {"score": 0, "gas": 25.0, "health": 100.0},
		"p2": {"score": 4, "gas": 80.0, "health": 100.0}
	}
	var first: Dictionary = comeback.activate(state, 1)
	if not bool(first.get("ok", false)):
		return _fail("virada_first_use_failed")
	if bool(comeback.activate(state, 1).get("ok", true)):
		return _fail("virada_second_use_allowed")
	return true

func _test_post_fight() -> bool:
	var bridge = PostFightScript.new()
	var result: Dictionary = bridge.enrich_result(
		{"winner": "ruan_macacao", "method": "points"},
		[
			{"technique_id": "t001", "success": true},
			{"technique_id": "t025", "success": true, "denied": false}
		],
		287,
		false
	)
	if result.get("clips", []).size() != 2:
		return _fail("clip_count_wrong")
	if float(result.get("best_clip", {}).get("quality", 0.0)) <= 0.0:
		return _fail("best_clip_missing")
	if int(result.get("duration", 0)) != 287:
		return _fail("duration_wrong")
	return true

func _test_reducer_determinism_50() -> bool:
	var kg := _load_json("res://data/bjj/bjj_kg_slice_ruan_davi_v1.json")
	var rules := _load_json("res://data/combat/bjj_rulesets_verified_v1.json")
	var timing := _load_json("res://data/combat/bjj_timing_windows_v1.json")
	for seed in range(1, 51):
		var reducer_a = ReducerScript.new(kg, rules, timing)
		var reducer_b = ReducerScript.new(kg, rules, timing)
		var state_a: Dictionary = reducer_a.new_state("ibjjf_v6", true, seed)
		var state_b: Dictionary = reducer_b.new_state("ibjjf_v6", true, seed)
		var actions: Array = reducer_a.available_actions(state_a, 1)
		if actions.is_empty():
			return _fail("no_action_seed_%d" % seed)
		var attack_id := str(actions[seed % actions.size()])
		var action := {"atk": attack_id, "atk_player": 1}
		var out_a: Dictionary = reducer_a.reduce(state_a, action)
		var out_b: Dictionary = reducer_b.reduce(state_b, action)
		if out_a != out_b:
			return _fail("reducer_nondeterministic_seed_%d" % seed)
	return true

func _load_json(path: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

func _fail(message: String) -> bool:
	push_error("COMBAT_CORE_V2_SMOKE_FAIL: %s" % message)
	quit(1)
	return false
