class_name BJJMotionBindingV1
extends RefCounted

var requirements: Dictionary = {}
var by_technique: Dictionary = {}
var phases: Array = []

func _init(requirements_data: Dictionary = {}):
	requirements = requirements_data.duplicate(true)
	phases = requirements.get("phases", ["anticipation", "entry", "establish", "stabilize", "response", "recovery"]).duplicate(true)
	for raw_requirement in requirements.get("requirements", []):
		if typeof(raw_requirement) != TYPE_DICTIONARY:
			continue
		var requirement: Dictionary = raw_requirement
		var technique_id := str(requirement.get("technique_id", ""))
		if technique_id != "":
			by_technique[technique_id] = requirement.duplicate(true)

func build_request(before_state: Dictionary, after_state: Dictionary, action: Dictionary, outcome_event: Dictionary) -> Dictionary:
	var base := {
		"version": "1.0.0",
		"authoritative": false,
		"may_mutate_combat": false,
		"visual_only": true,
		"shipping": false,
		"from_position": str(before_state.get("pos", "")),
		"to_position": str(after_state.get("pos", "")),
		"phases": phases.duplicate(true),
		"paired_required": false,
		"ready_to_play": false,
		"asset_status": "NO_MOTION",
		"technique_id": "",
		"outcome": str(outcome_event.get("ev", ""))
	}

	if str(action.get("kind", "technique")) == "stabilize":
		base["asset_status"] = "EVENT_ONLY"
		base["visual_event"] = "stabilization"
		return base

	var event_type := str(outcome_event.get("ev", ""))
	if event_type not in ["hit", "counter"]:
		base["asset_status"] = "NO_COMMITTED_TRANSITION"
		base["technique_id"] = str(action.get("atk", ""))
		return base

	var technique_id := str(outcome_event.get("t", action.get("atk", "")))
	base["technique_id"] = technique_id
	base["paired_required"] = true
	if not by_technique.has(technique_id):
		base["asset_status"] = "UNMAPPED_MOTION_REQUIREMENT"
		return base

	var requirement: Dictionary = by_technique[technique_id]
	base["from_position"] = str(requirement.get("from", before_state.get("pos", "")))
	base["to_position"] = str(requirement.get("to", after_state.get("pos", "")))
	base["asset_status"] = str(requirement.get("asset_status", "MISSING_APPROVED_FINAL"))
	base["human_approval"] = bool(requirement.get("human_approval", false))
	base["ready_to_play"] = base["asset_status"] == "APPROVED_FINAL" and bool(base["human_approval"])
	return base

func requirement_for(technique_id: String) -> Dictionary:
	if not by_technique.has(technique_id):
		return {}
	return by_technique[technique_id].duplicate(true)

func coverage(technique_ids: Array) -> Dictionary:
	var missing: Array[String] = []
	for value in technique_ids:
		var technique_id := str(value)
		if not by_technique.has(technique_id):
			missing.append(technique_id)
	return {"ok": missing.is_empty(), "missing": missing, "mapped": technique_ids.size() - missing.size(), "required": technique_ids.size()}
