extends Node
class_name WorldTimeManager

var save_manager: SaveManager
var state: Dictionary = {}

func setup(p_save_manager: SaveManager) -> void:
	save_manager = p_save_manager
	state = save_manager.load_json("world_time.json", {"week": 1, "day": 1, "block": "manha"})

func save() -> void:
	save_manager.save_json("world_time.json", state)

func next_day() -> Dictionary:
	state["day"] = int(state.get("day", 1)) + 1
	if int(state["day"]) > 7:
		state["day"] = 1
		state["week"] = int(state.get("week", 1)) + 1
	save()
	return state

func next_week() -> Dictionary:
	state["week"] = int(state.get("week", 1)) + 1
	state["day"] = 1
	save()
	return state
