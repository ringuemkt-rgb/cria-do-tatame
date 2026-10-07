extends SceneTree
## Migration diagnostic. Exit 2 means measured parity is blocked, not a passing test.
## This covers neutral mapped actions only; it cannot certify full scoring/rules parity.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var combat = root.get_node("CombatManager")
	var observer = root.get_node("BJJShadowRuntimeObserver")
	var rows: Array = []
	var matching := 0
	var classes: Dictionary = {}
	var actions := ["baiana", "puxada_guarda"]
	for index in range(50):
		var seed_value := 260907 + index
		var action_id: String = actions[index % actions.size()]
		var begin: Dictionary = combat.start_combat("arena_do_dique", "ruan_macacao", "davi_relampago")
		if not bool(begin.get("ok", false)):
			push_error("PARITY_HARNESS_ERROR: combat did not start")
			quit(1)
			return
		combat.technique_resolver.rng.seed = seed_value
		observer.adapter.reset(seed_value, "ibjjf_v6", true, "touch")
		var result: Dictionary = combat.apply_player_action(action_id)
		var comparison: Dictionary = observer.get_last_comparison()
		if comparison.is_empty() or result.has("error"):
			push_error("PARITY_HARNESS_ERROR: comparison missing or action rejected")
			quit(1)
			return
		var classification := str(comparison.get("classification", "UNKNOWN"))
		classes[classification] = int(classes.get(classification, 0)) + 1
		var shadow: Dictionary = comparison.get("shadow", {})
		var canonical: Dictionary = shadow.get("shadow_after", {})
		var sync: Dictionary = observer.adapter.sync_from_legacy_state(combat.get_current_state_name())
		var exact_position := bool(sync.get("ok", false)) and str(sync.get("confidence", "")) == "EXACT" and str(sync.get("canonical_position", "")) == str(canonical.get("pos", ""))
		var resources_match := is_equal_approx(float(combat.fighters["ruan_macacao"]["gas"]), float(canonical.get("p1", {}).get("gas", -1)))
		var score_match := int(combat.fighters["ruan_macacao"]["score"]) == int(canonical.get("p1", {}).get("score", -1))
		var complete_match := classification == "MATCH" and exact_position and resources_match and score_match
		if complete_match:
			matching += 1
		rows.append({"case": index + 1, "seed": seed_value, "action": action_id,
			"classification": classification, "outcome_match": comparison.get("outcome_match", false),
			"exact_position_match": exact_position, "gas_match": resources_match,
			"immediate_score_match": score_match, "known_delta": comparison.get("known_semantic_delta", ""),
			"legacy_result": result, "shadow": shadow})
		combat.is_running = false
	var report := {"cases_run": rows.size(), "matching_cases": matching,
		"classifications": classes, "parity_percent": float(matching) * 100.0 / 50.0,
		"scope": "neutral mapped actions / IBJJF GI / seeds 260907..260956",
		"full_rules_scoring_coverage": false, "parity_100": false, "flip_allowed": false,
		"blockers": ["mapped actions carry semantic deltas", "full rules/scoring and Android coverage not certified"],
		"rows": rows}
	var output := "user://reducer_parity_report.json"
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2 and args[0] == "--report":
		output = args[1]
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		push_error("PARITY_HARNESS_ERROR: report could not be written")
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	print("REDUCER_PARITY_BLOCKED cases=%d matches=%d classifications=%s report=%s" % [rows.size(), matching, str(classes), output])
	quit(2)
