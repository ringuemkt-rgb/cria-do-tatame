extends Node

enum CombatPhase { DISTANCE, GRIP, CLINCH, TAKEDOWN, GROUND, TRANSITION, TECHNICAL, RESET }

const DEFAULT_PLAYER_ID: String = "ruan_macacao"
const DEFAULT_OPPONENT_ID: String = "davi_relampago"
const CombatStateMachineScript = preload("res://src/combat/CombatStateMachine.gd")
const TechniqueResolverScript = preload("res://src/combat/TechniqueResolver.gd")
const TechniqueClashResolverScript = preload("res://src/combat/TechniqueClashResolver.gd")
const FrameDataSystemScript = preload("res://src/combat/FrameDataSystem.gd")
const CombatCoreV2CoordinatorScript = preload("res://src/combat/CombatCoreV2Coordinator.gd")

const STATE_MIRROR := {
	"PLAYER_STANDING_NEUTRAL": "PLAYER_STANDING_NEUTRAL",
	"PLAYER_TOP_CLINCH": "PLAYER_BOTTOM_CLINCH",
	"PLAYER_BOTTOM_CLINCH": "PLAYER_TOP_CLINCH",
	"PLAYER_TOP_GUARD": "PLAYER_BOTTOM_GUARD",
	"PLAYER_BOTTOM_GUARD": "PLAYER_TOP_GUARD",
	"PLAYER_TOP_SIDE": "PLAYER_BOTTOM_SIDE",
	"PLAYER_BOTTOM_SIDE": "PLAYER_TOP_SIDE",
	"PLAYER_TOP_MOUNT": "PLAYER_BOTTOM_MOUNT",
	"PLAYER_BOTTOM_MOUNT": "PLAYER_TOP_MOUNT",
	"PLAYER_BACK_ATTACK": "PLAYER_BACK_DEFENSE",
	"PLAYER_BACK_DEFENSE": "PLAYER_BACK_ATTACK",
	"PLAYER_SUBMISSION_ATTACK": "PLAYER_SUBMISSION_DEFENSE",
	"PLAYER_SUBMISSION_DEFENSE": "PLAYER_SUBMISSION_ATTACK",
	"RESET": "RESET"
}

var phase: int = CombatPhase.DISTANCE
var arena_id: String = ""
var player_id: String = DEFAULT_PLAYER_ID
var opponent_id: String = DEFAULT_OPPONENT_ID
var fighters: Dictionary = {}
var is_running: bool = false
var last_result: Dictionary = {}
var state_machine: Node
var technique_resolver: Node
var clash_resolver: Node
var frame_data_system: Node
var combat_core_v2
var combat_v2_timer_remaining: float = 0.0
var combat_v2_overtime := false
var combat_v2_timer_expired_once := false

func _ready() -> void:
	_ensure_runtime_components()

func _ensure_runtime_components() -> void:
	if state_machine == null:
		state_machine = CombatStateMachineScript.new()
		state_machine.name = "CombatStateMachineRuntime"
		add_child(state_machine)
	if technique_resolver == null:
		technique_resolver = TechniqueResolverScript.new()
		technique_resolver.name = "TechniqueResolverRuntime"
		add_child(technique_resolver)
	if clash_resolver == null:
		clash_resolver = TechniqueClashResolverScript.new()
		clash_resolver.name = "TechniqueClashResolverRuntime"
		add_child(clash_resolver)
	if frame_data_system == null:
		frame_data_system = FrameDataSystemScript.new()
		frame_data_system.name = "FrameDataSystemRuntime"
		add_child(frame_data_system)
	_ensure_combat_core_v2()

