class_name GrapplingConnectionGraphV1
extends RefCounted

const EDGE_TYPES := [
	"grip", "frame", "hook", "pin", "post", "wedge", "head_control",
	"chest_contact", "hip_contact", "leg_entanglement", "foot_contact", "mat_support"
]
const PHASES := ["anticipation", "entry", "establish", "stabilize", "response", "recovery", "UNKNOWN"]

static func empty() -> Array:
	return []

static func valid_node_id(node_id: String) -> bool:
	if node_id in ["mat", "boundary"]:
		return true
	return node_id.begins_with("p1_") or node_id.begins_with("p2_") or node_id.begins_with("gi_")

static func validate_edge(edge: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var edge_type := str(edge.get("type", ""))
	var source := str(edge.get("source", ""))
	var target := str(edge.get("target", ""))
	var phase := str(edge.get("phase", "UNKNOWN"))
	if edge_type not in EDGE_TYPES:
		errors.append("unknown_edge_type:%s" % edge_type)
	if not valid_node_id(source):
		errors.append("invalid_source:%s" % source)
	if not valid_node_id(target):
		errors.append("invalid_target:%s" % target)
	if source == target:
		errors.append("self_edge_forbidden:%s" % source)
	if phase not in PHASES:
		errors.append("invalid_phase:%s" % phase)
	var strength = edge.get("strength", "UNKNOWN")
	if typeof(strength) != TYPE_STRING:
		var numeric_strength := float(strength)
		if numeric_strength < 0.0 or numeric_strength > 1.0:
			errors.append("strength_out_of_range")
	elif str(strength) != "UNKNOWN":
		errors.append("invalid_strength_unknown_token")
	var confidence = edge.get("confidence", "UNKNOWN")
	if typeof(confidence) != TYPE_STRING:
		var numeric_confidence := float(confidence)
		if numeric_confidence < 0.0 or numeric_confidence > 1.0:
			errors.append("confidence_out_of_range")
	elif str(confidence) != "UNKNOWN":
		errors.append("invalid_confidence_unknown_token")
	return {"ok": errors.is_empty(), "errors": errors}

static func validate_edges(edges: Array) -> Dictionary:
	var errors: Array[String] = []
	for index in range(edges.size()):
		if typeof(edges[index]) != TYPE_DICTIONARY:
			errors.append("edge_not_dictionary:%d" % index)
			continue
		var result := validate_edge(edges[index])
		for error in result.get("errors", []):
			errors.append("edge_%d:%s" % [index, str(error)])
	return {"ok": errors.is_empty(), "errors": errors}

static func add_edge(edges: Array, edge: Dictionary) -> Dictionary:
	var check := validate_edge(edge)
	if not bool(check.get("ok", false)):
		return {"ok": false, "errors": check.get("errors", []), "edges": edges.duplicate(true)}
	var next := edges.duplicate(true)
	var key := _edge_key(edge)
	for existing in next:
		if typeof(existing) == TYPE_DICTIONARY and _edge_key(existing) == key:
			return {"ok": true, "edges": next, "deduplicated": true}
	next.append(edge.duplicate(true))
	return {"ok": true, "edges": next, "deduplicated": false}

static func remove_edge(edges: Array, edge_type: String, source: String, target: String) -> Array:
	var next: Array = []
	for existing in edges:
		if typeof(existing) != TYPE_DICTIONARY:
			continue
		if str(existing.get("type", "")) == edge_type and str(existing.get("source", "")) == source and str(existing.get("target", "")) == target:
			continue
		next.append(existing.duplicate(true))
	return next

static func edges_for_phase(edges: Array, phase: String) -> Array:
	var out: Array = []
	for edge in edges:
		if typeof(edge) == TYPE_DICTIONARY and str(edge.get("phase", "UNKNOWN")) == phase:
			out.append(edge.duplicate(true))
	return out

static func _edge_key(edge: Dictionary) -> String:
	return "%s|%s|%s|%s" % [str(edge.get("type", "")), str(edge.get("source", "")), str(edge.get("target", "")), str(edge.get("phase", "UNKNOWN"))]
