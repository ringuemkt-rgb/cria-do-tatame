extends Node

enum CombatPhase { DISTANCE, GRIP, CLINCH, TAKEDOWN, GROUND, TRANSITION, SUBMISSION, RESET }

var phase := CombatPhase.DISTANCE
var arena_id := ""
var player_id := "ruan_macacao"
var opponent_id := "davi_relampago"
var fighters := {}
var is_running := false

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
		"control": stats.get("control", 50),
		"moral": stats.get("moral", 50)
	}

func apply_player_action(action_id: String):
	if not is_running:
		return
	match action_id:
		"grip":
			_change_phase(CombatPhase.GRIP)
			_adjust(player_id, "control", 4)
			_adjust(opponent_id, "grip", -4)
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
		"submission":
			_change_phase(CombatPhase.SUBMISSION)
			_adjust(player_id, "gas", -8)
			_try_finish()
	_emit_resources()
	_check_end()

func _try_finish():
	var p = fighters[player_id]
	if p.control >= 70 and p.focus >= 40:
		finish_combat({"winner": player_id, "method": "technical_submission"})

func _adjust(id: String, key: String, delta: int):
	fighters[id][key] = clamp(fighters[id].get(key, 0) + delta, 0, 100)

func _change_phase(new_phase):
	var old_name = CombatPhase.keys()[phase]
	phase = new_phase
	SignalBus.combat_state_changed.emit(old_name, CombatPhase.keys()[phase])

func _check_end():
	if fighters[opponent_id].gas <= 0 and fighters[player_id].control >= 65:
		finish_combat({"winner": player_id, "method": "control_domination"})
	elif fighters[player_id].gas <= 0:
		finish_combat({"winner": opponent_id, "method": "fatigue"})

func finish_combat(result: Dictionary):
	is_running = false
	phase = CombatPhase.RESET
	SignalBus.combat_finished.emit(result)

func _emit_resources():
	for id in fighters.keys():
		SignalBus.resources_changed.emit(id, fighters[id])
