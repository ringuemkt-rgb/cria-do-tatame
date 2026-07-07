extends Node
class_name ScoringSystem

var score := {
	"player": 0,
	"rival": 0,
	"player_advantages": 0,
	"rival_advantages": 0,
	"player_penalties": 0,
	"rival_penalties": 0
}

func reset() -> void:
	score = {
		"player": 0,
		"rival": 0,
		"player_advantages": 0,
		"rival_advantages": 0,
		"player_penalties": 0,
		"rival_penalties": 0
	}

func apply_event(side: String, event_id: String) -> Dictionary:
	var points := _points_for(event_id)
	if points > 0:
		score[side] = int(score.get(side, 0)) + points
	elif event_id == "vantagem":
		score[side + "_advantages"] = int(score.get(side + "_advantages", 0)) + 1
	elif event_id == "punicao":
		score[side + "_penalties"] = int(score.get(side + "_penalties", 0)) + 1
	return score

func _points_for(event_id: String) -> int:
	match event_id:
		"queda_limpa": return 2
		"raspagem": return 2
		"passagem": return 3
		"montada": return 4
		"costas_com_ganchos": return 4
		_: return 0

func get_winner_if_time_ends() -> String:
	if int(score["player"]) > int(score["rival"]):
		return "player"
	if int(score["rival"]) > int(score["player"]):
		return "rival"
	if int(score["player_advantages"]) > int(score["rival_advantages"]):
		return "player"
	if int(score["rival_advantages"]) > int(score["player_advantages"]):
		return "rival"
	return "draw"
