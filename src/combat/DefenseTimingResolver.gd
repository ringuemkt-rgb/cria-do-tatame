extends Node
class_name DefenseTimingResolver

func get_timing_window(technique: Dictionary, defender: Dictionary) -> Dictionary:
	var base_window := float(technique.get("defense_window", 0.25))
	var focus := float(defender.get("focus", 50))
	var base := float(defender.get("base", 50))
	var adjusted := base_window + (focus - 50.0) * 0.002 + (base - 50.0) * 0.002
	return {
		"window": clamp(adjusted, 0.10, 0.55),
		"preferred_response": technique.get("defense_response", "defesa")
	}

func resolve_defense(input_quality: float, technique: Dictionary, defender: Dictionary) -> Dictionary:
	var timing := get_timing_window(technique, defender)
	var success := input_quality <= float(timing["window"])
	return {
		"success": success,
		"response": timing["preferred_response"],
		"next_state": technique.get("state_to_defended" if success else "state_to_success", "reset")
	}
