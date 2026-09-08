class_name BJJGraphLoader
extends RefCounted

const FULL_MIN_POSITIONS := 40
const FULL_MIN_TECHNIQUES := 120
const FULL_MIN_CHAINS := 10
const COUNTER_OUTCOMES := {
	"deny_to_same_state": true,
	"redirect_to_scramble": true,
	"redirect_to_front_headlock": true,
	"redirect_to_knee_shield": true,
	"reverse_to_top": true,
	"submission_threat": true,
	"reset_to_neutral": true
}

static func load_from_path(path: String, require_full: bool = true) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "errors": ["kg_file_missing:%s" % path], "kg": {}}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "errors": ["kg_file_unreadable:%s" % path], "kg": {}}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"ok": false, "errors": ["kg_root_must_be_dictionary"], "kg": {}}
	var errors := validate_graph(parsed, require_full)
	return {"ok": errors.is_empty(), "errors": errors, "kg": parsed if errors.is_empty() else {}}

static func validate_graph(kg: Dictionary, require_full: bool = true) -> Array:
	var errors: Array = []
	var positions: Array = kg.get("positions", kg.get("posicoes", []))
	var techniques: Array = kg.get("techniques", kg.get("tecnicas", []))
	var chains: Array = kg.get("chains", [])
	if require_full:
		if positions.size() < FULL_MIN_POSITIONS:
			errors.append("full_kg_requires_at_least_40_positions")
		if techniques.size() < FULL_MIN_TECHNIQUES:
			errors.append("full_kg_requires_at_least_120_techniques")
		if chains.size() < FULL_MIN_CHAINS:
			errors.append("full_kg_requires_at_least_10_chains")
		if bool(kg.get("full_graph_claim", true)) == false:
			errors.append("full_kg_cannot_be_slice_fixture")

	var pos_ids := {}
	for raw_position in positions:
		if typeof(raw_position) != TYPE_DICTIONARY:
			errors.append("position_must_be_dictionary")
			continue
		var position: Dictionary = raw_position
		var pid := str(position.get("id", ""))
		if pid == "":
			errors.append("position_id_missing")
			continue
		if pos_ids.has(pid):
			errors.append("duplicate_position:%s" % pid)
		pos_ids[pid] = true

	var tech_ids := {}
	for raw_technique in techniques:
		if typeof(raw_technique) != TYPE_DICTIONARY:
			errors.append("technique_must_be_dictionary")
			continue
		var technique: Dictionary = raw_technique
		var tid := str(technique.get("id", ""))
		if tid == "":
			errors.append("technique_id_missing")
			continue
		if tech_ids.has(tid):
			errors.append("duplicate_technique:%s" % tid)
		tech_ids[tid] = true
		var from_id := str(technique.get("from", technique.get("de", "")))
		var to_id := str(technique.get("to", technique.get("para", "")))
		if not pos_ids.has(from_id):
			errors.append("technique_from_missing:%s:%s" % [tid, from_id])
		if not pos_ids.has(to_id):
			errors.append("technique_to_missing:%s:%s" % [tid, to_id])
		if not technique.has("actor_role_from") or not technique.has("actor_role_to"):
			errors.append("technique_actor_roles_required:%s" % tid)
		if technique.has("pts"):
			errors.append("static_pts_tuple_forbidden:%s" % tid)
		var prior = technique.get("authoring_prior", null)
		if typeof(prior) not in [TYPE_FLOAT, TYPE_INT]:
			errors.append("authoring_prior_required:%s" % tid)
		else:
			var prior_f := float(prior)
			if prior_f < 0.0 or prior_f > 1.0:
				errors.append("authoring_prior_out_of_range:%s" % tid)
		if str(technique.get("prior_status", "")) != "UNCALIBRATED_EXPERT_HEURISTIC":
			errors.append("authoring_prior_status_invalid:%s" % tid)
		if technique.get("empirical_success", null) != null:
			errors.append("empirical_success_must_be_null_before_f3:%s" % tid)
		var availability: Dictionary = technique.get("availability", {})
		if not availability.has("gi") or not availability.has("nogi"):
			errors.append("gi_nogi_availability_required:%s" % tid)
		var legality: Dictionary = technique.get("legality", {})
		if legality.is_empty():
			errors.append("ruleset_legality_required:%s" % tid)
		for ruleset_id in legality.keys():
			var gate: Dictionary = legality[ruleset_id]
			if not gate.has("allowed") or not gate.has("belt_or_skill_division") or not gate.has("age_division"):
				errors.append("legality_dimensions_incomplete:%s:%s" % [tid, str(ruleset_id)])
		var counters: Array = technique.get("counters", [])
		for counter_value in counters:
			if typeof(counter_value) != TYPE_DICTIONARY:
				errors.append("counter_must_have_semantics:%s" % tid)
				continue
			var outcome := str(counter_value.get("outcome", ""))
			if not COUNTER_OUTCOMES.has(outcome):
				errors.append("counter_outcome_invalid:%s:%s" % [tid, outcome])

	for raw_technique in techniques:
		if typeof(raw_technique) != TYPE_DICTIONARY:
			continue
		var technique: Dictionary = raw_technique
		var tid := str(technique.get("id", ""))
		for counter_value in technique.get("counters", []):
			if typeof(counter_value) != TYPE_DICTIONARY:
				continue
			var counter_id := str(counter_value.get("technique_id", ""))
			if not tech_ids.has(counter_id):
				errors.append("counter_target_missing:%s:%s" % [tid, counter_id])

	for chain_value in chains:
		if typeof(chain_value) != TYPE_DICTIONARY:
			errors.append("chain_must_be_dictionary")
			continue
		var steps: Array = chain_value.get("steps", [])
		for step_id in steps:
			if not tech_ids.has(str(step_id)):
				errors.append("chain_step_missing:%s" % str(step_id))
	return errors
