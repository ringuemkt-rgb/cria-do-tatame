extends SceneTree

const ResolverScript = preload("res://src/combat/TechniqueResolver.gd")
const CoordinatorScript = preload("res://src/combat/CombatCoreV2Coordinator.gd")
const DaviAIControllerScript = preload("res://src/combat/DaviAIController.gd")
const CombatDeckHUDScript = preload("res://scenes/ui/CombatDeckHUD.gd")
const SELECTION := ["grip_de_ferro", "baiana", "sprawl", "puxada_guarda", "corte_joelho", "encerramento_tecnico"]
var checks := 0
var failures := 0
var started_events := 0
var resolved_events := 0
var cm: Node

func _init() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("[CombatActionSafety] " + label)

func _run() -> void:
	await process_frame
	cm = root.get_node("CombatManager")
	_test_resolver_rejections()
	_test_plan_atomicity()
	_test_campaign_golden_chain_preset()
	_test_full_golden_chain_runtime()
	_test_grappling_scoring_authority()
	_test_interactive_defense_contract()
	_test_runtime_guards()
	_test_seeded_runtime()
	_test_aether_playable_adaptation()
	await _test_scene_input_lock()
	print("[CombatActionSafety] checks=%d failures=%d" % [checks, failures])
	print("[CombatActionSafety] PASS" if failures == 0 else "[CombatActionSafety] FAIL")
	quit(0 if failures == 0 else 1)

func _test_resolver_rejections() -> void:
	var resolver = ResolverScript.new()
	root.add_child(resolver)
	var actor := {"gas": 50.0, "focus": 50.0, "moral": 50.0}
	var defender := actor.duplicate(true)
	var technique := {"id": "fixture", "entry_state": "PLAYER_TOP_MOUNT", "exit_state": "PLAYER_SUBMISSION_ATTACK", "cost": {"gas": 10}, "commit_frame": 8}
	var rng_before: int = resolver.rng.state
	for context in [{"state": "PLAYER_STANDING_NEUTRAL"}, {"state": "PLAYER_STANDING_NEUTRAL", "fake": true, "frame": 0}]:
		var rejected: Dictionary = resolver.resolve_technique(technique, actor, defender, context)
		_check(not bool(rejected.get("accepted", true)), "wrong-position/fake attempt rejected")
		_check(rejected.get("state_to") == "PLAYER_STANDING_NEUTRAL", "rejection preserves position")
		_check(resolver.aplicar_resultado(actor, defender, rejected) == {"actor": actor, "defender": defender}, "rejection preserves both fighters")
	actor["gas"] = 0.0
	var low: Dictionary = resolver.resolve_technique(technique, actor, defender, {"state": "PLAYER_TOP_MOUNT"})
	_check(low.get("error") == "recurso_insuficiente", "insufficient gas rejected")
	_check(resolver.rng.state == rng_before, "rejected attempts consume no random draws")
	resolver.queue_free()

func _test_plan_atomicity() -> void:
	var coordinator = CoordinatorScript.new()
	coordinator.configure({}, {}, {}, {}, {"ibjjf": {"duration_sec": 360}})
	var first: Dictionary = coordinator.build_pre_fight_plan("davi_relampago", SELECTION, SELECTION, {}, 42, "ibjjf", true, "arena_do_dique")
	_check(bool(first.get("ok")), "valid plan accepted")
	coordinator.begin_fight()
	var before: Dictionary = coordinator.snapshot()
	var rejected: Dictionary = coordinator.build_pre_fight_plan("other", SELECTION, SELECTION, {}, 3, "unknown", false, "other")
	_check(not bool(rejected.get("ok")), "unknown ruleset rejected")
	_check(coordinator.snapshot() == before, "invalid ruleset cannot clear live hand or mix plans")
	coordinator.build_pre_fight_plan("other", SELECTION, SELECTION.slice(0, 2), {}, 3, "ibjjf", true, "other")
	_check(coordinator.snapshot() == before, "invalid deck cannot mutate plan")

