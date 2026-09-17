class_name ComebackSystem
extends RefCounted

const USES_PER_FIGHT := 1

var remaining := {"p1": USES_PER_FIGHT, "p2": USES_PER_FIGHT}

func reset() -> void:
	remaining = {"p1": USES_PER_FIGHT, "p2": USES_PER_FIGHT}

func can_activate(state: Dictionary, player: int) -> bool:
	var key := _key(player)
	if key == "":
		return false
	if int(remaining.get(key, 0)) <= 0:
		return false
	if int(state.get("winner", 0)) != 0:
		return false
	var mine: Dictionary = state.get(key, {})
	var other: Dictionary = state.get("p2" if key == "p1" else "p1", {})
	var score_deficit := int(other.get("score", 0)) - int(mine.get("score", 0))
	return (
		score_deficit >= 2
		or float(mine.get("gas", 100.0)) <= 30.0
		or float(mine.get("health", 100.0)) <= 55.0
	)

func activate(state: Dictionary, player: int) -> Dictionary:
	if not can_activate(state, player):
		return {"ok": false, "reason": "virada_unavailable"}
	var key := _key(player)
	remaining[key] = int(remaining.get(key, 0)) - 1
	return {
		"ok": true,
		"player": player,
		"resource_delta": {
			"focus": 15.0,
			"moral": 15.0,
			"gas": 8.0
		},
		"remaining": int(remaining[key]),
		"changes_outcome_directly": false
	}

func is_available(player: int) -> bool:
	var key := _key(player)
	return key != "" and int(remaining.get(key, 0)) > 0

func to_dict() -> Dictionary:
	return {"remaining": remaining.duplicate(true)}

func _key(player: int) -> String:
	if player == 1:
		return "p1"
	if player == 2:
		return "p2"
	return ""