func start_combat(new_arena_id: String, new_player_id: String, new_opponent_id: String) -> Dictionary:
	_ensure_runtime_components()
	arena_id = new_arena_id if new_arena_id != "" else "terreiro_da_luta"
	player_id = new_player_id if new_player_id != "" else DEFAULT_PLAYER_ID
	opponent_id = new_opponent_id if new_opponent_id != "" else DEFAULT_OPPONENT_ID
	phase = CombatPhase.DISTANCE
	is_running = true
	last_result = {}
	fighters = {
		player_id: _create_runtime_stats(player_id),
		opponent_id: _create_runtime_stats(opponent_id)
	}
	state_machine.call("reiniciar_em_pe")
	if _combat_v2_active():
		var begin_v2: Dictionary = combat_core_v2.begin_fight()
		if not bool(begin_v2.get("ok", false)):
			return {"ok": false, "error": begin_v2.get("reason", "combat_v2_begin_failed")}
		combat_v2_timer_remaining = float(begin_v2.get("timer_sec", 0))
		combat_v2_overtime = false
		combat_v2_timer_expired_once = false
		SignalBus.combat_v2_hand_changed.emit(begin_v2.get("hand", []).duplicate())
	else:
		if has_node("/root/DeckManager"):
			DeckManager.start_combat_hand()
	SignalBus.combat_started.emit(arena_id, player_id, opponent_id)
	if SignalBus.has_signal("combate_iniciado"):
		SignalBus.combate_iniciado.emit(StringName(opponent_id))
	_emit_resources()
	return {
		"ok": true,
		"arena_id": arena_id,
		"player_id": player_id,
		"opponent_id": opponent_id,
		"state": get_current_state_name(),
		"fighters": fighters
	}

func iniciar_combate(id_jogador: String, id_oponente: String, arena: String) -> void:
	start_combat(arena, id_jogador, id_oponente)

func _create_runtime_stats(character_id: String) -> Dictionary:
	var base: Dictionary = DataRegistry.characters.get(character_id, {})
	var stats: Dictionary = base.get("stats", {})
	return {
		"health": float(stats.get("health", stats.get("hp", 100))),
		"gas": float(stats.get("gas", 70)),
		"focus": float(stats.get("focus", 50)),
		"grip": float(stats.get("grip", stats.get("grip_strength", 50))),
		"guard": float(stats.get("guard", 100)),
		"grip_integrity": 100.0,
		"control": float(stats.get("control", stats.get("technique", 50))),
		"moral": float(stats.get("moral", 50)),
		"score": 0
	}

func get_current_state_name() -> String:
	if state_machine == null:
		return "PLAYER_STANDING_NEUTRAL"
	return str(state_machine.call("get_current_state_name"))

func get_actor_state_name(actor_id: String) -> String:
	var player_perspective := get_current_state_name()
	if actor_id == player_id:
		return player_perspective
	return _mirror_state(player_perspective)

func _mirror_state(state_name: String) -> String:
	return str(STATE_MIRROR.get(state_name, state_name))

func _state_to_player_perspective(actor_id: String, actor_state_name: String) -> String:
	if actor_id == player_id:
		return actor_state_name
	return _mirror_state(actor_state_name)

