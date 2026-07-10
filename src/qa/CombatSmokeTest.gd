extends Node
class_name CombatSmokeTest

func run() -> Dictionary:
	var combat := CombatSimulationEngine.new()
	add_child(combat)
	combat.setup(
		{"gas": 70, "focus": 60, "grip": 95, "control": 55, "moral": 60},
		{"gas": 70, "focus": 50, "grip": 50, "guard": 50, "control": 50, "moral": 50}
	)
	var technique := {
		"id": "pegada_lapela_manga",
		"name_ptbr": "Pegada Lapela e Manga",
		"state_from": "distancia_media",
		"state_to_success": "disputa_pegada",
		"state_to_defended": "distancia_media",
		"entry_state": "distancia_media",
		"exit_state": "disputa_pegada",
		"base_chance": 0.9,
		"cost": {"gas": 4, "focus": 1},
		"effects": {"self_control_bonus": 5, "opponent_grip_reduction": 8},
		"score_event": ""
	}
	var result := combat.use_technique(technique)
	var passed := result.has("combat_state") and not result.has("error")
	combat.queue_free()
	return {
		"passed": passed,
		"result": result
	}