func _test_campaign_golden_chain_preset() -> void:
	var deck := root.get_node("DeckManager")
	var preset: Array = deck.get_v2_preset("adaptativo")
	var required := ["baiana", "sprawl", "raspagem_tesoura", "corte_joelho", "montada_pesada", "chave_braco"]
	_check(preset.size() >= 6 and preset.size() <= 8, "campaign adaptive preset has valid V2 size")
	for technique_id in required:
		_check(preset.has(technique_id), "campaign preset includes golden-chain technique %s" % technique_id)
	var unlocked: Array = deck.get_unlocked_technique_ids()
	for technique_id in required:
		_check(unlocked.has(technique_id), "golden-chain technique is unlocked for Ruan: %s" % technique_id)

	cm.is_running = false
	cm.clear_combat_v2_plan()
	var plan: Dictionary = cm.combat_core_v2.build_pre_fight_plan(
		"davi_relampago",
		unlocked,
		preset,
		{},
		4242,
		"ibjjf",
		true,
		"arena_do_dique"
	)
	_check(bool(plan.get("ok", false)), "real campaign adaptive preset builds a valid pre-fight plan")
	var start: Dictionary = cm.start_combat("arena_do_dique", "ruan_macacao", "davi_relampago")
	_check(bool(start.get("ok", false)), "real campaign golden-chain plan starts")
	if bool(start.get("ok", false)):
		var progression_cases := [
			{"state": "PLAYER_TOP_GUARD", "technique": "corte_joelho"},
			{"state": "PLAYER_TOP_SIDE", "technique": "montada_pesada"},
			{"state": "PLAYER_TOP_MOUNT", "technique": "chave_braco"}
		]
		for case_value in progression_cases:
			var case: Dictionary = case_value
			var target_state := str(case.get("state", ""))
			var target_technique := str(case.get("technique", ""))
			cm.state_machine.call("forcar_estado", cm.state_machine.call("estado_por_nome", target_state))
			cm._ensure_v2_playable_hand()
			_check(
				cm.combat_core_v2.card_available(target_technique),
				"dead-hand rescue exposes %s in %s" % [target_technique, target_state]
			)

		cm.state_machine.call("forcar_estado", cm.state_machine.call("estado_por_nome", "PLAYER_SUBMISSION_ATTACK"))
		var available_ids: Array = []
		for row_value in cm.get_available_techniques():
			if typeof(row_value) == TYPE_DICTIONARY:
				available_ids.append(str(row_value.get("id", "")))
		_check(not preset.has("encerramento_tecnico"), "technical finish is not wasted as a deck slot")
		_check(available_ids.has("encerramento_tecnico"), "technical finish appears contextually after submission control")
	cm.is_running = false

func _execute_player_until_success(technique_id: String, max_attempts: int = 24) -> Dictionary:
	var registry := root.get_node("DataRegistry")
	var technique: Dictionary = registry.get_technique(technique_id)
	var last: Dictionary = {}
	for _attempt in range(max_attempts):
		if not cm.is_running:
			break
		cm.fighters[cm.player_id]["gas"] = 100.0
		cm.fighters[cm.player_id]["focus"] = 100.0
		cm.fighters[cm.player_id]["moral"] = 100.0
		if technique_id != "encerramento_tecnico":
			cm.combat_core_v2.ensure_playable_hand([technique_id])
		last = cm.execute_technique(cm.player_id, cm.opponent_id, technique)
		if bool(last.get("success", false)):
			return last
	return last

