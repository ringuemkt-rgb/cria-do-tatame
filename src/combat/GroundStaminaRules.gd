class_name GroundStaminaRules
extends RefCounted

var data: Dictionary = {}

func configure(p_data: Dictionary) -> void:
	data = p_data.duplicate(true)

func decorate_technique(technique: Dictionary, actor_state: String) -> Dictionary:
	var output: Dictionary = technique.duplicate(true)
	var source_cost = technique.get("cost", technique.get("custo", {}))
	var cost: Dictionary = source_cost.duplicate(true) if typeof(source_cost) == TYPE_DICTIONARY else {}
	var base_gas := float(cost.get("gas", technique.get("gas_cost", 0.0)))
	var surcharge := get_action_surcharge(actor_state)
	cost["gas"] = base_gas + surcharge
	cost["focus"] = float(cost.get("focus", cost.get("foco", technique.get("focus_cost", 0.0))))
	cost["moral"] = float(cost.get("moral", technique.get("moral_cost", 0.0)))
	output["cost"] = cost
	output["ground_stamina_surcharge"] = surcharge
	return output

func get_action_surcharge(actor_state: String) -> float:
	var limits: Dictionary = data.get("limits", {})
	var maximum := float(limits.get("max_action_surcharge", 2.0))
	var costs: Dictionary = data.get("state_action_surcharge", {})
	return clampf(float(costs.get(actor_state, 0.0)), 0.0, maximum)

func get_fatigue_profile(gas: float) -> Dictionary:
	var profile := {
		"id": "fresh",
		"gas_at_or_below": 100.0,
		"chance_modifier": 0.0,
		"submission_effectiveness": 1.0
	}
	for band_value in data.get("fatigue_bands", []):
		if typeof(band_value) != TYPE_DICTIONARY:
			continue
		var band: Dictionary = band_value
		if gas <= float(band.get("gas_at_or_below", -1.0)):
			profile = band.duplicate(true)
	var limits: Dictionary = data.get("limits", {})
	profile["chance_modifier"] = clampf(
		float(profile.get("chance_modifier", 0.0)),
		float(limits.get("min_chance_modifier", -0.14)),
		float(limits.get("max_chance_modifier", 0.0))
	)
	profile["submission_effectiveness"] = clampf(
		float(profile.get("submission_effectiveness", 1.0)),
		float(limits.get("min_submission_effectiveness", 0.6)),
		float(limits.get("max_submission_effectiveness", 1.0))
	)
	return profile

func get_chance_modifier(gas: float) -> float:
	return float(get_fatigue_profile(gas).get("chance_modifier", 0.0))

func get_submission_effectiveness(gas: float) -> float:
	return float(get_fatigue_profile(gas).get("submission_effectiveness", 1.0))

func get_action_snapshot(technique: Dictionary, actor_state: String, gas: float) -> Dictionary:
	var fatigue := get_fatigue_profile(gas)
	return {
		"simulation": str(data.get("simulation", "")),
		"state": actor_state,
		"surcharge": get_action_surcharge(actor_state),
		"fatigue_band": str(fatigue.get("id", "fresh")),
		"chance_modifier": float(fatigue.get("chance_modifier", 0.0)),
		"submission_effectiveness": float(fatigue.get("submission_effectiveness", 1.0)),
		"technique_id": str(technique.get("id", ""))
	}
