extends Node

enum CombatPhase { DISTANCE, GRIP, CLINCH, TAKEDOWN, GROUND, TRANSITION, TECHNICAL, RESET }

var phase := CombatPhase.DISTANCE
var arena_id := ""
var player_id := "ruan_macacao"
var opponent_id := "davi_relampago"
var fighters := {}
var is_running := false
var last_result := {}
var state_machine: CombatStateMachine

func _ready():
	state_machine = CombatStateMachine.new()
	add_child(state_machine)

func start_combat(new_arena_id: String, new_player_id: String, new_opponent_id: String):
	arena_id = new_arena_id
	player_id = new_player_id
	opponent_id = new_opponent_id
	phase = CombatPhase.DISTANCE
	is_running = true
	fighters = {
		player_id: _create_runtime_stats(player_id),
		opponent_id: _create_runtime_stats(opponent_id)
	}
	state_machine.transition_to(CombatStateMachine.CombatState.STANDING_NEUTRAL)
	SignalBus.combat_started.emit(arena_id, player_id, opponent_id)
	_emit_resources()

func _create_runtime_stats(character_id: String):
	var base = DataRegistry.characters.get(character_id, {})
	var stats = base.get("stats", {})
	return {
		"health": stats.get("health", 100),
		"gas": stats.get("gas", 70),
		"focus": stats.get("focus", 50),
		"grip": stats.get("grip", 50),
		"grip_integrity": 100,
		"control": stats.get("control", 50),
		"moral": stats.get("moral", 50)
	}

func apply_player_action(action_id: String):
	if not is_running:
		return {}
	var technique = DataRegistry.get_technique(action_id)
	if technique.is_empty():
		return _apply_simple_action(action_id)
	return execute_technique(player_id, opponent_id, technique)

func execute_technique(actor_id: String, defender_id: String, technique: Dictionary):
	SignalBus.technique_started.emit(technique.get("id", "unknown"), actor_id)
	var actor = fighters.get(actor_id, {})
	var defender = fighters.get(defender_id, {})
	var gas_cost = int(technique.get("gas_cost", 5))
	var focus_cost = int(technique.get("focus_cost", 2))
	_adjust(actor_id, "gas", -gas_cost)
	_adjust(actor_id, "focus", -focus_cost)
	var grip_damage = int(technique.get("grip_damage", 4))
	if actor_id == player_id and technique.get("uses_silverback_grip", false):
		grip_damage = int(round(float(grip_damage) * 1.15))
	_adjust(defender_id, "grip_integrity", -grip_damage)
	var control_gain = int(technique.get("control_gain", 5))
	_adjust(actor_id, "control", control_gain)
	var success = _calculate_success(actor, defender, technique)
	if success:
		_change_phase(_phase_from_string(technique.get("phase_to", "TRANSITION")))
	else:
		_adjust(defender_id, "focus", 2)
	last_result = {
		"technique_id": technique.get("id", "unknown"),
		"actor_id": actor_id,
		"defender_id": defender_id,
		"success": success,
		"phase": CombatPhase.keys()[phase],
		"fighters": fighters
	}
	SignalBus.technique_resolved.emit(last_result)
	_emit_resources()
	_check_end()
	return last_result

func _calculate_success(actor: Dictionary, defender: Dictionary, technique: Dictionary) -> bool:
	var base_chance = float(technique.get("base_chance", 0.55))
	base_chance += (float(actor.get("focus", 50)) - 50.0) * 0.004
	base_chance += (float(actor.get("control", 50)) - 50.0) * 0.004
	base_chance -= (float(defender.get("focus", 50)) - 50.0) * 0.003
	return randf() <= clamp(base_chance, 0.05, 0.95)

func _apply_simple_action(action_id: String):
	match action_id:
		"grip":
			_change_phase(CombatPhase.GRIP)
			_adjust(player_id, "control", 4)
			_adjust(opponent_id, "grip_integrity", -4)
		"defense":
			_adjust(player_id, "focus", 3)
			_adjust(player_id, "gas", -2)
		"transition":
			_change_phase(CombatPhase.TRANSITION)
			_adjust(player_id, "control", 5)
			_adjust(player_id, "gas", -5)
		"pressure":
			_adjust(player_id, "control", 6)
			_adjust(opponent_id, "gas", -5)
			_adjust(opponent_id, "focus", -3)
		"technical":
			_change_phase(CombatPhase.TECHNICAL)
			_adjust(player_id, "gas", -8)
			_try_finish()
	_emit_resources()
	_check_end()
	return {"action_id": action_id, "phase": CombatPhase.keys()[phase], "fighters": fighters}

func _try_finish():
	var p = fighters[player_id]
	if p.control >= 70 and p.focus >= 35:
		finish_combat({"winner": player_id, "method": "encerramento_tecnico"})

func _adjust(id: String, key: String, delta: int):
	fighters[id][key] = clamp(fighters[id].get(key, 0) + delta, 0, 100)
	if key == "grip_integrity" and fighters[id][key] <= 0:
		SignalBus.grip_integrity_broken.emit(StringName(id))

func _change_phase(new_phase):
	var old_name = CombatPhase.keys()[phase]
	phase = new_phase
	SignalBus.combat_state_changed.emit(old_name, CombatPhase.keys()[phase])

func _phase_from_string(value: String):
	var upper = value.to_upper()
	for i in CombatPhase.keys().size():
		if CombatPhase.keys()[i] == upper:
			return i
	return CombatPhase.TRANSITION

func _check_end():
	if fighters[opponent_id].gas <= 0 and fighters[player_id].control >= 65:
		finish_combat({"winner": player_id, "method": "controle_posicional"})
	elif fighters[player_id].gas <= 0:
		finish_combat({"winner": opponent_id, "method": "cansaco"})

func finish_combat(result: Dictionary):
	is_running = false
	phase = CombatPhase.RESET
	SignalBus.combat_finished.emit(result)

func _emit_resources():
	for id in fighters.keys():
		SignalBus.resources_changed.emit(id, fighters[id])
