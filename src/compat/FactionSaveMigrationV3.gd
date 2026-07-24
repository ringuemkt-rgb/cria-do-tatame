class_name FactionSaveMigrationV3
extends RefCounted

const TARGET_SAVE_VERSION := 5
const CANONICAL_IDS := ["LEM", "NTM", "ALE"]
const LEGACY_MAP := {
	"la_ele_mil_vezes": "LEM",
	"nos_tem_um_molho": "NTM",
	"os_aleluia": "ALE",
	"lem": "LEM",
	"ntm": "NTM",
	"ale": "ALE",
	"LEM": "LEM",
	"NTM": "NTM",
	"ALE": "ALE",
}
const NON_FACTION_IDS := ["terreiro", "raiz", "cria_live", "circuito_oficial"]
const RETIRED_IDS := ["dragao_vermelho", "fantasma"]

static func migrate(save_data: Dictionary) -> Dictionary:
	var migrated := save_data.duplicate(true)
	var log: Array[String] = []
	var legacy_axes: Dictionary = migrated.get("legacy_axes", {}).duplicate(true)
	var lore: Dictionary = migrated.get("legacy_lore", {}).duplicate(true)

	var faction_state: Dictionary = migrated.get("faction_state", {}).duplicate(true)
	var relations: Dictionary = _canonicalize_numeric_map(faction_state.get("relations", {}), legacy_axes, lore, "relation", log)
	var heat: Dictionary = _canonicalize_numeric_map(faction_state.get("heat", {}), legacy_axes, lore, "heat", log)
	var flags: Dictionary = _canonicalize_nested_map(faction_state.get("faction_flags", {}), legacy_axes, lore, log)
	migrated["faction_state"] = {
		"schema_version": 3,
		"relations": _with_defaults(relations, 0.0),
		"heat": _with_defaults(heat, 0.0),
		"faction_flags": flags,
		"legacy_axes": legacy_axes.duplicate(true),
	}

	if migrated.has("faction_director_state"):
		migrated["faction_director_state"] = _migrate_director_state(migrated.get("faction_director_state", {}), log)

	# Compatibilidade com protótipos muito antigos que gravavam reputação no topo.
	for key in ["faction_reputation", "factions"]:
		if typeof(migrated.get(key, null)) == TYPE_DICTIONARY:
			var extra := _canonicalize_numeric_map(migrated[key], legacy_axes, lore, "relation", log)
			for faction_id in CANONICAL_IDS:
				migrated["faction_state"]["relations"][faction_id] = clampf(
					float(migrated["faction_state"]["relations"].get(faction_id, 0.0)) + float(extra.get(faction_id, 0.0)),
					-100.0,
					100.0
				)
			migrated.erase(key)

	var narrative_flags: Dictionary = migrated.get("narrative_flags", {}).duplicate(true)
	if legacy_axes.has("raiz_relation"):
		narrative_flags["raiz"] = maxi(int(narrative_flags.get("raiz", 0)), int(round(float(legacy_axes["raiz_relation"]))))
	migrated["narrative_flags"] = narrative_flags
	migrated["legacy_axes"] = legacy_axes
	migrated["legacy_lore"] = lore
	migrated["faction_reputation_v3"] = migrated["faction_state"]["relations"].duplicate(true)
	migrated["save_version"] = TARGET_SAVE_VERSION
	migrated["migration_v3_log"] = log
	migrated["migration_v3_applied_at"] = Time.get_datetime_string_from_system()
	return migrated

static func needs_migration(save_data: Dictionary) -> bool:
	if int(save_data.get("save_version", 0)) < TARGET_SAVE_VERSION:
		return true
	var faction_state: Dictionary = save_data.get("faction_state", {})
	if int(faction_state.get("schema_version", 0)) < 3:
		return true
	for container in [faction_state.get("relations", {}), faction_state.get("heat", {}), faction_state.get("faction_flags", {})]:
		if typeof(container) != TYPE_DICTIONARY:
			continue
		for key_value in container.keys():
			if not CANONICAL_IDS.has(str(key_value)):
				return true
	var director: Dictionary = save_data.get("faction_director_state", {})
	for key_value in director.get("factions", {}).keys():
		if not CANONICAL_IDS.has(str(key_value)):
			return true
	return false

