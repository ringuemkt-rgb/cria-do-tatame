extends Node

var mastery: Dictionary = {}
var physical_xp: Dictionary = {"gas": 0.0, "pressure": 0.0, "guard": 0.0, "focus": 0.0, "grip": 0.0}
var fatigue: float = 0.0

func reset() -> void:
	mastery = {}
	physical_xp = {"gas": 0.0, "pressure": 0.0, "guard": 0.0, "focus": 0.0, "grip": 0.0}
	fatigue = 0.0

func run_physical_training(training_id: String, performance: float = 1.0) -> Dictionary:
	var physical_training: Dictionary = DataRegistry.training_minigames.get("physical_training", {})
	var data: Dictionary = physical_training.get(training_id, {})
	if data.is_empty():
		return {"ok": false, "message": "Treino inexistente."}
	var energy_cost: float = float(data.get("energy_cost", 0))
	if WorldState.energy < energy_cost:
		return {"ok": false, "message": "Energia insuficiente."}
	WorldState.energy = max(0.0, WorldState.energy - energy_cost)
	var reward: Dictionary = data.get("reward", {})
	for key_value in reward.keys():
		var key: String = str(key_value)
		var value: float = float(reward[key]) * performance
		if key.ends_with("_xp"):
			var stat: String = key.replace("_xp", "")
			physical_xp[stat] = float(physical_xp.get(stat, 0.0)) + value
		elif key == "injury_recovery":
			WorldState.strain_level = max(0, WorldState.strain_level - int(value))
		else:
			WorldState.modify_reputation(key, value)
	var risk: float = float(data.get("risk_fatigue", 0.0)) + fatigue * 0.01
	if randf() < risk:
		fatigue += 10.0
		WorldState.strain_level += 1
	else:
		fatigue += 4.0
	SaveManager.save_game(1)
	return {"ok": true, "message": "Treino concluido: " + str(data.get("name", training_id)), "fatigue": fatigue}

func run_technical_training(technique_id: String, executions: int = 0) -> Dictionary:
	var technical_training: Dictionary = DataRegistry.training_minigames.get("technical_training", {})
	var base: Dictionary = technical_training.get("rolagem_tecnica", {})
	var energy_cost: float = float(base.get("energy_cost", 25))
	if WorldState.energy < energy_cost:
		return {"ok": false, "message": "Energia insuficiente."}
	WorldState.energy = max(0.0, WorldState.energy - energy_cost)
	var xp: float = float(base.get("mastery_xp", 20)) * clamp(float(executions) / 3.0, 0.25, 1.25)
	mastery[technique_id] = float(mastery.get(technique_id, 0.0)) + xp
	if float(mastery[technique_id]) >= 100.0 and not WorldState.techniques_learned.has(technique_id):
		WorldState.techniques_learned.append(technique_id)
	SaveManager.save_game(1)
	return {"ok": true, "message": "Maestria de " + technique_id + " aumentou.", "xp": xp, "total": mastery[technique_id]}

func get_mastery_level(technique_id: String) -> int:
	return clampi(int(float(mastery.get(technique_id, 0.0)) / 100.0) + 1, 1, 5)

func to_dict() -> Dictionary:
	return {"mastery": mastery, "physical_xp": physical_xp, "fatigue": fatigue}

func load_from_dict(data: Dictionary) -> void:
	mastery = data.get("mastery", {})
	physical_xp = data.get("physical_xp", physical_xp)
	fatigue = float(data.get("fatigue", 0.0))