func get_available_techniques(actor_id: String = "") -> Array:
	var resolved_actor: String = actor_id if actor_id != "" else player_id
	var actor: Dictionary = fighters.get(resolved_actor, {})
	var actor_state: String = get_actor_state_name(resolved_actor)
	var available: Array = []
	for technique_value in DataRegistry.techniques.values():
		if typeof(technique_value) != TYPE_DICTIONARY:
			continue
		var technique: Dictionary = technique_value
		var entry_state: String = str(technique.get("entry_state", technique.get("estado_entrada", "")))
		if entry_state != "" and entry_state != actor_state:
			continue
		var owner: String = str(technique.get("dono", technique.get("owner", "qualquer")))
		if owner != "" and owner != "qualquer" and owner != resolved_actor:
			continue
		var cost: Dictionary = technique.get("cost", technique.get("custo", {}))
		var gas_cost: float = float(cost.get("gas", technique.get("gas_cost", 0)))
		var focus_cost: float = float(cost.get("focus", cost.get("foco", technique.get("focus_cost", 0))))
		var moral_cost: float = float(cost.get("moral", technique.get("moral_cost", 0)))
		var item: Dictionary = technique.duplicate(true)
		item["affordable"] = (
			float(actor.get("gas", 0)) >= gas_cost
			and float(actor.get("focus", 0)) >= focus_cost
			and float(actor.get("moral", 0)) >= moral_cost
		)
		item["actor_state"] = actor_state
		if resolved_actor == player_id and _combat_v2_active():
			var v2_available: bool = bool(combat_core_v2.card_available(str(technique.get("id", ""))))
			item["deck_card_available"] = v2_available
			item["deck_card_level"] = 1
			item["deck_card_id"] = str(technique.get("id", ""))
			if not v2_available:
				continue
		elif resolved_actor == player_id and has_node("/root/DeckManager"):
			var card: Dictionary = DeckManager.get_attack_card(str(technique.get("id", "")), actor, actor_state)
			item["deck_card_available"] = not card.is_empty()
			item["deck_card_level"] = int(card.get("level", 0))
			item["deck_card_id"] = str(card.get("id", ""))
		available.append(item)
	available.sort_custom(_sort_techniques_by_name)
	return available

func _sort_techniques_by_name(a: Dictionary, b: Dictionary) -> bool:
	var name_a: String = str(a.get("nome", a.get("name", a.get("id", ""))))
	var name_b: String = str(b.get("nome", b.get("name", b.get("id", ""))))
	return name_a < name_b

func apply_player_action(action_id: String) -> Dictionary:
	if not is_running:
		return {"success": false, "error": "combat_not_running", "action_id": action_id}
	if action_id == "reset_position":
		state_machine.call("reiniciar_em_pe")
		_change_phase(CombatPhase.RESET)
		_adjust(player_id, "gas", -3.0)
		var reset_result: Dictionary = {
			"action_id": action_id,
			"technique_id": action_id,
			"actor_id": player_id,
			"defender_id": opponent_id,
			"success": true,
			"message": "Posicao reiniciada com seguranca.",
			"phase": CombatPhase.keys()[phase],
			"state_to": get_current_state_name(),
			"fighters": fighters
		}
		last_result = reset_result
		SignalBus.technique_resolved.emit(reset_result)
		_emit_resources()
		return reset_result
	if _combat_v2_active() and not combat_core_v2.card_available(action_id):
		return {"success": false, "error": "deck_card_not_in_hand", "action_id": action_id, "hand": combat_core_v2.deck_runtime.hand.duplicate()}
	return apply_actor_action(player_id, action_id)

func apply_opponent_action(action_id: String) -> Dictionary:
	return apply_actor_action(opponent_id, action_id)

func apply_actor_action(actor_id: String, action_id: String) -> Dictionary:
	if not is_running:
		return {"success": false, "error": "combat_not_running", "action_id": action_id}
	var defender_id := opponent_id if actor_id == player_id else player_id
	var technique: Dictionary = DataRegistry.get_technique(action_id)
	if technique.is_empty():
		return {
			"success": false,
			"error": "technique_not_found",
			"action_id": action_id,
			"actor_id": actor_id,
			"defender_id": defender_id,
			"message": "Tecnica nao encontrada no catalogo."
		}
	return execute_technique(actor_id, defender_id, technique)

