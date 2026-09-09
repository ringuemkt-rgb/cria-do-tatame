class_name GrapplingPhysicalStateV1
extends RefCounted

const ConnectionGraphScript = preload("res://src/combat/GrapplingConnectionGraphV1.gd")

static func from_reducer_state(combat_state: Dictionary) -> Dictionary:
	return {
		"version": "1.0.0",
		"position_id": str(combat_state.get("pos", "standing_neutral")),
		"top_player": int(combat_state.get("top", 0)),
		"authority": "DERIVED_FROM_DETERMINISTIC_REDUCER",
		"athletes": {
			"p1": _athlete_from_reducer(combat_state.get("p1", {})),
			"p2": _athlete_from_reducer(combat_state.get("p2", {}))
		},
		"interaction": {
			"connection_graph": [],
			"contact_continuity": "UNKNOWN",
			"current_phase": "idle",
			"observation_status": "UNOBSERVED"
		}
	}

static func apply_reviewed_binding(physical_state: Dictionary, binding: Dictionary, phase: String) -> Dictionary:
	var next := physical_state.duplicate(true)
	if str(binding.get("review_status", "PENDING")) != "APPROVED":
		return next
	var evidence_refs = binding.get("evidence_refs", [])
	if typeof(evidence_refs) != TYPE_ARRAY or evidence_refs.is_empty():
		return next
	if str(binding.get("reviewer", "")).strip_edges() == "":
		return next
	var phase_edges: Dictionary = binding.get("phase_edges", {})
	var raw_edges = phase_edges.get(phase, [])
	if typeof(raw_edges) != TYPE_ARRAY:
		return next
	var edge_check := ConnectionGraphScript.validate_edges(raw_edges)
	if not bool(edge_check.get("ok", false)):
		return next
	var interaction: Dictionary = next.get("interaction", {}).duplicate(true)
	interaction["connection_graph"] = raw_edges.duplicate(true)
	interaction["current_phase"] = phase
	interaction["observation_status"] = "EXPERT_APPROVED"
	interaction["contact_continuity"] = 1.0 if not raw_edges.is_empty() else "UNKNOWN"
	next["interaction"] = interaction
	return next

static func set_unobserved_phase(physical_state: Dictionary, phase: String) -> Dictionary:
	var next := physical_state.duplicate(true)
	var interaction: Dictionary = next.get("interaction", {}).duplicate(true)
	interaction["current_phase"] = phase
	interaction["connection_graph"] = []
	interaction["contact_continuity"] = "UNKNOWN"
	interaction["observation_status"] = "UNOBSERVED"
	next["interaction"] = interaction
	return next

static func validate_runtime_state(value: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	if str(value.get("authority", "")) != "DERIVED_FROM_DETERMINISTIC_REDUCER":
		errors.append("invalid_authority")
	if str(value.get("position_id", "")) == "":
		errors.append("position_missing")
	var top_player := int(value.get("top_player", -1))
	if top_player < 0 or top_player > 2:
		errors.append("top_player_invalid")
	var athletes = value.get("athletes", {})
	if typeof(athletes) != TYPE_DICTIONARY:
		errors.append("athletes_missing")
	else:
		for player_id in ["p1", "p2"]:
			if not athletes.has(player_id) or typeof(athletes[player_id]) != TYPE_DICTIONARY:
				errors.append("athlete_missing:%s" % player_id)
	var interaction = value.get("interaction", {})
	if typeof(interaction) != TYPE_DICTIONARY:
		errors.append("interaction_missing")
	else:
		var graph = interaction.get("connection_graph", [])
		if typeof(graph) != TYPE_ARRAY:
			errors.append("connection_graph_not_array")
		else:
			var graph_check := ConnectionGraphScript.validate_edges(graph)
			for error in graph_check.get("errors", []):
				errors.append("connection_graph:%s" % str(error))
	return {"ok": errors.is_empty(), "errors": errors}

static func _athlete_from_reducer(fighter: Dictionary) -> Dictionary:
	return {
		"posture": "UNKNOWN",
		"support_points": "UNKNOWN",
		"base_quality": "UNKNOWN",
		"center_of_mass_projection": "UNKNOWN",
		"hip_orientation": "UNKNOWN",
		"shoulder_orientation": "UNKNOWN",
		"head_position": "UNKNOWN",
		"inside_position": "UNKNOWN",
		"frames_and_wedges": "UNKNOWN",
		"grip_graph": "UNKNOWN",
		"grip_integrity": "UNKNOWN",
		"underhook_overhook_state": "UNKNOWN",
		"leg_entanglement_topology": "UNKNOWN",
		"knee_line_state": "UNKNOWN",
		"heel_exposure": "UNKNOWN",
		"off_balance": "UNKNOWN",
		"pressure_vector": "UNKNOWN",
		"mobility_freedom": "UNKNOWN",
		"pinned_segments": "UNKNOWN",
		"submission_danger": "UNKNOWN",
		"gas": clampf(float(fighter.get("gas", 0.0)), 0.0, 100.0),
		"isometric_load": "UNKNOWN",
		"local_fatigue": "UNKNOWN",
		"decision_confidence": "UNKNOWN",
		"score": maxi(0, int(fighter.get("score", 0)))
	}