func _test_full_golden_chain_runtime() -> void:
	var deck := root.get_node("DeckManager")
	var preset: Array = deck.get_v2_preset("adaptativo")
	var unlocked: Array = deck.get_unlocked_technique_ids()
	cm.is_running = false
	cm.clear_combat_v2_plan()
	var plan: Dictionary = cm.combat_core_v2.build_pre_fight_plan(
		"davi_relampago",
		unlocked,
		preset,
		{},
		1337,
		"ibjjf",
		true,
		"arena_do_dique"
	)
	_check(bool(plan.get("ok", false)), "full golden-chain test plan builds")
	var start: Dictionary = cm.start_combat("arena_do_dique", "ruan_macacao", "davi_relampago")
	_check(bool(start.get("ok", false)), "full golden-chain runtime starts")
	if not bool(start.get("ok", false)):
		return

	var takedown: Dictionary = _execute_player_until_success("baiana")
	_check(bool(takedown.get("success", false)), "golden chain: takedown succeeds")
	_check(cm.get_current_state_name() == "PLAYER_TOP_GUARD", "golden chain: takedown reaches top guard")
	cm.tick_combat_timer(3.0)
	_check(int(cm.scoring_system.get_score().get("player", 0)) == 2, "golden chain: stabilized takedown scores 2")

	var passing: Dictionary = _execute_player_until_success("corte_joelho")
	_check(bool(passing.get("success", false)), "golden chain: knee cut succeeds")
	_check(cm.get_current_state_name() == "PLAYER_TOP_SIDE", "golden chain: pass reaches side control")
	cm.tick_combat_timer(3.0)
	_check(int(cm.scoring_system.get_score().get("player", 0)) == 5, "golden chain: stabilized pass brings score to 5")

	var mount: Dictionary = _execute_player_until_success("montada_pesada")
	_check(bool(mount.get("success", false)), "golden chain: mount transition succeeds")
	_check(cm.get_current_state_name() == "PLAYER_TOP_MOUNT", "golden chain: control reaches mount")
	cm.tick_combat_timer(3.0)
	_check(int(cm.scoring_system.get_score().get("player", 0)) == 9, "golden chain: stabilized mount brings score to 9")

	var submission_entry: Dictionary = _execute_player_until_success("chave_braco")
	_check(bool(submission_entry.get("success", false)), "golden chain: armbar entry succeeds")
	_check(cm.get_current_state_name() == "PLAYER_SUBMISSION_ATTACK", "golden chain: armbar enters submission control")
	var finisher_available := false
	for row_value in cm.get_available_techniques():
		if typeof(row_value) == TYPE_DICTIONARY and str(row_value.get("id", "")) == "encerramento_tecnico":
			finisher_available = true
			break
	_check(finisher_available, "golden chain: contextual finish is offered")

	var finish_attempt: Dictionary = _execute_player_until_success("encerramento_tecnico")
	_check(bool(finish_attempt.get("success", false)), "golden chain: technical finish succeeds")
	_check(not cm.is_running, "golden chain: successful submission ends combat")
	_check(str(cm.last_result.get("winner", "")) == cm.player_id, "golden chain: Ruan is recorded as winner")
	_check(str(cm.last_result.get("method", "")) == "encerramento_tecnico", "golden chain: finish method is submission closure")