func execute_technique(actor_id: String, defender_id: String, technique: Dictionary) -> Dictionary:
	if not fighters.has(actor_id) or not fighters.has(defender_id):
		return {"success": false, "error": "fighter_not_found", "technique_id": technique.get("id", "unknown")}
	SignalBus.technique_started.emit(technique.get("id", "unknown"), actor_id)
	var player_state_before: String = get_current_state_name()
	var actor_state_before: String = get_actor_state_name(actor_id)
	var actor: Dictionary = fighters.get(actor_id, {})
	var defender: Dictionary = fighters.get(defender_id, {})
	var card_context := _build_card_context(actor_id, defender_id, technique, actor, defender, actor_state_before)
	var resolver_result: Dictionary = technique_resolver.call(
		"resolve_technique",
		technique,
		actor,
		defender,
		card_context
	)
	var applied: Dictionary = technique_resolver.call("aplicar_resultado", actor, defender, resolver_result)
	fighters[actor_id] = applied.get("actor", actor)
	fighters[defender_id] = applied.get("defender", defender)
	_apply_card_activation_cost(actor_id, card_context.get("attack_card", {}))
	if actor_id == player_id and _combat_v2_active():
		var next_hand: Array = combat_core_v2.consume_card(str(technique.get("id", "")))
		SignalBus.combat_v2_hand_changed.emit(next_hand)
	elif has_node("/root/DeckManager") and actor_id == player_id:
		DeckManager.consume_used_card(str(card_context.get("attack_card", {}).get("id", "")), bool(resolver_result.get("success", false)))

	last_result = resolver_result.duplicate(true)
	last_result["actor_id"] = actor_id
	last_result["defender_id"] = defender_id
	last_result["state_from"] = player_state_before
	last_result["actor_state_from"] = actor_state_before
	if _combat_v2_active():
		combat_core_v2.append_action({
			"technique_id": str(technique.get("id", "")),
			"actor_id": actor_id,
			"success": bool(resolver_result.get("success", false)),
			"denied": bool(resolver_result.get("denied", false)),
			"state_from": player_state_before,
			"state_to": str(resolver_result.get("state_to", player_state_before))
		})
		if actor_id == opponent_id:
			var observed: Dictionary = combat_core_v2.observe_technique(str(technique.get("id", "")))
			if bool(observed.get("counter_suggestion_unlocked", false)):
				SignalBus.combat_corner_suggestion.emit(get_corner_suggestion())

	if _resolve_finisher_before_transition(actor_id, defender_id, technique, last_result, actor_state_before):
		last_result["phase"] = CombatPhase.keys()[phase]
		last_result["combat_state"] = player_state_before
		last_result["fighters"] = fighters
		SignalBus.technique_resolved.emit(last_result)
		_emit_resources()
		var finish_result: Dictionary = {
			"winner": actor_id,
			"loser": defender_id,
			"method": str(technique.get("id", "encerramento_tecnico")),
			"technical": true,
			"technique_id": str(technique.get("id", "encerramento_tecnico")),
			"state_from": player_state_before,
			"actor_state_from": actor_state_before
		}
		finish_combat(finish_result)
		return last_result

	if bool(resolver_result.get("success", false)):
		var actor_state_to := str(resolver_result.get("state_to", actor_state_before))
		var player_state_to := _state_to_player_perspective(actor_id, actor_state_to)
		last_result["actor_state_to"] = actor_state_to
		last_result["state_to"] = player_state_to
		_apply_state_transition(player_state_to)
		_change_phase(_phase_from_string(str(technique.get("phase_to", "TRANSITION"))))
	else:
		_adjust(defender_id, "focus", 2.0)

	last_result["phase"] = CombatPhase.keys()[phase]
	last_result["combat_state"] = get_current_state_name()
	last_result["fighters"] = fighters
	SignalBus.technique_resolved.emit(last_result)
	_emit_resources()
	_check_end(actor_id, defender_id, technique, last_result)
	return last_result

