extends RefCounted

const ACTIVE_IDS := ["ALE", "LEM", "NTM"]
const LEGACY_TO_CANON := {
	"os_aleluia": "ALE",
	"la_ele_mil_vezes": "LEM",
	"nos_tem_um_molho": "NTM"
}
const CANON_TO_LEGACY := {
	"ALE": "os_aleluia",
	"LEM": "la_ele_mil_vezes",
	"NTM": "nos_tem_um_molho"
}
const DISPLAY_NAMES := {
	"ALE": "Os Aleluiados",
	"LEM": "Lá Ele Mil Vezes",
	"NTM": "Nós Tem Um Molho"
}
const NON_FACTION_DOMAINS := [
	"terreiro",
	"raiz",
	"atalhos",
	"circuito_oficial",
	"cria_live",
	"dragao_vermelho",
	"fantasma"
]

static func canonical_id(value: Variant) -> String:
	var raw := str(value).strip_edges()
	if raw == "":
		return ""
	var upper := raw.to_upper()
	if ACTIVE_IDS.has(upper):
		return upper
	return str(LEGACY_TO_CANON.get(raw, ""))

static func is_active(value: Variant) -> bool:
	return canonical_id(value) != ""

static func legacy_id(value: Variant) -> String:
	var canonical := canonical_id(value)
	return str(CANON_TO_LEGACY.get(canonical, ""))

static func display_name(value: Variant) -> String:
	var canonical := canonical_id(value)
	return str(DISPLAY_NAMES.get(canonical, str(value)))

static func canonicalize_list(values: Array) -> Array:
	var output: Array = []
	for value in values:
		var canonical := canonical_id(value)
		if canonical != "" and not output.has(canonical):
			output.append(canonical)
	return output

static func migrate_director_state(data: Dictionary) -> Dictionary:
	if data.is_empty():
		return {}
	var migrated := data.duplicate(true)
	var archive: Dictionary = migrated.get("legacy_archive", {}).duplicate(true)
	archive["factions"] = archive.get("factions", {}).duplicate(true)
	archive["champions"] = archive.get("champions", {}).duplicate(true)
	archive["conflicts"] = archive.get("conflicts", []).duplicate(true)
	archive["operations"] = archive.get("operations", []).duplicate(true)
	archive["memories"] = archive.get("memories", []).duplicate(true)
	archive["debts"] = archive.get("debts", []).duplicate(true)
	archive["territory_ownership"] = archive.get("territory_ownership", {}).duplicate(true)

	migrated["factions"] = _migrate_factions(data.get("factions", {}), archive)
	migrated["champions"] = _migrate_keyed_records(data.get("champions", {}), archive["champions"])
	migrated["territories"] = _migrate_territories(data.get("territories", {}), archive)
	migrated["conflicts"] = _migrate_conflicts(data.get("conflicts", {}), archive)
	migrated["active_operations"] = _migrate_operations(data.get("active_operations", []), archive)
	migrated["operation_history"] = _migrate_operations(data.get("operation_history", []), archive)
	migrated["memories"] = _migrate_records_with_faction(data.get("memories", []), "faction_id", archive["memories"])
	migrated["debts"] = _migrate_records_with_faction(data.get("debts", []), "faction_id", archive["debts"])
	migrated["pending_hooks"] = _migrate_records_with_faction(data.get("pending_hooks", []), "faction_id", archive["operations"])
	migrated["legacy_archive"] = archive
	migrated["version"] = 2
	migrated["migration_id"] = "factions_v4_2"
	migrated["active_faction_ids"] = ACTIVE_IDS.duplicate()
	for required_key in ["pressure", "debts", "memories", "active_operations", "operation_history", "pending_hooks"]:
		if not migrated.has(required_key):
			migrated[required_key] = {} if required_key == "pressure" else []
	return migrated