func _test_grappling_scoring_authority() -> void:
	var scoring = load("res://src/combat/ScoringSystem.gd").new()
	root.add_child(scoring)
	scoring.reset()
	var queued: Dictionary = scoring.queue_event("player", "takedown_clean", 3.0, "PLAYER_TOP_GUARD", "baiana")
	_check(bool(queued.get("queued", false)), "takedown waits for stabilization")
	scoring.tick_stabilization(2.9, "PLAYER_TOP_GUARD")
	_check(int(scoring.get_score().get("player", 0)) == 0, "no points before three seconds")
	var awarded: Array = scoring.tick_stabilization(0.1, "PLAYER_TOP_GUARD")
	_check(int(scoring.get_score().get("player", 0)) == 2, "stable takedown awards two points")
	_check(awarded.size() == 1 and bool(awarded[0].get("awarded", false)), "stabilized event reports award")

	scoring.queue_event("player", "guard_pass", 3.0, "PLAYER_TOP_SIDE", "corte_joelho")
	scoring.tick_stabilization(1.0, "PLAYER_TOP_SIDE")
	var cancelled: Array = scoring.tick_stabilization(0.1, "PLAYER_TOP_GUARD")
	_check(int(scoring.get_score().get("player", 0)) == 2, "lost position cancels pending pass points")
	_check(cancelled.size() == 1 and bool(cancelled[0].get("cancelled", false)), "broken stabilization is explicit")

	scoring.queue_event("player", "mount", 3.0, "PLAYER_TOP_MOUNT", "montada_pesada")
	scoring.tick_stabilization(3.0, "PLAYER_TOP_MOUNT")
	_check(int(scoring.get_score().get("player", 0)) == 6, "mount adds four points after stabilization")
	scoring.apply_event("rival", "advantage")
	_check(int(scoring.get_score().get("rival_advantages", 0)) == 1, "advantage alias is scored")

	scoring.reset()
	scoring.apply_event("player", "advantage")
	_check(scoring.get_time_decision().get("winner_side") == "player", "advantages break tied points")
	scoring.reset()
	scoring.apply_event("rival", "penalty")
	_check(scoring.get_time_decision().get("winner_side") == "player", "fewer penalties break tied points and advantages")
	scoring.reset()
	_check(scoring.get_time_decision().get("winner_side") == "draw", "fully tied regulation requires non-score decision")
	scoring.queue_free()

	_prepare()
	cm.fighters[cm.player_id]["health"] = 0.0
	cm.fighters[cm.player_id]["gas"] = 0.0
	cm.fighters[cm.opponent_id]["health"] = 0.0
	cm.fighters[cm.opponent_id]["gas"] = 0.0
	cm._check_end(cm.player_id, cm.opponent_id, {}, {})
	_check(cm.is_running, "HP/gas exhaustion no longer ends grappling")
	var registry := root.get_node("DataRegistry")
	var finisher: Dictionary = registry.get_technique("encerramento_tecnico")
	cm.fighters[cm.player_id]["control"] = 0.0
	cm.fighters[cm.opponent_id]["health"] = 100.0
	_check(
		cm._resolve_finisher_before_transition(
			cm.player_id,
			cm.opponent_id,
			finisher,
			{"success": true},
			"PLAYER_SUBMISSION_ATTACK"
		),
		"successful committed submission can finish without HP/control threshold"
	)

	_prepare()
	cm.scoring_system.apply_event("player", "takedown_clean")
	cm._sync_score_from_system()
	cm.combat_v2_timer_remaining = 0.01
	var time_out: Dictionary = cm.tick_combat_timer(0.02)
	_check(bool(time_out.get("expired", false)) and not cm.is_running, "regulation expiry resolves fight")
	_check(cm.last_result.get("winner") == cm.player_id, "points decide winner at regulation")
	_check(cm.last_result.get("method") == "pontos", "time result records points basis")
	_check(int(cm.last_result.get("scoreboard", {}).get("player", 0)) == 2, "final result preserves scoreboard")

	_prepare()
	cm.combat_v2_timer_remaining = 0.01
	cm.tick_combat_timer(0.02)
	_check(bool(cm.last_result.get("draw", false)), "fully tied score ends as explicit draw instead of false loss")

func _prepare(seed_value: int = 42) -> void:
	cm.is_running = false
	cm.clear_combat_v2_plan()
	# Exercise the coordinator with catalog IDs independently of campaign unlocks.
	var plan: Dictionary = cm.combat_core_v2.build_pre_fight_plan("davi_relampago", SELECTION, SELECTION, {}, seed_value, "ibjjf", true, "arena_do_dique")
	_check(bool(plan.get("ok")), "fixture plan ready")
	var start: Dictionary = cm.start_combat("arena_do_dique", "ruan_macacao", "davi_relampago")
	_check(bool(start.get("ok")), "fixture starts")

func _on_started(_id, _actor) -> void:
	started_events += 1

func _on_resolved(_result) -> void:
	resolved_events += 1

