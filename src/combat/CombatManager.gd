extends Node
class_name CombatSimulationEngine

# Motor instanciavel para testes e simulacoes isoladas.
# O singleton global CombatManager permanece em src/autoloads/CombatManager.gd.

var state_machine: PositionalStateMachine
var technique_resolver: TechniqueResolver
var scoring: ScoringSystem

var player_stats: Dictionary = {}
var opponent_stats: Dictionary = {}

func setup(p_player_stats: Dictionary, p_opponent_stats: Dictionary) -> void:
	state_machine = PositionalStateMachine.new()
	technique_resolver = TechniqueResolver.new()
	scoring = ScoringSystem.new()
	add_child(state_machine)
	add_child(technique_resolver)
	add_child(scoring)
	player_stats = p_player_stats.duplicate(true)
	opponent_stats = p_opponent_stats.duplicate(true)
	state_machine.force_state("distancia_media")
	scoring.reset()

func use_technique(technique: Dictionary, input_context: Dictionary = {}) -> Dictionary:
	if state_machine == null or technique_resolver == null or scoring == null:
		return {"error": "engine_not_initialized", "combat_state": "reset", "score": {}}
	var context := input_context.duplicate(true)
	context["state"] = state_machine.current_state
	var result := technique_resolver.resolve_technique(technique, player_stats, opponent_stats, context)
	var applied := technique_resolver.aplicar_resultado(player_stats, opponent_stats, result)
	player_stats = applied.get("actor", player_stats)
	opponent_stats = applied.get("defender", opponent_stats)
	var next_state := str(result.get("state_to", state_machine.current_state))
	state_machine.force_state(next_state)
	if bool(result.get("success", false)):
		var score_event := str(technique.get("score_event", ""))
		if score_event != "":
			scoring.apply_event("player", score_event)
	return {
		"result": result,
		"combat_state": state_machine.current_state,
		"score": scoring.score,
		"player_stats": player_stats,
		"opponent_stats": opponent_stats
	}