func _build_card_context(
	actor_id: String,
	defender_id: String,
	technique: Dictionary,
	actor: Dictionary,
	defender: Dictionary,
	actor_state: String
) -> Dictionary:
	var context: Dictionary = {"state": actor_state, "input_quality": 0.5, "defense_timing": 0.5}
	if _combat_v2_active() and actor_id == player_id:
		var synthetic_card := {
			"id": "v2_%s" % str(technique.get("id", "")),
			"name": technique.get("nome", technique.get("name", technique.get("id", ""))),
			"technique_id": technique.get("id", ""),
			"level": 1,
			"base_power": 10.0,
			"activation_cost": {}
		}
		context["attack_card"] = synthetic_card
		context["defense_card"] = clash_resolver.call("build_baseline_defense", technique, defender)
		context["deck_clash"] = {}
		context["chance_modifier"] = 0.0
		context["frame_data"] = {}
		return context
	if not has_node("/root/DeckManager"):
		return context
	var technique_id := str(technique.get("id", ""))
	var family := str(technique.get("family", technique.get("familia", "geral")))
	var attack_card: Dictionary = {}
	if actor_id == player_id:
		attack_card = DeckManager.get_attack_card(technique_id, actor, actor_state)
		if not attack_card.is_empty() and not _can_pay_technique_and_card(actor, technique, attack_card):
			attack_card = {}
	else:
		attack_card = _build_opponent_technique_card(technique, actor)
	var defender_state := get_actor_state_name(defender_id)
	var defense_card: Dictionary = {}
	if defender_id == player_id:
		defense_card = DeckManager.get_defense_card(family, defender, defender_state)
	if defense_card.is_empty():
		defense_card = clash_resolver.call("build_baseline_defense", technique, defender)
	var clash: Dictionary = clash_resolver.call(
		"resolve_clash", attack_card, defense_card, actor, defender, technique, context
	)
	var frame_data: Dictionary = frame_data_system.call("apply_level_clash", {}, clash, technique)
	context["attack_card"] = attack_card
	context["defense_card"] = defense_card
	context["deck_clash"] = clash
	context["chance_modifier"] = float(clash.get("chance_modifier", 0.0))
	context["frame_data"] = frame_data
	if bool(clash.get("enabled", false)):
		SignalBus.technique_clash_resolved.emit(clash.duplicate(true))
	return context

func _build_opponent_technique_card(technique: Dictionary, actor: Dictionary) -> Dictionary:
	var level := clampi(1 + int(float(actor.get("control", 50.0)) / 35.0), 1, 3)
	return {
		"id": "rival_card_%s" % str(technique.get("id", "technique")),
		"name": technique.get("nome", technique.get("name", "Tecnica rival")),
		"technique_id": technique.get("id", ""),
		"level": level,
		"base_power": 9.0,
		"activation_cost": {}
	}

func _apply_card_activation_cost(actor_id: String, card: Dictionary) -> void:
	if card.is_empty():
		return
	var cost: Dictionary = card.get("activation_cost", {})
	_adjust(actor_id, "focus", -float(cost.get("focus", 0.0)))
	_adjust(actor_id, "gas", -float(cost.get("gas", 0.0)))

func _can_pay_technique_and_card(actor: Dictionary, technique: Dictionary, card: Dictionary) -> bool:
	var technique_cost: Dictionary = technique.get("cost", technique.get("custo", {}))
	var card_cost: Dictionary = card.get("activation_cost", {})
	var gas_total := float(technique_cost.get("gas", 0.0)) + float(card_cost.get("gas", 0.0))
	var focus_total := float(technique_cost.get("focus", technique_cost.get("foco", 0.0))) + float(card_cost.get("focus", 0.0))
	return float(actor.get("gas", 0.0)) >= gas_total and float(actor.get("focus", 0.0)) >= focus_total

func _resolve_finisher_before_transition(
	actor_id: String,
	defender_id: String,
	technique: Dictionary,
	result: Dictionary,
	actor_state_before: String
) -> bool:
	if not is_running:
		return false
	if not bool(result.get("success", false)):
		return false
	if not bool(technique.get("requer_finalizacao", false)):
		return false
	if actor_state_before != "PLAYER_SUBMISSION_ATTACK":
		return false
	var actor: Dictionary = fighters.get(actor_id, {})
	var defender: Dictionary = fighters.get(defender_id, {})
	return float(actor.get("control", 0)) >= 55.0 or float(defender.get("health", 100)) <= 70.0

