extends Node
class_name DaviAIController

var seen_player_actions := {}
var last_action := ""

func reset() -> void:
	seen_player_actions.clear()
	last_action = ""

func record_player_action(action_id: String) -> void:
	seen_player_actions[action_id] = int(seen_player_actions.get(action_id, 0)) + 1
	last_action = action_id

func choose_response(combat_phase: String, player_resources: Dictionary) -> String:
	var gas := float(player_resources.get("gas", 100))
	if _player_is_repeating("baiana"):
		return "sprawl"
	if _player_is_repeating("grip_de_ferro"):
		return "quebra_base"
	if combat_phase == "GROUND" or combat_phase == "TRANSITION":
		return "saida_cem_quilos"
	if gas < 30.0:
		return "pressao_cabeca"
	return "grip_de_ferro"

func pressure_message() -> String:
	if last_action != "" and int(seen_player_actions.get(last_action, 0)) >= 3:
		return "Davi leu a repeticao. Muda o ritmo."
	return "Davi Relampago esta estudando seu jogo."

func _player_is_repeating(action_id: String) -> bool:
	return int(seen_player_actions.get(action_id, 0)) >= 2
