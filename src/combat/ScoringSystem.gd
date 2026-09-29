extends Node
class_name ScoringSystem

const EVENT_ALIASES := {
	"queda_limpa": "takedown",
	"takedown_clean": "takedown",
	"takedown": "takedown",
	"raspagem": "sweep",
	"sweep": "sweep",
	"passagem": "guard_pass",
	"guard_pass": "guard_pass",
	"montada": "mount",
	"mount": "mount",
	"costas_com_ganchos": "back_control",
	"back_control": "back_control",
	"vantagem": "advantage",
	"advantage": "advantage",
	"punicao": "penalty",
	"penalty": "penalty"
}

var score := {
	"player": 0,
	"rival": 0,
	"player_advantages": 0,
	"rival_advantages": 0,
	"player_penalties": 0,
	"rival_penalties": 0
}

var pending_events: Array = []

func reset() -> void:
	score = {
		"player": 0,
		"rival": 0,
		"player_advantages": 0,
		"rival_advantages": 0,
		"player_penalties": 0,
		"rival_penalties": 0
	}
	pending_events.clear()

func normalize_event_id(event_id: String) -> String:
	var normalized := event_id.strip_edges().to_lower()
	return str(EVENT_ALIASES.get(normalized, normalized))

func apply_event(side: String, event_id: String) -> Dictionary:
	if side not in ["player", "rival"]:
		return get_score()
	var canonical := normalize_event_id(event_id)
	var points := _points_for(canonical)
	if points > 0:
		score[side] = int(score.get(side, 0)) + points
	elif canonical == "advantage":
		score[side + "_advantages"] = int(score.get(side + "_advantages", 0)) + 1
	elif canonical == "penalty":
		score[side + "_penalties"] = int(score.get(side + "_penalties", 0)) + 1
	return get_score()

func queue_event(
	side: String,
	event_id: String,
	stabilization_seconds: float = 0.0,
	expected_state: String = "",
	technique_id: String = ""
) -> Dictionary:
	var canonical := normalize_event_id(event_id)
	if side not in ["player", "rival"] or canonical == "":
		return {"queued": false, "ignored": true}
	if stabilization_seconds <= 0.0:
		var updated := apply_event(side, canonical)
		return {
			"queued": false,
			"awarded": true,
			"side": side,
			"event_id": canonical,
			"technique_id": technique_id,
			"score": updated
		}
	var item := {
		"side": side,
		"event_id": canonical,
		"technique_id": technique_id,
		"expected_state": expected_state,
		"required": stabilization_seconds,
		"remaining": stabilization_seconds
	}
	pending_events.append(item)
	return {"queued": true, "awarded": false, "event": item.duplicate(true)}

func tick_stabilization(delta_sec: float, current_state: String) -> Array:
	var resolved: Array = []
	var safe_delta := maxf(0.0, delta_sec)
	for index in range(pending_events.size() - 1, -1, -1):
		var item: Dictionary = pending_events[index]
		var expected := str(item.get("expected_state", ""))
		if expected != "" and expected != current_state:
			var cancelled := item.duplicate(true)
			cancelled["cancelled"] = true
			cancelled["reason"] = "position_not_stabilized"
			resolved.append(cancelled)
			pending_events.remove_at(index)
			continue
		item["remaining"] = maxf(0.0, float(item.get("remaining", 0.0)) - safe_delta)
		if float(item["remaining"]) <= 0.0:
			var awarded := item.duplicate(true)
			awarded["awarded"] = true
			awarded["score"] = apply_event(str(item.get("side", "")), str(item.get("event_id", "")))
			resolved.append(awarded)
			pending_events.remove_at(index)
		else:
			pending_events[index] = item
	return resolved

func cancel_pending() -> void:
	pending_events.clear()

func get_score() -> Dictionary:
	return score.duplicate(true)

func get_pending_events() -> Array:
	return pending_events.duplicate(true)

func _points_for(event_id: String) -> int:
	match normalize_event_id(event_id):
		"takedown": return 2
		"sweep": return 2
		"guard_pass": return 3
		"mount": return 4
		"back_control": return 4
		_: return 0

func get_time_decision() -> Dictionary:
	var player_points := int(score.get("player", 0))
	var rival_points := int(score.get("rival", 0))
	if player_points != rival_points:
		return {
			"winner_side": "player" if player_points > rival_points else "rival",
			"basis": "points"
		}
	var player_advantages := int(score.get("player_advantages", 0))
	var rival_advantages := int(score.get("rival_advantages", 0))
	if player_advantages != rival_advantages:
		return {
			"winner_side": "player" if player_advantages > rival_advantages else "rival",
			"basis": "advantages"
		}
	var player_penalties := int(score.get("player_penalties", 0))
	var rival_penalties := int(score.get("rival_penalties", 0))
	if player_penalties != rival_penalties:
		return {
			"winner_side": "player" if player_penalties < rival_penalties else "rival",
			"basis": "penalties"
		}
	return {"winner_side": "draw", "basis": "referee_decision_required"}

func get_winner_if_time_ends() -> String:
	return str(get_time_decision().get("winner_side", "draw"))
