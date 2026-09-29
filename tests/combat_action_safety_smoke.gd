extends SceneTree

const ResolverScript = preload("res://src/combat/TechniqueResolver.gd")
const CoordinatorScript = preload("res://src/combat/CombatCoreV2Coordinator.gd")
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
	_test_runtime_guards()
	_test_seeded_runtime()
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

func _test_scene_input_lock() -> void:
	_prepare()
	cm.is_running = false
	var arena_scene: PackedScene = load("res://scenes/combat/CombatArenaBase.tscn")
	var arena = arena_scene.instantiate()
	root.add_child(arena)
	await process_frame
	arena.ai_turn_delay = 0.05
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
