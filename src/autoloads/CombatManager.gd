extends Node

enum CombatPhase { DISTANCE, GRIP, CLINCH, TAKEDOWN, GROUND, TRANSITION, TECHNICAL, RESET }

const DEFAULT_PLAYER_ID: String = "ruan_macacao"
const DEFAULT_OPPONENT_ID: String = "davi_relampago"
const CombatStateMachineScript = preload("res://src/combat/CombatStateMachine.gd")
const TechniqueResolverScript = preload("res://src/combat/TechniqueResolver.gd")

var phase: int = CombatPhase.DISTANCE
var arena_id: String = ""
var player_id: String = DEFAULT_PLAYER_ID
var opponent_id: String = DEFAULT_OPPONENT_ID
var fighters: Dictionary = {}
var is_running: bool = false
var last_result: Dictionary = {}
var state_machine: Node
var technique_resolver: Node

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
		"moral": float(stats.get("moral", 50))
	}

func get_current_state_name() -> String:
	if state_machine == null:
		return "PLAYER_STANDING_NEUTRAL"
	return str(state_machine.call("get_current_state_name"))

func get_available_techniques(actor_id: String = "") -> Array:
	var resolved_actor: String = actor_id if actor_id != "" else player_id
	var actor: Dictionary = fighters.get(resolved_actor, {})
	var current_state: String = get_current_state_name()
	var available: Array = []
	for technique_value in DataRegistry.techniques.values():
		if typeof(technique_value) != TYPE_DICTIONARY:
			continue
		var technique: Dictionary = technique_value
		var entry_state: String = str(technique.get("entry_state", technique.get("estado_entrada", "")))
		if entry_state != "" and entry_state != current_state:
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
	var technique: Dictionary = DataRegistry.get_technique(action_id)
	if technique.is_empty():
		return {
			"success": false,
			"error": "technique_not_found",
			"action_id": action_id,
			"message": "Tecnica nao encontrada no catalogo."
		}
	return execute_technique(player_id, opponent_id, technique)

func execute_technique(actor_id: String, defender_id: String, technique: Dictionary) -> Dictionary:
	if not fighters.has(actor_id) or not fighters.has(defender_id):
		return {"success": false, "error": "fighter_not_found", "technique_id": technique.get("id", "unknown")}
	SignalBus.technique_started.emit(technique.get("id", "unknown"), actor_id)
	var state_before: String = get_current_state_name()
	var actor: Dictionary = fighters.get(actor_id, {})
	var defender: Dictionary = fighters.get(defender_id, {})
	var resolver_result: Dictionary = technique_resolver.call(
		"resolve_technique",
		technique,
		actor,
		defender,
		{"state": state_before}
	)
	var applied: Dictionary = technique_resolver.call("aplicar_resultado", actor, defender, resolver_result)
	fighters[actor_id] = applied.get("actor", actor)
	fighters[defender_id] = applied.get("defender", defender)

	last_result = resolver_result.duplicate(true)
	last_result["actor_id"] = actor_id
	last_result["defender_id"] = defender_id
	last_result["state_from"] = state_before

	if _resolve_finisher_before_transition(actor_id, defender_id, technique, last_result, state_before):
		last_result["phase"] = CombatPhase.keys()[phase]
		last_result["combat_state"] = state_before
		last_result["fighters"] = fighters
		SignalBus.technique_resolved.emit(last_result)
		_emit_resources()
		var finish_result: Dictionary = {
			"winner": actor_id,
			"loser": defender_id,
			"method": str(technique.get("id", "encerramento_tecnico")),
			"technical": true,
			"technique_id": str(technique.get("id", "encerramento_tecnico")),
			"state_from": state_before
		}
		finish_combat(finish_result)
		return last_result

	if bool(resolver_result.get("success", false)):
		_apply_state_transition(str(resolver_result.get("state_to", get_current_state_name())))
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

func _resolve_finisher_before_transition(
	actor_id: String,
	defender_id: String,
	technique: Dictionary,
	result: Dictionary,
	state_before: String
) -> bool:
	if not is_running:
		return false
	if not bool(result.get("success", false)):
		return false
	if not bool(technique.get("requer_finalizacao", false)):
		return false
	if state_before != "PLAYER_SUBMISSION_ATTACK":
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
	last_result = result.duplicate(true)
	last_result["fighters"] = fighters.duplicate(true)
	last_result["final_state"] = get_current_state_name()
	_apply_post_combat_effects(last_result)
	state_machine.call("reset")
	SignalBus.combat_finished.emit(last_result)
	SignalBus.combat_ended.emit(last_result)
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
