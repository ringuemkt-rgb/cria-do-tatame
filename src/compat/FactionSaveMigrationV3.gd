class_name FactionSaveMigrationV3
extends RefCounted

const TARGET_SAVE_VERSION := 5
const LEGACY_MAP := {
	"la_ele_mil_vezes": "LEM",
	"nos_tem_um_molho": "NTM",
	"os_aleluia": "ALE"
}
const NON_FACTION_IDS := ["terreiro", "raiz", "cria_live", "circuito_oficial"]
const RETIRED_IDS := ["dragao_vermelho", "fantasma"]

static func migrate(save_data: Dictionary) -> Dictionary:
	var migrated := save_data.duplicate(true)
	var log: Array[String] = []
	var legacy_rep: Dictionary = _extract_legacy_reputation(migrated)
	var canonical_rep := {"LEM": 0, "NTM": 0, "ALE": 0}

	for legacy_id in legacy_rep.keys():
		var value := int(legacy_rep.get(legacy_id, 0))
		if LEGACY_MAP.has(legacy_id):
			var canonical_id: String = LEGACY_MAP[legacy_id]
			canonical_rep[canonical_id] = int(canonical_rep[canonical_id]) + value
			log.append("%s->%s:%d" % [legacy_id, canonical_id, value])
		elif legacy_id == "terreiro":
			migrated["terreiro_reputation"] = value
			log.append("terreiro->local")
		elif legacy_id == "raiz":
			var flags: Dictionary = migrated.get("narrative_flags", {})
			flags["raiz"] = max(int(flags.get("raiz", 0)), value)
			migrated["narrative_flags"] = flags
			log.append("raiz->narrative_flags")
		elif legacy_id == "cria_live":
			var cria_live: Dictionary = migrated.get("cria_live", {})
			cria_live["reputation"] = value
			migrated["cria_live"] = cria_live
			log.append("cria_live->system")
		elif legacy_id in RETIRED_IDS:
			var lore: Dictionary = migrated.get("legacy_lore", {})
			lore["conheceu_%s" % legacy_id] = value != 0
			migrated["legacy_lore"] = lore
			log.append("%s->retired_lore" % legacy_id)

	migrated["faction_reputation_v3"] = canonical_rep
	migrated.erase("faction_reputation")
	migrated.erase("factions")
	migrated["save_version"] = TARGET_SAVE_VERSION
	migrated["migration_v3_log"] = log
	return migrated

static func needs_migration(save_data: Dictionary) -> bool:
	if int(save_data.get("save_version", 0)) < TARGET_SAVE_VERSION:
		return true
	var rep := _extract_legacy_reputation(save_data)
	for legacy_id in LEGACY_MAP.keys() + NON_FACTION_IDS + RETIRED_IDS:
		if rep.has(legacy_id):
			return true
	return false

static func _extract_legacy_reputation(save_data: Dictionary) -> Dictionary:
	if typeof(save_data.get("faction_reputation", {})) == TYPE_DICTIONARY:
		return save_data.get("faction_reputation", {})
	if typeof(save_data.get("factions", {})) == TYPE_DICTIONARY:
		return save_data.get("factions", {})
	return {}
