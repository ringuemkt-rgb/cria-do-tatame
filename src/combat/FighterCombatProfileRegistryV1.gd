class_name FighterCombatProfileRegistryV1
extends RefCounted

## Read-only, deterministic roster profiles for EXHIBITION preview.
## Does not create a manager, change save, or certify athlete attributes.

const ROSTER_PATH := "res://data/combat/roster_v3.json"
const PROFILES_PATH := "res://data/combat/fighter_profiles_universal_v1.json"
const TECHNIQUES_PATH := "res://data/techniques.json"

var _profiles: Dictionary = {}
var _ordered_ids: Array[String] = []
var _issues: Array[String] = []

func _init() -> void:
	var roster := _json(ROSTER_PATH)
	var source := _json(PROFILES_PATH)
	var catalog := _json(TECHNIQUES_PATH)
	if roster.is_empty() or source.is_empty() or catalog.is_empty():
		_issues.append("required_catalog_missing")
		return
	if bool(source.get("shipping", true)):
		_issues.append("candidate_profiles_must_not_ship")
	if str(source.get("status", "")) != "EXHIBITION_PREVIEW_UNCALIBRATED":
		_issues.append("invalid_profile_status")
	var roster_rows: Array = roster.get("fighters", [])
	var items: Dictionary = source.get("profiles", {})
	var canonical_actions: Dictionary = {}
	for row_value in catalog.get("techniques", []):
		if typeof(row_value) == TYPE_DICTIONARY:
			var row: Dictionary = row_value
			canonical_actions[str(row.get("id", ""))] = row
	if int(roster.get("count", -1)) != roster_rows.size() or roster_rows.size() != items.size():
		_issues.append("roster_profile_coverage_mismatch")
	for value in roster_rows:
		if typeof(value) != TYPE_DICTIONARY:
			_issues.append("invalid_roster_entry")
			continue
		var entry: Dictionary = value
		var id := str(entry.get("id", ""))
		if id == "" or _profiles.has(id) or not items.has(id):
			_issues.append("missing_or_duplicate_fighter:" + id)
			continue
		var profile_value = items[id]
		if typeof(profile_value) != TYPE_DICTIONARY:
			_issues.append("invalid_profile:" + id)
			continue
		var profile: Dictionary = profile_value
		if str(profile.get("id", "")) != id or str(profile.get("display_name", "")) != str(entry.get("display_name", "")) or str(profile.get("signature_trigger", "")) != str(entry.get("signature_trigger", "")):
			_issues.append("profile_identity_mismatch:" + id)
		if bool(profile.get("shipping", true)) or bool(profile.get("human_approved", true)):
			_issues.append("unapproved_profiles_must_be_candidate:" + id)
		var actions: Array = profile.get("technique_repertoire", [])
		if actions.is_empty():
			_issues.append("empty_technique_repertoire:" + id)
		for action_value in actions:
			var action_id := str(action_value)
			if not canonical_actions.has(action_id):
				_issues.append("unknown_technique:" + id + ":" + action_id)
				continue
			var action: Dictionary = canonical_actions[action_id]
			var owner := str(action.get("dono", action.get("owner", "qualquer")))
			if owner != "" and owner != "qualquer" and owner != id:
				_issues.append("technique_owner_violation:" + id + ":" + action_id)
		for action_value in profile.get("preferred_actions", []):
			if not actions.has(action_value):
				_issues.append("preferred_action_not_in_repertoire:" + id)
		for stat_value in profile.get("attributes", {}).values():
			if typeof(stat_value) not in [TYPE_INT, TYPE_FLOAT] or float(stat_value) < 0.0 or float(stat_value) > 120.0:
				_issues.append("invalid_preview_attribute:" + id)
		_profiles[id] = profile.duplicate(true)
		_ordered_ids.append(id)
	_ordered_ids.sort()

func ready() -> bool:
	return _issues.is_empty() and not _profiles.is_empty()

func errors() -> Array[String]:
	return _issues.duplicate()

func fighter_ids() -> Array[String]:
	return _ordered_ids.duplicate()

func profile(fighter_id: String) -> Dictionary:
	return _profiles.get(fighter_id, {}).duplicate(true) if ready() else {}

func has_fighter(fighter_id: String) -> bool:
	return ready() and _profiles.has(fighter_id)

func action_allowed(fighter_id: String, technique_id: String) -> bool:
	if not has_fighter(fighter_id):
		return false
	return _profiles[fighter_id].get("technique_repertoire", []).has(technique_id)

func candidate_stats(fighter_id: String) -> Dictionary:
	return profile(fighter_id).get("attributes", {}).duplicate(true)

func prepare_exhibition(player_id: String, opponent_id: String, arena_id: String) -> Dictionary:
	if not ready():
		return {"ok": false, "error": "fighter_profiles_invalid", "issues": errors()}
	if player_id == opponent_id:
		return {"ok": false, "error": "same_fighter"}
	if not has_fighter(player_id) or not has_fighter(opponent_id):
		return {"ok": false, "error": "fighter_not_in_canonical_roster"}
	if arena_id == "":
		return {"ok": false, "error": "arena_missing"}
	return {
		"ok": true,
		"mode": "exhibition_preview",
		"player_id": player_id,
		"opponent_id": opponent_id,
		"arena_id": arena_id,
		"rules_authority": "existing_CombatManager",
		"shipping": false,
		"tuning_status": "UNCALIBRATED_CANDIDATE",
		"campaign_mutation_allowed": false
	}

static func _json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var value = JSON.parse_string(file.get_as_text())
	file.close()
	return value if typeof(value) == TYPE_DICTIONARY else {}
