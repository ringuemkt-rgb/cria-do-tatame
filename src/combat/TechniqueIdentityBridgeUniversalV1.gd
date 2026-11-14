class_name TechniqueIdentityBridgeUniversalV1
extends RefCounted

## Read-only migration intelligence. NEVER rewrites techniques or changes reducer authority.
const BRIDGE := "res://data/combat/technique_identity_bridge_universal_v1.json"
const MASTER := "res://data/techniques.json"
const SHADOW := "res://data/combat/combat_manager_bjj_shadow_map_v1.json"

var mapping: Dictionary = {}
var issues: Array[String] = []

func _init() -> void:
	var data := FighterCombatProfileRegistryV1._json(BRIDGE)
	var master := FighterCombatProfileRegistryV1._json(MASTER)
	var shadow := FighterCombatProfileRegistryV1._json(SHADOW)
	if data.is_empty() or master.is_empty() or shadow.is_empty():
		issues.append("missing_bridge_source")
		return
	if bool(data.get("shipping", true)) or data.get("status", "") != "SHADOW_NON_AUTHORITATIVE":
		issues.append("bridge_must_remain_non_authoritative")
	var expected: Dictionary = {}
	for item in master.get("techniques", []):
		if typeof(item) == TYPE_DICTIONARY:
			expected[str(item.get("id", ""))] = item
	mapping = data.get("techniques", {}).duplicate(true)
	if mapping.size() != expected.size():
		issues.append("bridge_missing_or_extra_techniques")
	for id in expected:
		if not mapping.has(id):
			issues.append("missing_legacy_id:" + id)
			continue
		var pair: Dictionary = mapping[id]
		var legacy: Dictionary = expected[id]
		if bool(pair.get("shipping", true)) or str(pair.get("legacy_id", "")) != id or str(pair.get("legacy_from", "")) != str(legacy.get("entry_state", "")) or str(pair.get("legacy_to", "")) != str(legacy.get("exit_state", "")):
			issues.append("bridge_catalog_conflict:" + id)
		var official: Dictionary = shadow.get("legacy_action_map", {}).get(id, {})
		if not official.is_empty() and (str(pair.get("bjj_kg_id", "")) != str(official.get("canonical", "")) or str(pair.get("known_semantic_delta", "")) != str(official.get("known_delta", ""))):
			issues.append("bridge_shadow_conflict:" + id)
	for id in mapping:
		if not expected.has(id):
			issues.append("extra_legacy_id:" + str(id))

func ready() -> bool:
	return issues.is_empty() and not mapping.is_empty()

func resolve(technique_id: String, legacy_from: String = "") -> Dictionary:
	if not ready():
		return {"ok": false, "reason": "invalid_bridge", "issues": issues.duplicate()}
	if not mapping.has(technique_id):
		return {"ok": false, "reason": "unmapped_legacy_technique", "legacy_id": technique_id}
	var row: Dictionary = mapping[technique_id]
	if legacy_from != "" and str(row.get("legacy_from", "")) != legacy_from:
		return {"ok": false, "reason": "legacy_state_mismatch", "legacy_id": technique_id}
	var candidate_id := str(row.get("bjj_kg_id", ""))
	var confidence := str(row.get("confidence", "UNMAPPED"))
	var semantic_delta = row.get("known_semantic_delta", null)
	return {
		"ok": true,
		"legacy_id": technique_id,
		"visual_motion_id": technique_id,
		"candidate_bjj_id": candidate_id if candidate_id != "" else null,
		"confidence": confidence,
		"semantic_delta": semantic_delta,
		"mapping_status": "KNOWN_SEMANTIC_DELTA" if semantic_delta != null else ("UNMAPPED" if candidate_id == "" else "PENDING_REVIEW"),
		"safe_to_promote_reducer_authority": false,
		"shipping": false
	}