func _apply_state_transition(state_name: String) -> void:
	var target_state: int = int(state_machine.call("estado_por_nome", state_name))
	var current_state: int = int(state_machine.get("current_state"))
	if target_state == current_state:
		return
	var transitioned: bool = bool(state_machine.call("transition_to", target_state))
	if not transitioned:
		push_warning("[CombatManager] Transicao nao catalogada: %s -> %s" % [get_current_state_name(), state_name])
		state_machine.call("forcar_estado", target_state)

func _check_end(actor_id: String, defender_id: String, technique: Dictionary = {}, result: Dictionary = {}) -> void:
	if not is_running:
		return
	var actor: Dictionary = fighters.get(actor_id, {})
	var defender: Dictionary = fighters.get(defender_id, {})
	if float(defender.get("health", 100)) <= 0.0:
		finish_combat({
			"winner": actor_id,
			"loser": defender_id,
			"method": str(technique.get("id", "encerramento_tecnico")),
			"technical": true
		})
	elif float(defender.get("gas", 100)) <= 0.0 and float(actor.get("control", 0)) >= 65.0:
		finish_combat({
			"winner": actor_id,
			"loser": defender_id,
			"method": "controle_posicional",
			"technical": true
		})
	elif float(actor.get("gas", 100)) <= 0.0:
		finish_combat({
			"winner": defender_id,
			"loser": actor_id,
			"method": "cansaco",
			"technical": false
		})

func _adjust(id: String, key: String, delta: float) -> void:
	if not fighters.has(id):
		return
	fighters[id][key] = clampf(float(fighters[id].get(key, 0.0)) + delta, 0.0, 100.0)
	if key == "grip_integrity" and float(fighters[id][key]) <= 0.0:
		SignalBus.grip_integrity_broken.emit(StringName(id))

func _change_phase(new_phase: int) -> void:
	var old_name: String = str(CombatPhase.keys()[phase])
	phase = clampi(new_phase, 0, CombatPhase.keys().size() - 1)
	var new_name: String = str(CombatPhase.keys()[phase])
	SignalBus.combat_state_changed.emit(old_name, new_name)
	if SignalBus.has_signal("estado_combate_mudou"):
		SignalBus.estado_combate_mudou.emit(StringName(new_name), StringName(old_name))

func _phase_from_string(value: String) -> int:
	var upper: String = value.to_upper()
	var keys: Array = CombatPhase.keys()
	for i in range(keys.size()):
		if str(keys[i]) == upper:
			return i
	return CombatPhase.TRANSITION

func finish_combat(result: Dictionary) -> void:
	if not is_running:
		return
	is_running = false
	phase = CombatPhase.RESET
	last_result = combat_core_v2.finish_result(result) if _combat_v2_active() else result.duplicate(true)
	last_result["fighters"] = fighters.duplicate(true)
	last_result["final_state"] = get_current_state_name()
	_apply_post_combat_effects(last_result)
	state_machine.call("reset")
	SignalBus.combat_finished.emit(last_result)
	SignalBus.combat_ended.emit(last_result)
	if _combat_v2_active():
		SignalBus.combat_clip_candidate.emit(last_result.duplicate(true))
	if SignalBus.has_signal("combate_finalizado"):
		SignalBus.combate_finalizado.emit(last_result)

func finalizar_combate(result: Dictionary) -> void:
	finish_combat(result)

func _apply_post_combat_effects(result: Dictionary) -> void:
	WorldState.last_combat_result = result
	if result.get("winner", "") == player_id:
		WorldState.fights_won += 1
		WorldState.money += 200
		WorldState.modify_reputation("honra", 5.0)
		WorldState.modify_reputation("hype", 3.0)
		if bool(result.get("technical", false)):
			WorldState.technical_finishes += 1
	else:
		WorldState.fights_lost += 1
		WorldState.modify_reputation("honra", -3.0)
		WorldState.modify_reputation("hype", -2.0)
	WorldState._sync_aliases()