static func _migrate_factions(source: Dictionary, archive: Dictionary) -> Dictionary:
	var output: Dictionary = {}
	for canonical_value in ACTIVE_IDS:
		var canonical := str(canonical_value)
		var legacy := str(CANON_TO_LEGACY[canonical])
		var record: Dictionary = {}
		if source.has(canonical) and typeof(source[canonical]) == TYPE_DICTIONARY:
			record = source[canonical].duplicate(true)
		elif source.has(legacy) and typeof(source[legacy]) == TYPE_DICTIONARY:
			record = source[legacy].duplicate(true)
		if not record.is_empty():
			record["id"] = canonical
			record["legacy_id"] = legacy
			record["name"] = DISPLAY_NAMES[canonical]
			output[canonical] = record
	for key_value in source.keys():
		var key := str(key_value)
		if canonical_id(key) == "":
			archive["factions"][key] = source[key_value]
	return output

static func _migrate_keyed_records(source: Dictionary, archive_target: Dictionary) -> Dictionary:
	var output: Dictionary = {}
	for key_value in source.keys():
		var key := str(key_value)
		var canonical := canonical_id(key)
		if canonical == "":
			archive_target[key] = source[key_value]
			continue
		if not output.has(canonical) or key == canonical:
			output[canonical] = source[key_value].duplicate(true) if typeof(source[key_value]) == TYPE_DICTIONARY else source[key_value]
	return output

static func _migrate_territories(source: Dictionary, archive: Dictionary) -> Dictionary:
	var output: Dictionary = {}
	for territory_id_value in source.keys():
		var territory_id := str(territory_id_value)
		if typeof(source[territory_id_value]) != TYPE_DICTIONARY:
			continue
		var territory: Dictionary = source[territory_id_value].duplicate(true)
		var raw_owner := str(territory.get("owner", "neutral"))
		var canonical_owner := canonical_id(raw_owner)
		if raw_owner != "neutral" and canonical_owner == "":
			archive["territory_ownership"][territory_id] = raw_owner
		territory["owner"] = canonical_owner if canonical_owner != "" else "neutral"
		territory["challengers"] = canonicalize_list(territory.get("challengers", []))
		var influence: Dictionary = {}
		var legacy_influence: Dictionary = {}
		for faction_value in territory.get("influence_by_faction", {}).keys():
			var raw_faction := str(faction_value)
			var canonical := canonical_id(raw_faction)
			if canonical == "":
				legacy_influence[raw_faction] = territory["influence_by_faction"][faction_value]
			else:
				influence[canonical] = maxf(float(influence.get(canonical, 0.0)), float(territory["influence_by_faction"][faction_value]))
		territory["influence_by_faction"] = influence
		if not legacy_influence.is_empty():
			territory["legacy_influence_archive"] = legacy_influence
		output[territory_id] = territory
	return output

static func _migrate_conflicts(source: Dictionary, archive: Dictionary) -> Dictionary:
	var output: Dictionary = {}
	for conflict_value in source.values():
		if typeof(conflict_value) != TYPE_DICTIONARY:
			continue
		var conflict: Dictionary = conflict_value.duplicate(true)
		var a := canonical_id(conflict.get("a", ""))
		var b := canonical_id(conflict.get("b", ""))
		if a == "" or b == "" or a == b:
			archive["conflicts"].append(conflict)
			continue
		var first: String = a if a < b else b
		var second: String = b if a < b else a
		var key := "%s|%s" % [first, second]
		conflict["id"] = key
		conflict["a"] = first
		conflict["b"] = second
		if not output.has(key) or float(conflict.get("intensity", 0.0)) > float(output[key].get("intensity", 0.0)):
			output[key] = conflict
	return output

static func _migrate_operations(values: Array, archive: Dictionary) -> Array:
	var output: Array = []
	for value in values:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var operation: Dictionary = value.duplicate(true)
		var actor := canonical_id(operation.get("actor_faction", ""))
		if actor == "":
			archive["operations"].append(operation)
			continue
		operation["actor_faction"] = actor
		var target := canonical_id(operation.get("target_faction", ""))
		operation["target_faction"] = target
		output.append(operation)
	return output

static func _migrate_records_with_faction(values: Array, field: String, archive_target: Array) -> Array:
	var output: Array = []
	for value in values:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var record: Dictionary = value.duplicate(true)
		var canonical := canonical_id(record.get(field, ""))
		if canonical == "":
			archive_target.append(record)
			continue
		record[field] = canonical
		output.append(record)
	return output
