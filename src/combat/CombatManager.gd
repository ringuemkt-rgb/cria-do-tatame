extends Node
class_name CombatManager

var state_machine: PositionalStateMachine
var technique_resolver: TechniqueResolver
var scoring: ScoringSystem

var player_stats: Dictionary = {}
var opponent_stats: Dictionary = {}

func setup(p_player_stats: Dictionary, p_opponent_stats: Dictionary) -> void:
	state_machine = PositionalStateMachine.new()
	technique_resolver = TechniqueResolver.new()
	scoring = ScoringSystem.new()
	player_stats = p_player_stats
	opponent_stats = p_opponent_stats
	state_machine.force_state("distancia_media")
	scoring.reset()

func use_technique(technique: Dictionary, input_context: Dictionary = {}) -> Dictionary:
	var context := input_context.duplicate(true)
	context["state"] = state_machine.current_state
	var result := technique_resolver.resolve_technique(technique, player_stats, opponent_stats, context)
	var next_state := str(result.get("state_to", "reset"))
	state_machine.force_state(next_state)
	if bool(result.get("success", false)):
		var score_event := str(technique.get("score_event", ""))
		if score_event != "":
			scoring.apply_event("player", score_event)
	return {"result": result, "combat_state": state_machine.current_state, "score": scoring.score}
