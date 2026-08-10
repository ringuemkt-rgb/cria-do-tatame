extends RefCounted
class_name GroundGraphRules

var graph: Dictionary = {}
var edges_by_technique: Dictionary = {}

func configure(data: Dictionary) -> void:
	graph = data.duplicate(true)
	edges_by_technique.clear()
	for edge_value in graph.get("edges", []):
		if typeof(edge_value) != TYPE_DICTIONARY:
			continue
		var edge: Dictionary = edge_value
		var technique_id := str(edge.get("technique_id", ""))
		if technique_id != "":
			edges_by_technique[technique_id] = edge.duplicate(true)

func get_edge(technique_id: String) -> Dictionary:
	return edges_by_technique.get(technique_id, {}).duplicate(true)

func validate_technique_transition(technique: Dictionary, actor_state: String) -> Dictionary:
	var technique_id := str(technique.get("id", ""))
	var edge := get_edge(technique_id)
	if edge.is_empty():
		return _error(technique_id, "ground_graph_edge_missing")
	var declared_from := str(technique.get("entry_state", technique.get("estado_entrada", "")))
	var declared_to := str(technique.get("exit_state", technique.get("estado_saida", declared_from)))
	if declared_from != str(edge.get("from", "")) or declared_to != str(edge.get("to", "")):
		return _error(technique_id, "ground_graph_contract_mismatch")
	if actor_state != declared_from:
		return _error(technique_id, "ground_graph_state_mismatch")
	return {
		"ok": true,
		"technique_id": technique_id,
		"from": declared_from,
		"to": declared_to,
		"intent": str(edge.get("intent", "")),
		"anatomy_id": str(edge.get("anatomy_id", ""))
	}

func _error(technique_id: String, reason: String) -> Dictionary:
	return {"ok": false, "technique_id": technique_id, "error": reason}
