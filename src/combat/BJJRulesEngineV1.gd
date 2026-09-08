class_name BJJRulesEngineV1
extends RefCounted

var rules: Dictionary = {}

func _init(rules_data: Dictionary = {}):
	rules = rules_data.duplicate(true)

func canonical_ruleset_id(value: String) -> String:
	match value:
		"ibjjf", "ibjjf_v6": return "ibjjf_v6"
		"adcc", "adcc_championship_current": return "adcc_championship_current"
		"clandestina", "clandestine_cria_v1": return "clandestine_cria_v1"
		_: return value

func technique_allowed(technique: Dictionary, state: Dictionary, positions: Dictionary) -> bool:
	var availability: Dictionary = technique.get("availability", {})
	if bool(state.get("gi", true)):
		if availability.get("gi", false) != true:
			return false
	else:
		if availability.get("nogi", false) != true:
			return false

	var ruleset_id := canonical_ruleset_id(str(state.get("ruleset", "")))
	var legality: Dictionary = technique.get("legality", {})
	if not legality.has(ruleset_id):
		return false
	var gate: Dictionary = legality[ruleset_id]
	if gate.get("allowed", false) != true:
		return false
	var requested_belt := str(state.get("belt_or_skill_division", "slice_any"))
	var requested_age := str(state.get("age_division", "adult"))
	var belts: Array = gate.get("belt_or_skill_division", [])
	var ages: Array = gate.get("age_division", [])
	if not belts.has(requested_belt) and not belts.has("any") and not belts.has("slice_any"):
		return false
	if not ages.has(requested_age) and not ages.has("any"):
		return false

	if bool(technique.get("restricted_leglock", false)):
		var from_id := str(technique.get("from", technique.get("de", "")))
		var from_node: Dictionary = positions.get(from_id, {})
		if str(from_node.get("cat", "")) != "leglock":
			return false
	return true

func points_for_event(ruleset_value: String, event_id: String) -> int:
	var ruleset_id := canonical_ruleset_id(ruleset_value)
	if ruleset_id == "clandestine_cria_v1":
		return 0
	var rulesets: Dictionary = rules.get("rulesets", {})
	var spec: Dictionary = rulesets.get(ruleset_id, {})
	var points: Dictionary = spec.get("points", {})
	match ruleset_id:
		"ibjjf_v6":
			match event_id:
				"takedown": return int(points.get("takedown", 0))
				"sweep": return int(points.get("sweep", 0))
				"knee_on_belly": return int(points.get("knee_on_belly", 0))
				"guard_pass": return int(points.get("guard_pass", 0))
				"mount": return int(points.get("mount", 0))
				"back_control": return int(points.get("back_control", 0))
		"adcc_championship_current":
			match event_id:
				"takedown": return int(points.get("takedown_to_guard_or_half", 0))
				"clean_takedown": return int(points.get("clean_takedown_past_guard", 0))
				"sweep": return int(points.get("sweep_to_guard_or_half", 0))
				"clean_sweep": return int(points.get("clean_sweep_past_guard", 0))
				"knee_on_belly": return int(points.get("knee_on_stomach", 0))
				"guard_pass": return int(points.get("guard_pass", 0))
				"mount": return int(points.get("mount", 0))
				"back_control": return int(points.get("back_mount_hooks_or_body_triangle", 0))
	return 0