static func _canonicalize_numeric_map(source: Dictionary, legacy_axes: Dictionary, lore: Dictionary, suffix: String, log: Array[String]) -> Dictionary:
	var result := {"LEM": 0.0, "NTM": 0.0, "ALE": 0.0}
	for raw_id_value in source.keys():
		var raw_id := str(raw_id_value)
		var value := float(source[raw_id_value])
		var canonical := canonical_id(raw_id)
		if canonical != "":
			result[canonical] = clampf(float(result[canonical]) + value, -100.0 if suffix == "relation" else 0.0, 100.0)
			if raw_id != canonical:
				log.append("%s.%s->%s" % [raw_id, suffix, canonical])
		elif NON_FACTION_IDS.has(raw_id):
			legacy_axes["%s_%s" % [raw_id, suffix]] = value
			log.append("%s.%s->legacy_axes" % [raw_id, suffix])
		elif RETIRED_IDS.has(raw_id):
			lore["conheceu_%s" % raw_id] = true
			lore["%s_%s_final" % [raw_id, suffix]] = value
			log.append("%s.%s->retired_lore" % [raw_id, suffix])
	return result

static func _canonicalize_nested_map(source: Dictionary, legacy_axes: Dictionary, lore: Dictionary, log: Array[String]) -> Dictionary:
	var result := {"LEM": {}, "NTM": {}, "ALE": {}}
	for raw_id_value in source.keys():
		var raw_id := str(raw_id_value)
		var value: Dictionary = source[raw_id_value].duplicate(true) if typeof(source[raw_id_value]) == TYPE_DICTIONARY else {}
		var canonical := canonical_id(raw_id)
		if canonical != "":
			result[canonical].merge(value, true)
		elif NON_FACTION_IDS.has(raw_id):
			legacy_axes["%s_flags" % raw_id] = value
		elif RETIRED_IDS.has(raw_id):
			lore["%s_flags" % raw_id] = value
		log.append("%s.flags->%s" % [raw_id, canonical if canonical != "" else "non_faction"])
	return result

static func _migrate_director_state(source: Dictionary, log: Array[String]) -> Dictionary:
	if source.is_empty():
		return source
	var result := source.duplicate(true)
	result["version"] = 3
	result["factions"] = _merge_entity_map(source.get("factions", {}), log)
	result["champions"] = _merge_entity_map(source.get("champions", {}), log)
	result["territories"] = _migrate_territories(source.get("territories", {}), log)
	result["conflicts"] = _migrate_conflicts(source.get("conflicts", {}), log)
	result["active_operations"] = _migrate_operations(source.get("active_operations", []), log)
	result["operation_history"] = _migrate_operations(source.get("operation_history", []), log)
	result["memories"] = _migrate_records(source.get("memories", []), "faction_id", log)
	result["debts"] = _migrate_records(source.get("debts", []), "faction_id", log)
	return result

static func _merge_entity_map(source: Dictionary, log: Array[String]) -> Dictionary:
	var result := {"LEM": {}, "NTM": {}, "ALE": {}}
	for raw_id_value in source.keys():
		var raw_id := str(raw_id_value)
		var canonical := canonical_id(raw_id)
		if canonical == "":
			continue
		var value: Dictionary = source[raw_id_value].duplicate(true) if typeof(source[raw_id_value]) == TYPE_DICTIONARY else {}
		value["id"] = canonical
		if result[canonical].is_empty():
			result[canonical] = value
		else:
			result[canonical] = _merge_runtime_entity(result[canonical], value)
		if raw_id != canonical:
			log.append("director.%s->%s" % [raw_id, canonical])
	return result

