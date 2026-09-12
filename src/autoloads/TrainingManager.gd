extends Node

# `mastery` permanece como espelho de compatibilidade para saves e consumidores legados.
# A autoridade de maestria tecnica passa a ser ProgressionOS.
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
	var result := {
		"ok": true,
		"message": "Treino concluido: " + str(data.get("name", training_id)),
		"fatigue": fatigue,
		"performance": performance,
		"progression_xp": 35.0 * clampf(performance, 0.25, 1.5)
	}
	if SignalBus.has_signal("training_completed"):
		SignalBus.training_completed.emit(StringName("physical"), StringName(training_id), result.duplicate(true))
	SaveManager.save_game(1)
	return result

func run_technical_training(technique_id: String, executions: int = 0) -> Dictionary:
	var technical_training: Dictionary = DataRegistry.training_minigames.get("technical_training", {})
	var base: Dictionary = technical_training.get("rolagem_tecnica", {})
	var energy_cost: float = float(base.get("energy_cost", 25))
	if WorldState.energy < energy_cost:
		return {"ok": false, "message": "Energia insuficiente."}
	WorldState.energy = max(0.0, WorldState.energy - energy_cost)
	var xp: float = float(base.get("mastery_xp", 20)) * clamp(float(executions) / 3.0, 0.25, 1.25)
	var result := {
		"ok": true,
		"message": "Maestria de " + technique_id + " aumentou.",
		"xp": xp,
		"mastery_xp": xp,
		"progression_xp": max(10.0, xp * 0.5),
		"executions": executions
	}
	if has_node("/root/ProgressionOS") and SignalBus.has_signal("training_completed"):
		SignalBus.training_completed.emit(StringName("technical"), StringName(technique_id), result.duplicate(true))
		mastery = ProgressionOS.get_mastery_points_map()
		result["total"] = ProgressionOS.get_mastery_points(technique_id)
		result["stage"] = ProgressionOS.get_mastery_stage(technique_id)
	else:
		mastery[technique_id] = float(mastery.get(technique_id, 0.0)) + xp
		if float(mastery[technique_id]) >= 100.0 and not WorldState.techniques_learned.has(technique_id):
			WorldState.techniques_learned.append(technique_id)
		result["total"] = mastery[technique_id]
	SaveManager.save_game(1)
	return result

func get_mastery_level(technique_id: String) -> int:
	if has_node("/root/ProgressionOS"):
		return ProgressionOS.get_mastery_level(technique_id)
	return clampi(int(float(mastery.get(technique_id, 0.0)) / 100.0) + 1, 1, 5)

func get_mastery_points(technique_id: String) -> float:
	if has_node("/root/ProgressionOS"):
		return ProgressionOS.get_mastery_points(technique_id)
	return float(mastery.get(technique_id, 0.0))

func get_mastery_stage(technique_id: String) -> String:
	if has_node("/root/ProgressionOS"):
		return ProgressionOS.get_mastery_stage(technique_id)
	return "learned" if get_mastery_points(technique_id) >= 100.0 else "discovered"

func to_dict() -> Dictionary:
	var exported_mastery := mastery.duplicate(true)
	if has_node("/root/ProgressionOS"):
		exported_mastery = ProgressionOS.get_mastery_points_map()
	return {"mastery": exported_mastery, "physical_xp": physical_xp, "fatigue": fatigue}

func load_from_dict(data: Dictionary) -> void:
	var legacy_mastery: Dictionary = data.get("mastery", {}).duplicate(true)
	physical_xp = data.get("physical_xp", physical_xp)
	fatigue = float(data.get("fatigue", 0.0))
	if has_node("/root/ProgressionOS"):
		if ProgressionOS.is_empty() and not legacy_mastery.is_empty():
			ProgressionOS.import_legacy_training_mastery(legacy_mastery)
		mastery = ProgressionOS.get_mastery_points_map()
	else:
		mastery = legacy_mastery