func _test_interactive_defense_contract() -> void:
	_prepare()
	var options: Array = cm.get_defense_options(cm.opponent_id, "baiana")
	_check(options.size() == 1, "Davi takedown exposes one legal player defense")
	if options.is_empty():
		return
	_check(str(options[0].get("id", "")) == "sprawl", "baiana defense contract resolves to sprawl")
	var gas_before := float(cm.fighters[cm.player_id].get("gas", 0.0))
	var focus_before := float(cm.fighters[cm.player_id].get("focus", 0.0))
	var result: Dictionary = cm.apply_opponent_action_with_defense("baiana", "sprawl", 0.0)
	_check(bool(result.get("denied", false)), "timed sprawl denies committed takedown")
	_check(bool(result.get("countered", false)), "successful defense becomes positional counter")
	_check(cm.get_current_state_name() == "PLAYER_TOP_CLINCH", "sprawl counter transitions player to top clinch")
	_check(float(cm.fighters[cm.player_id].get("gas", 0.0)) < gas_before, "committed defense spends gas")
	_check(float(cm.fighters[cm.player_id].get("focus", 0.0)) < focus_before, "committed defense spends focus")
	var defense_logged := false
	for event_value in cm.combat_core_v2.action_log:
		if typeof(event_value) == TYPE_DICTIONARY and str(event_value.get("role", "")) == "defense" and str(event_value.get("technique_id", "")) == "sprawl":
			defense_logged = true
			break
	_check(defense_logged, "defense commitment is persisted in combat action log")

func _test_runtime_guards() -> void:
	_prepare()
	var bus := root.get_node("SignalBus")
	bus.technique_started.connect(_on_started)
	bus.technique_resolved.connect(_on_resolved)
	var fighters_before: Dictionary = cm.fighters.duplicate(true)
	var deck_before: Dictionary = cm.combat_core_v2.deck_runtime.to_dict()
	var rng_before: int = cm.technique_resolver.rng.state
	var registry := root.get_node("DataRegistry")
	var knee: Dictionary = registry.get_technique("corte_joelho")
	_check(cm.apply_player_action("corte_joelho").get("error") == "estado_posicional_incorreto", "wrong-position card rejected at manager")
	_check(cm.apply_actor_action("ruan_macacao", "montada_pesada").get("error") == "deck_card_not_in_hand", "direct actor call cannot bypass hand")
	_check(cm.execute_technique("ruan_macacao", "ruan_macacao", knee).get("error") == "same_fighter", "self-target rejected")
	_check(cm.apply_opponent_action("silverback_grip").get("error") == "technique_owner_mismatch", "Davi cannot execute Ruan signature")
	_check(cm.fighters == fighters_before, "invalid inputs leave resources unchanged")
	_check(cm.combat_core_v2.deck_runtime.to_dict() == deck_before, "invalid inputs leave hand/discard unchanged")
	_check(cm.technique_resolver.rng.state == rng_before, "invalid inputs leave RNG unchanged")
	_check(started_events == 0 and resolved_events == 0, "invalid inputs emit no action/scouting/shadow events")
	_check(not bool(cm.prepare_combat_v2("davi_relampago", "arena_do_dique", "ibjjf", true, SELECTION).get("ok")), "cannot replace plan during fight")
	var hint: Dictionary = cm.get_corner_suggestion()
	var playable: Array = []
	for row in cm.get_available_techniques():
		if row.get("affordable", false):
			_check(not playable.has(row.get("id")), "catalog aliases do not duplicate playable actions")
			playable.append(row.get("id"))
	_check(playable.has(hint.get("kg_id")), "corner suggests only playable hand action")
	cm.fighters[cm.player_id]["gas"] = 0.0
	_check(cm.get_corner_suggestion().is_empty(), "corner does not suggest unaffordable action")
	cm.is_running = false
	var stopped_before: Dictionary = cm.fighters.duplicate(true)
	_check(cm.execute_technique("ruan_macacao", "davi_relampago", knee).get("error") == "combat_not_running", "direct execute blocked after fight")
	_check(not bool(cm.activate_virada_do_cria().get("ok")), "comeback blocked outside fight")
	_check(cm.fighters == stopped_before, "stopped fight cannot change resources")
	bus.technique_started.disconnect(_on_started)
	bus.technique_resolved.disconnect(_on_resolved)