func _emit_resources() -> void:
	for fighter_value in fighters.keys():
		var fighter_id: String = str(fighter_value)
		var resources: Dictionary = fighters[fighter_id]
		SignalBus.resources_changed.emit(fighter_id, resources.duplicate(true))
		for resource_value in resources.keys():
			var resource_name: String = str(resource_value)
			if SignalBus.has_signal("recurso_mudou"):
				SignalBus.recurso_mudou.emit(StringName(fighter_id), StringName(resource_name), float(resources[resource_name]), 100.0)


func prepare_combat_v2(
	new_opponent_id: String,
	new_arena_id: String,
	ruleset: String,
	gi: bool,
	selection: Array = [],
	seed: int = 0,
	social_state: Dictionary = {}
) -> Dictionary:
	_ensure_combat_core_v2()
	if combat_core_v2 == null:
		return {"ok": false, "error": "combat_core_v2_unavailable"}
	if not has_node("/root/DeckManager"):
		return {"ok": false, "error": "deck_manager_missing"}
	var available: Array = DeckManager.get_unlocked_technique_ids()
	var chosen: Array = selection.duplicate()
	if chosen.is_empty():
		var adaptive: Array = DeckManager.get_v2_preset("adaptativo")
		chosen = adaptive if not adaptive.is_empty() else DeckManager.get_default_v2_selection()
	if seed == 0:
		seed = _combat_v2_seed(new_opponent_id, new_arena_id)
	var social := social_state.duplicate(true)
	if social.is_empty() and has_node("/root/CriaLiveInteractionManager") and CriaLiveInteractionManager.has_method("get_v1_state"):
		social = CriaLiveInteractionManager.get_v1_state()
	return combat_core_v2.build_pre_fight_plan(
		new_opponent_id,
		available,
		chosen,
		social,
		seed,
		ruleset,
		gi,
		new_arena_id
	)

func get_pre_fight_plan_v2() -> Dictionary:
	_ensure_combat_core_v2()
	return combat_core_v2.current_plan.duplicate(true) if combat_core_v2 != null else {}

func get_corner_suggestion() -> Dictionary:
	if not _combat_v2_active():
		return {}
	var suggestion: Dictionary = combat_core_v2.corner_suggestion(get_combat_state_v2())
	if not suggestion.is_empty():
		SignalBus.combat_corner_suggestion.emit(suggestion.duplicate(true))
	return suggestion

func activate_virada_do_cria(player: int = 1) -> Dictionary:
	if not _combat_v2_active():
		return {"ok": false, "reason": "combat_v2_not_active"}
	var result: Dictionary = combat_core_v2.activate_virada(get_combat_state_v2(), player)
	if not bool(result.get("ok", false)):
		return result
	var fighter_id := player_id if player == 1 else opponent_id
	for key_value in result.get("resource_delta", {}).keys():
		_adjust(fighter_id, str(key_value), float(result["resource_delta"][key_value]))
	_emit_resources()
	SignalBus.combat_virada_used.emit(player, result.duplicate(true))
	return result

func get_combat_state_v2() -> Dictionary:
	var p1: Dictionary = fighters.get(player_id, {})
	var p2: Dictionary = fighters.get(opponent_id, {})
	var plan: Dictionary = combat_core_v2.current_plan if _combat_v2_active() else {}
	return {
		"pos": get_current_state_name(),
		"top": 0,
		"gi": bool(plan.get("gi", true)),
		"ruleset": str(plan.get("ruleset", "ibjjf")),
		"seed": int(plan.get("seed", 0)),
		"tick": combat_core_v2.action_log.size() if _combat_v2_active() else 0,
		"winner": 0,
		"timer": maxi(0, int(ceil(combat_v2_timer_remaining))),
		"overtime": combat_v2_overtime,
		"p1": _fighter_state_v2(p1),
		"p2": _fighter_state_v2(p2),
		"log": combat_core_v2.action_log.duplicate(true) if _combat_v2_active() else [],
		"virada_disponivel": {
			"p1": combat_core_v2.comeback.is_available(1) if _combat_v2_active() else false,
			"p2": combat_core_v2.comeback.is_available(2) if _combat_v2_active() else false
		},
		"nemesis_counters": plan.get("scouting", {}).get("counters_known", []).duplicate()
	}