static func _merge_runtime_entity(a: Dictionary, b: Dictionary) -> Dictionary:
	var result := a.duplicate(true)
	for key_value in b.keys():
		var key := str(key_value)
		if key == "power" and typeof(b[key_value]) == TYPE_DICTIONARY:
			var power: Dictionary = result.get("power", {}).duplicate(true)
			for dimension in b[key_value].keys():
				power[dimension] = maxf(float(power.get(dimension, 0.0)), float(b[key_value][dimension]))
			result["power"] = power
		elif key in ["victories", "defeats", "weeks_trained"]:
			result[key] = int(result.get(key, 0)) + int(b[key_value])
		elif not result.has(key) or result[key] in [null, "", [], {}]:
			result[key] = b[key_value]
	return result

static func _migrate_territories(source: Dictionary, log: Array[String]) -> Dictionary:
	var result: Dictionary = {}
	for territory_id_value in source.keys():
		var territory_id := str(territory_id_value)
		var territory: Dictionary = source[territory_id_value].duplicate(true)
		territory["owner"] = canonical_id(str(territory.get("owner", ""))) if canonical_id(str(territory.get("owner", ""))) != "" else "neutral"
		var challengers: Array = []
		for challenger_value in territory.get("challengers", []):
			var canonical := canonical_id(str(challenger_value))
			if canonical != "" and not challengers.has(canonical):
				challengers.append(canonical)
		territory["challengers"] = challengers
		var influence: Dictionary = {}
		for faction_value in territory.get("influence_by_faction", {}).keys():
			var canonical := canonical_id(str(faction_value))
			if canonical != "":
				influence[canonical] = maxf(float(influence.get(canonical, 0.0)), float(territory["influence_by_faction"][faction_value]))
		territory["influence_by_faction"] = influence
		result[territory_id] = territory
	return result

static func _migrate_conflicts(source: Dictionary, log: Array[String]) -> Dictionary:
	var result: Dictionary = {}
	for conflict_value in source.values():
		if typeof(conflict_value) != TYPE_DICTIONARY:
			continue
		var conflict: Dictionary = conflict_value.duplicate(true)
		var a := canonical_id(str(conflict.get("a", "")))
		var b := canonical_id(str(conflict.get("b", "")))
		if a == "" or b == "" or a == b:
			continue
		var first := a if a < b else b
		var second := b if a < b else a
		var key := "%s|%s" % [first, second]
		conflict["id"] = key
		conflict["a"] = first
		conflict["b"] = second
		if not result.has(key) or float(conflict.get("intensity", 0.0)) > float(result[key].get("intensity", 0.0)):
			result[key] = conflict
	return result

static func _migrate_operations(source: Array, log: Array[String]) -> Array:
	var result: Array = []
	for operation_value in source:
		if typeof(operation_value) != TYPE_DICTIONARY:
			continue
		var operation: Dictionary = operation_value.duplicate(true)
		var actor := canonical_id(str(operation.get("actor_faction", "")))
		var target := canonical_id(str(operation.get("target_faction", "")))
		if actor == "":
			continue
		operation["actor_faction"] = actor
		operation["target_faction"] = target
		result.append(operation)
	return result

static func _migrate_records(source: Array, faction_key: String, log: Array[String]) -> Array:
	var result: Array = []
	for record_value in source:
		if typeof(record_value) != TYPE_DICTIONARY:
			continue
		var record: Dictionary = record_value.duplicate(true)
		var raw_id := str(record.get(faction_key, ""))
		var canonical := canonical_id(raw_id)
		if raw_id != "" and canonical == "":
			record["legacy_%s" % faction_key] = raw_id
			record[faction_key] = ""
		else:
			record[faction_key] = canonical
		result.append(record)
	return result

static func canonical_id(raw_id: String) -> String:
	return str(LEGACY_MAP.get(raw_id, ""))

static func _with_defaults(source: Dictionary, default_value: float) -> Dictionary:
	var result := source.duplicate(true)
	for faction_id in CANONICAL_IDS:
		if not result.has(faction_id):
			result[faction_id] = default_value
	return result
