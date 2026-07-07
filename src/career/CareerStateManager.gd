extends Node
class_name CareerStateManager

var save_manager: SaveManager
var state: Dictionary = {}

func setup(p_save_manager: SaveManager) -> void:
	save_manager = p_save_manager
	state = save_manager.load_json("player_state.json", _default_state())

func _default_state() -> Dictionary:
	return {
		"athlete_id": "ruan_macacao",
		"display_name": "Ruan Macacao Silva",
		"belt": "branca",
		"week": 1,
		"attributes": {
			"gas": 70,
			"focus": 60,
			"moral": 50,
			"grip": 95,
			"base": 70,
			"takedown": 55,
			"guard": 45,
			"passing": 60,
			"sweep": 40,
			"top_control": 75,
			"bottom_defense": 45,
			"technical_finish": 40
		},
		"unlocked_techniques": ["postura", "pegada", "clinch", "baiana", "sprawl", "guarda_fechada", "cem_quilos"],
		"career_flags": {}
	}

func save() -> void:
	save_manager.save_json("player_state.json", state)

func get_attribute(key: String, default_value: int = 0) -> int:
	return int(state.get("attributes", {}).get(key, default_value))

func add_attribute_xp(key: String, amount: int) -> void:
	var attrs: Dictionary = state.get("attributes", {})
	attrs[key] = int(attrs.get(key, 0)) + amount
	state["attributes"] = attrs
	save()

func unlock_technique(technique_id: String) -> void:
	var list: Array = state.get("unlocked_techniques", [])
	if not list.has(technique_id):
		list.append(technique_id)
	state["unlocked_techniques"] = list
	save()

func has_technique(technique_id: String) -> bool:
	return state.get("unlocked_techniques", []).has(technique_id)
