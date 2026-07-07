extends Node
class_name TechniqueResolver

var rng := RandomNumberGenerator.new()

func resolve_technique(technique: Dictionary, actor: Dictionary, defender: Dictionary, context: Dictionary = {}) -> Dictionary:
	rng.randomize()
	var base_chance := float(technique.get("base_chance", 0.55))
	var required_state := str(technique.get("state_from", ""))
	var current_state := str(context.get("state", ""))
	if required_state != "" and required_state != current_state:
		base_chance -= 0.25
	var gas := float(actor.get("gas", 50))
	var focus := float(actor.get("focus", 50))
	var grip := float(actor.get("grip", 50))
	var defense := float(defender.get("defense", 50))
	var score := base_chance + (focus - 50.0) * 0.004 + (grip - 50.0) * 0.003 + (gas - 50.0) * 0.002 - (defense - 50.0) * 0.004
	score = clamp(score, 0.05, 0.95)
	var success := rng.randf() <= score
	return {
		"technique_id": technique.get("id", "unknown"),
		"success": success,
		"chance": score,
		"state_from": current_state,
		"state_to": technique.get("state_to_success" if success else "state_to_defended", "reset"),
		"gas_cost": int(technique.get("gas_cost", 8)),
		"focus_cost": int(technique.get("focus_cost", 3)),
		"message": technique.get("success_text" if success else "defended_text", "troca tecnica")
	}
