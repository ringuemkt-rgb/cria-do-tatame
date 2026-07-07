extends Node
class_name RivalAIController

var rival_id: String = "davi_relampago"
var gameplan: Dictionary = {}
var memory_manager: RivalMemoryManager

func setup(p_rival_id: String, p_gameplan: Dictionary, p_memory_manager: RivalMemoryManager = null) -> void:
	rival_id = p_rival_id
	gameplan = p_gameplan
	memory_manager = p_memory_manager

func choose_action(context: Dictionary) -> Dictionary:
	var state := str(context.get("state", "distancia_media"))
	var options: Array = gameplan.get("state_actions", {}).get(state, [])
	if options.is_empty():
		return {"action": "defesa", "technique_id": "base", "intent": "survive"}
	var best: Dictionary = options[0]
	var best_score := -999.0
	for option in options:
		var score := float(option.get("weight", 1.0))
		var tech_id := str(option.get("technique_id", ""))
		if memory_manager != null:
			score += memory_manager.get_counter_bias(rival_id, tech_id)
		if score > best_score:
			best_score = score
			best = option
	return best

func record_player_pattern(technique_id: String) -> void:
	if memory_manager != null:
		memory_manager.record_pattern(rival_id, technique_id)