func _replay(seed_value: int) -> Array:
	_prepare(seed_value)
	var results: Array = []
	for step in range(5):
		# Repeat a legal entry from identical neutral states; no wall-clock RNG.
		cm.state_machine.reiniciar_em_pe()
		results.append(cm.apply_player_action("baiana").duplicate(true))
	return results

func _test_seeded_runtime() -> void:
	for seed_value in range(1, 11):
		_check(_replay(seed_value) == _replay(seed_value), "actual CombatManager replay seed %d" % seed_value)
	cm.is_running = false
	var before: Dictionary = cm.fighters.duplicate(true)
	_check(not bool(cm.start_combat("wrong_arena", "ruan_macacao", "davi_relampago").get("ok")), "stale preflight mismatch blocked")
	_check(cm.fighters == before and not cm.is_running, "mismatch does not start or mutate fight")


func _test_aether_playable_adaptation() -> void:
	var ai = DaviAIControllerScript.new()
	root.add_child(ai)
	ai.setup("davi_relampago", "facil")
	var easy_delay := ai.get_reaction_delay()
	var easy_read := ai.get_read_strength()
	ai.setup("davi_relampago", "normal")
	var normal_delay := ai.get_reaction_delay()
	var normal_read := ai.get_read_strength()
	ai.setup("davi_relampago", "dificil")
	var hard_delay := ai.get_reaction_delay()
	var hard_read := ai.get_read_strength()
	ai.setup("davi_relampago", "pesadelo")
	var nightmare_delay := ai.get_reaction_delay()
	var nightmare_read := ai.get_read_strength()
	_check(easy_delay > normal_delay and normal_delay > hard_delay and hard_delay > nightmare_delay, "difficulty makes CPU reaction progressively faster")
	_check(easy_read < normal_read and normal_read < hard_read and hard_read <= nightmare_read, "difficulty increases pattern-read strength without stat buffs")
	ai.setup("davi_relampago", "invalid")
	_check(ai.difficulty == "normal", "unknown CPU difficulty safely falls back to normal")
	_check(is_equal_approx(ai.get_reaction_delay(), normal_delay), "fallback uses normal reaction profile")
	ai.queue_free()

	var hud = CombatDeckHUDScript.new()
	_check(hud.hotkey_index_from_keycode(KEY_1) == 0, "keyboard 1 maps to first combat card")
	_check(hud.hotkey_index_from_keycode(KEY_6) == 5, "keyboard 6 maps to sixth combat card")
	_check(hud.hotkey_index_from_keycode(KEY_7) == -1, "unmapped keyboard key does not trigger a card")
	hud.queue_free()


func _test_scene_input_lock() -> void:
	_prepare()
	cm.is_running = false
	var arena_scene: PackedScene = load("res://scenes/combat/CombatArenaBase.tscn")
	var arena = arena_scene.instantiate()
	root.add_child(arena)
	await process_frame
	arena.ai_turn_delay = 0.05
	arena.defense_window_seconds = 0.05
	arena._execute_player_action("baiana")
	# A second card event can arrive while the first coroutine awaits Davi.
	arena._on_v2_card_selected("grip_de_ferro")
	_check(arena._turn_in_progress, "arena locks while awaiting rival")
	for button in arena.get_node("CombatDeckHUD").card_buttons:
		_check(button.disabled, "HUD card locked during rival turn")
	await create_timer(0.4).timeout
	var player_actions := 0
	for event in cm.combat_core_v2.action_log:
		if event.get("actor_id") == cm.player_id:
			player_actions += 1
	_check(player_actions == 1, "rapid inputs produce one player action")
	_check(not arena._turn_in_progress, "input unlocks after rival turn")
	cm.is_running = false
	arena.queue_free()
	await process_frame
