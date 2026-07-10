extends Node
class_name CombatSimulationEngine

# Motor instanciavel para testes e simulacoes isoladas.
# O singleton global CombatManager permanece em src/autoloads/CombatManager.gd.

const PositionalStateMachineScript = preload("res://src/combat/PositionalStateMachine.gd")
const TechniqueResolverScript = preload("res://src/combat/TechniqueResolver.gd")
const ScoringSystemScript = preload("res://src/combat/ScoringSystem.gd")

var state_machine: Node
var technique_resolver: Node
var scoring: Node

var player_stats: Dictionary = {}
var opponent_stats: Dictionary = {}

func setup(p_player_stats: Dictionary, p_opponent_stats: Dictionary) -> void:
	state_machine = PositionalStateMachineScript.new()
	technique_resolver = TechniqueResolverScript.new()
	scoring = ScoringSystemScript.new()
	add_child(state_machine)
	add_child(technique_resolver)
	add_child(scoring)
	player_stats = p_player_stats.duplicate(true)
	opponent_stats = p_opponent_stats.duplicate(true)
	state_machine.call("force_state", "distancia_media")
	scoring.call("reset")

func use_technique(technique: Dictionary, input_context: Dictionary = {}) -> Dictionary:
	if state_machine == null or technique_resolver == null or scoring == null:
		return {"error": "engine_not_initialized", "combat_state": "reset", "score": {}}
	var context: Dictionary = input_context.duplicate(true)
	context["state"] = str(state_machine.get("current_state"))
	var result: Dictionary = technique_resolver.call("resolve_technique", technique, player_stats, opponent_stats, context)
	var applied: Dictionary = technique_resolver.call("aplicar_resultado", player_stats, opponent_stats, result)
	player_stats = applied.get("actor", player_stats)
	opponent_stats = applied.get("defender", opponent_stats)
	var next_state: String = str(result.get("state_to", state_machine.get("current_state")))
	state_machine.call("force_state", next_state)
	if bool(result.get("success", false)):
		var score_event: String = str(technique.get("score_event", ""))
		if score_event != "":
			scoring.call("apply_event", "player", score_event)
	return {
		"result": result,
		"combat_state": str(state_machine.get("current_state")),
		"score": scoring.get("score"),
		"player_stats": player_stats,
		"opponent_stats": opponent_stats
	}
