class_name BJJIdAdapterV1
extends RefCounted

const MAP_PATH := "res://data/combat/combat_manager_bjj_shadow_map_v1.json"
const SLICE_PATH := "res://data/bjj/bjj_kg_slice_ruan_davi_v1.json"

var legacy_action_to_canonical: Dictionary = {}
var legacy_state_to_canonical: Dictionary = {}
var canonical_techniques: Dictionary = {}
var canonical_positions: Dictionary = {}
var errors: Array[String] = []

func initialize() -> Dictionary:
	errors.clear()
	legacy_action_to_canonical.clear()
	legacy_state_to_canonical.clear()
	canonical_techniques.clear()
	canonical_positions.clear()

	var mapping := _load_json(MAP_PATH)
	var slice := _load_json(SLICE_PATH)
	if mapping.is_empty():
		errors.append("mapping_missing_or_invalid")
	if slice.is_empty():
		errors.append("slice_missing_or_invalid")
	if not errors.is_empty():
		return status()

	for row in slice.get("techniques", []):
		if typeof(row) != TYPE_DICTIONARY:
			continue
		var technique_id := str(row.get("id", ""))
		if technique_id != "":
			canonical_techniques[technique_id] = true

	for row in slice.get("positions", []):
		if typeof(row) != TYPE_DICTIONARY:
			continue
		var position_id := str(row.get("id", ""))
		if position_id != "":
			canonical_positions[position_id] = true

	for legacy_id in mapping.get("legacy_action_map", {}):
		var row: Dictionary = mapping["legacy_action_map"][legacy_id]
		var canonical_id := str(row.get("canonical", ""))
		if canonical_id == "" or not canonical_techniques.has(canonical_id):
			errors.append("legacy_action_invalid_target:%s:%s" % [legacy_id, canonical_id])
			continue
		legacy_action_to_canonical[str(legacy_id)] = canonical_id

	for legacy_id in mapping.get("legacy_state_map", {}):
		var row: Dictionary = mapping["legacy_state_map"][legacy_id]
		var canonical = row.get("canonical", null)
		var confidence := str(row.get("confidence", "UNKNOWN"))
		if canonical == null or confidence == "AMBIGUOUS":
			continue
		var canonical_id := str(canonical)
		if not canonical_positions.has(canonical_id):
			errors.append("legacy_state_invalid_target:%s:%s" % [legacy_id, canonical_id])
			continue
		legacy_state_to_canonical[str(legacy_id)] = canonical_id

	return status()

func is_ready() -> bool:
	return errors.is_empty() and not canonical_techniques.is_empty() and not canonical_positions.is_empty()

func normalize_technique(value: String, namespace: String = "auto") -> Dictionary:
	if not is_ready():
		return {"ok": false, "error": "adapter_not_ready"}
	var source := value.strip_edges()
	if source == "":
		return {"ok": false, "error": "empty_technique_id"}

	if namespace in ["auto", "canonical", "card"] and canonical_techniques.has(source):
		return {
			"ok": true,
			"canonical": source,
			"source": source,
			"source_namespace": "canonical" if namespace != "card" else "card",
			"mapped": namespace == "card"
		}

	if namespace in ["auto", "legacy"] and legacy_action_to_canonical.has(source):
		return {
			"ok": true,
			"canonical": str(legacy_action_to_canonical[source]),
			"source": source,
			"source_namespace": "legacy",
			"mapped": true
		}

	return {
		"ok": false,
		"error": "technique_id_unmapped",
		"source": source,
		"namespace": namespace,
		"policy": "DO_NOT_GUESS"
	}

func normalize_position(value: String, namespace: String = "auto") -> Dictionary:
	if not is_ready():
		return {"ok": false, "error": "adapter_not_ready"}
	var source := value.strip_edges()
	if source == "":
		return {"ok": false, "error": "empty_position_id"}

	if namespace in ["auto", "canonical"] and canonical_positions.has(source):
		return {
			"ok": true,
			"canonical": source,
			"source": source,
			"source_namespace": "canonical",
			"mapped": false
		}

	if namespace in ["auto", "legacy"] and legacy_state_to_canonical.has(source):
		return {
			"ok": true,
			"canonical": str(legacy_state_to_canonical[source]),
			"source": source,
			"source_namespace": "legacy",
			"mapped": true
		}

	return {
		"ok": false,
		"error": "position_id_unmapped_or_ambiguous",
		"source": source,
		"namespace": namespace,
		"policy": "DO_NOT_GUESS"
	}

func status() -> Dictionary:
	return {
		"ok": is_ready(),
		"authoritative": false,
		"shipping": false,
		"legacy_actions_mapped": legacy_action_to_canonical.size(),
		"legacy_states_mapped": legacy_state_to_canonical.size(),
		"canonical_techniques": canonical_techniques.size(),
		"canonical_positions": canonical_positions.size(),
		"errors": errors.duplicate()
	}

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}