func tick_combat_timer(delta_sec: float) -> Dictionary:
	if not is_running or not _combat_v2_active():
		return {"active": false}
	if combat_v2_timer_remaining <= 0.0:
		return {"active": true, "expired": combat_v2_timer_expired_once}
	combat_v2_timer_remaining = maxf(0.0, combat_v2_timer_remaining - maxf(0.0, delta_sec))
	SignalBus.combat_timer_changed.emit(int(ceil(combat_v2_timer_remaining)), combat_v2_overtime)
	if combat_v2_timer_remaining > 0.0:
		return {"active": true, "expired": false, "remaining": combat_v2_timer_remaining}
	if combat_v2_timer_expired_once:
		return {"active": true, "expired": true}
	combat_v2_timer_expired_once = true
	var timer_profile: Dictionary = combat_core_v2.current_plan.get("timer_profile", {})
	if bool(timer_profile.get("overtime", false)) and not combat_v2_overtime:
		combat_v2_overtime = true
		combat_v2_timer_expired_once = false
		combat_v2_timer_remaining = float(timer_profile.get("overtime_duration_sec", 0))
		return {"active": true, "overtime_started": true, "remaining": combat_v2_timer_remaining}
	var payload := {
		"ruleset": combat_core_v2.current_plan.get("ruleset", ""),
		"score_p1": int(fighters.get(player_id, {}).get("score", 0)),
		"score_p2": int(fighters.get(opponent_id, {}).get("score", 0)),
		"requires_authoritative_resolution": true
	}
	SignalBus.combat_timer_expired.emit(payload)
	return {"active": true, "expired": true, "payload": payload}

func clear_combat_v2_plan() -> void:
	if combat_core_v2 != null:
		combat_core_v2.clear()
	combat_v2_timer_remaining = 0.0
	combat_v2_overtime = false
	combat_v2_timer_expired_once = false

func _ensure_combat_core_v2() -> void:
	if combat_core_v2 != null:
		return
	combat_core_v2 = CombatCoreV2CoordinatorScript.new()
	var rival_profiles: Dictionary = DataRegistry.rival_ai_profiles.get("profiles", {}) if DataRegistry != null else {}
	combat_core_v2.configure(
		DataRegistry.techniques if DataRegistry != null else {},
		rival_profiles,
		_load_combat_v2_json("res://data/combat/bjj_position_values_v1.json"),
		_load_combat_v2_json("res://data/combat/scouting_profiles_v1.json").get("profiles", {}),
		_load_combat_v2_json("res://data/combat/ruleset_timers_v1.json").get("profiles", {})
	)

func _combat_v2_active() -> bool:
	return combat_core_v2 != null and combat_core_v2.is_active()

func _combat_v2_seed(target_opponent: String, target_arena: String) -> int:
	var week := int(WorldState.week) if has_node("/root/WorldState") else 0
	var text := "%s|%s|%d" % [target_opponent, target_arena, week]
	var value: int = 2166136261
	for index in range(text.length()):
		value = int((value ^ text.unicode_at(index)) * 16777619) & 0x7fffffff
	return maxi(1, value)

func _fighter_state_v2(raw: Dictionary) -> Dictionary:
	return {
		"gas": float(raw.get("gas", 0.0)),
		"score": int(raw.get("score", 0)),
		"grip": _resource_tier(float(raw.get("grip", 0.0))),
		"guard": _resource_tier(float(raw.get("guard", 0.0))),
		"focus": float(raw.get("focus", 0.0)),
		"moral": float(raw.get("moral", 0.0)),
		"health": float(raw.get("health", 0.0))
	}

func _resource_tier(value: float) -> int:
	if value <= 0.0:
		return 0
	if value < 34.0:
		return 1
	if value < 67.0:
		return 2
	return 3

func _load_combat_v2_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

func is_combat_v2_active() -> bool:
	return _combat_v2_active()
