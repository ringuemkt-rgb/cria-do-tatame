extends Node
class_name CombatSmokeTest

func run() -> Dictionary:
	var combat := CombatManager.new()
	combat.setup({"gas": 70, "focus": 60, "grip": 95}, {"defense": 50, "focus": 50, "base": 50})
	var technique := {
		"id": "pegada_lapela_manga",
		"state_from": "distancia_media",
		"state_to_success": "disputa_pegada",
		"state_to_defended": "distancia_media",
		"base_chance": 0.9,
		"score_event": ""
	}
	var result := combat.use_technique(technique)
	return {
		"passed": result.has("combat_state"),
		"result": result
	}
