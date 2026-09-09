extends SceneTree

const ShadowAdapterScript = preload("res://src/combat/CombatManagerBJJShadowAdapterV1.gd")

var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)

func _run() -> void:
	await process_frame

	var adapter = ShadowAdapterScript.new()
	var init: Dictionary = adapter.initialize(260909, "ibjjf_v6", true, "touch")
	_check(bool(init.get("ok", false)), "standalone adapter initializes")
	_check(not bool(init.get("authoritative", true)), "standalone adapter is non-authoritative")

	var sync: Dictionary = adapter.sync_from_legacy_state("PLAYER_STANDING_NEUTRAL")
	_check(bool(sync.get("ok", false)), "standing state syncs")
	_check(str(sync.get("canonical_position", "")) == "standing_neutral", "standing maps exactly")

	var ambiguous: Dictionary = adapter.sync_from_legacy_state("PLAYER_TOP_GUARD")
	_check(not bool(ambiguous.get("ok", true)), "ambiguous guard state is rejected")
	_check(str(ambiguous.get("error", "")) == "legacy_state_ambiguous", "ambiguous state remains explicit")

	adapter.reset(260909, "ibjjf_v6", true, "touch")
	var baiana: Dictionary = adapter.compare_action_availability("baiana", 1)
	_check(bool(baiana.get("mapped", false)), "baiana is mapped")
	_check(str(baiana.get("canonical_action_id", "")) == "t001", "baiana maps to t001")
	_check(bool(baiana.get("canonical_available", false)), "t001 is available from neutral")
	_check(str(baiana.get("known_delta", "")) != "", "baiana semantic delta is documented")

	var unmapped: Dictionary = adapter.compare_action_availability("grip_de_ferro", 1)
	_check(not bool(unmapped.get("mapped", true)), "unverified legacy action remains unmapped")

	var observation: Dictionary = adapter.observe_legacy_action("baiana", 1, "PLAYER_STANDING_NEUTRAL")
	_check(bool(observation.get("observed", false)), "standalone shadow observes mapped action")
	_check(not bool(observation.get("authoritative", true)), "observation cannot become authoritative")
	_check(str(observation.get("canonical_expected_to", "")) == "half_guard_top", "canonical baiana destination preserved")

	# Runtime wiring: use the real autoload flow. Shadow output must be evidence only.
	var start: Dictionary = CombatManager.start_combat("terreiro_da_luta", "ruan_macacao", "davi_relampago")
	_check(bool(start.get("ok", false)), "real CombatManager starts")
	var live_result: Dictionary = CombatManager.apply_player_action("baiana")
	_check(live_result.has("success"), "legacy live result remains available")
	await process_frame
	var comparison: Dictionary = BJJShadowRuntimeObserver.get_last_comparison()
	_check(not comparison.is_empty(), "runtime observer records comparison")
	_check(not bool(comparison.get("authoritative", true)), "runtime comparison is non-authoritative")
	_check(str(comparison.get("legacy_action_id", "")) == "baiana", "runtime comparison identifies legacy action")
	var summary: Dictionary = BJJShadowRuntimeObserver.summary()
	_check(int(summary.get("comparisons", 0)) >= 1, "runtime shadow session counts comparisons")
	_check(not bool(summary.get("authoritative", true)), "runtime shadow summary cannot claim authority")
	if bool(CombatManager.get("is_running")):
		CombatManager.finish_combat({"winner": "ruan_macacao", "loser": "davi_relampago", "method": "shadow_smoke", "technical": false})

	if failures.is_empty():
		print("BJJ_SHADOW_SMOKE PASS %d/%d" % [checks, checks])
		quit(0)
	else:
		for failure in failures:
			push_error("BJJ_SHADOW_SMOKE FAIL: %s" % failure)
		print("BJJ_SHADOW_SMOKE FAIL %d checks / %d failures" % [checks, failures.size()])
		quit(1)
