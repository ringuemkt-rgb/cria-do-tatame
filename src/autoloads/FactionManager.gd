extends Node

const FactionIdentityV4 = preload("res://src/factions/FactionIdentityV4.gd")
const STATE_VERSION := 2
const ACTIVE_FACTIONS := ["ALE", "LEM", "NTM"]
const ALL_FACTIONS := ACTIVE_FACTIONS
const DEFAULT_RELATIONS := {
	"ALE": 0.0,
	"LEM": 0.0,
	"NTM": 0.0
}
const DEFAULT_HEAT := {
	"ALE": 0.0,
	"LEM": 0.0,
	"NTM": 0.0
}

var relations: Dictionary = DEFAULT_RELATIONS.duplicate(true)
var heat: Dictionary = DEFAULT_HEAT.duplicate(true)
var faction_flags: Dictionary = {}
var legacy_archive: Dictionary = {
	"relations": {},
	"heat": {},
	"faction_flags": {}
}

func _ready() -> void:
	_ensure_defaults()

func reset() -> void:
	relations = DEFAULT_RELATIONS.duplicate(true)
	heat = DEFAULT_HEAT.duplicate(true)
	faction_flags = {}
	legacy_archive = {
		"relations": {},
		"heat": {},
		"faction_flags": {}
	}

func canonicalize_faction_id(faction_id: String) -> String:
	return FactionIdentityV4.canonical_id(faction_id)

func is_active_faction(faction_id: String) -> bool:
	return FactionIdentityV4.is_active(faction_id)

func get_active_factions() -> Array:
	return ACTIVE_FACTIONS.duplicate()

func get_legacy_id(faction_id: String) -> String:
	return FactionIdentityV4.legacy_id(faction_id)

func get_display_name(faction_id: String) -> String:
	return FactionIdentityV4.display_name(faction_id)

func _ensure_defaults() -> void:
	for faction_id_value in ACTIVE_FACTIONS:
		var faction_id: String = str(faction_id_value)
		if not relations.has(faction_id):
			relations[faction_id] = float(DEFAULT_RELATIONS.get(faction_id, 0.0))
		if not heat.has(faction_id):
			heat[faction_id] = float(DEFAULT_HEAT.get(faction_id, 0.0))
		if not faction_flags.has(faction_id):
			faction_flags[faction_id] = {}

func apply_choice_effects(effects: Dictionary) -> Dictionary:
	_ensure_defaults()
	for effect_key_value in effects.keys():
		var effect_key := str(effect_key_value)
		if effect_key.ends_with("_heat"):
			var heat_source := effect_key.trim_suffix("_heat")
			var heat_faction := canonicalize_faction_id(heat_source)
			if heat_faction != "":
				apply_heat_delta(heat_faction, float(effects[effect_key_value]), "choice_effect")
			continue
		var relation_faction := canonicalize_faction_id(effect_key)
		if relation_faction != "":
			apply_relation_delta(relation_faction, float(effects[effect_key_value]), "choice_effect")
	for axis_value in ["honra", "hype", "sombra", "legado", "moral", "raiz"]:
		var axis: String = str(axis_value)
		if effects.has(axis):
			WorldState.modify_reputation(axis, float(effects[axis]))
	if effects.has("money"):
		WorldState.money += int(effects["money"])
	if effects.has("tinker_event") and has_node("/root/TinkerBondManager"):
		TinkerBondManager.apply_event(str(effects["tinker_event"]))
	return to_dict()

func apply_mission_choice(choice: Dictionary) -> Dictionary:
	return apply_choice_effects(choice.get("effects", {}))

func apply_relation_delta(faction_id: String, delta: float, reason: String = "system") -> float:
	_ensure_defaults()
	var canonical := canonicalize_faction_id(faction_id)
	if canonical == "":
		return 0.0
	var old_value: float = float(relations.get(canonical, 0.0))
	var new_value: float = clampf(old_value + delta, -100.0, 100.0)
	relations[canonical] = new_value
	if SignalBus.has_signal("faction_relation_changed"):
		SignalBus.faction_relation_changed.emit(canonical, delta, new_value, reason)
	return new_value

func apply_heat_delta(faction_id: String, delta: float, reason: String = "system") -> float:
	_ensure_defaults()
	var canonical := canonicalize_faction_id(faction_id)
	if canonical == "":
		return 0.0
	var old_value: float = float(heat.get(canonical, 0.0))
	var new_value: float = clampf(old_value + delta, 0.0, 100.0)
	heat[canonical] = new_value
	if SignalBus.has_signal("faction_heat_changed"):
		SignalBus.faction_heat_changed.emit(canonical, delta, new_value, reason)
	return new_value

func set_flag(faction_id: String, flag_id: String, value: Variant = true) -> void:
	var canonical := canonicalize_faction_id(faction_id)
	if canonical == "":
		var archived_flags: Dictionary = legacy_archive.get("faction_flags", {})
		var archived_faction: Dictionary = archived_flags.get(faction_id, {})
		archived_faction[flag_id] = value
		archived_flags[faction_id] = archived_faction
		legacy_archive["faction_flags"] = archived_flags
		return
	var faction_data: Dictionary = faction_flags.get(canonical, {})
	faction_data[flag_id] = value
	faction_flags[canonical] = faction_data

func get_flag(faction_id: String, flag_id: String, fallback: Variant = false) -> Variant:
	var canonical := canonicalize_faction_id(faction_id)
	if canonical != "":
		return faction_flags.get(canonical, {}).get(flag_id, fallback)
	return legacy_archive.get("faction_flags", {}).get(faction_id, {}).get(flag_id, fallback)

func get_relation(faction_id: String) -> float:
	_ensure_defaults()
	var canonical := canonicalize_faction_id(faction_id)
	if canonical == "":
		return float(legacy_archive.get("relations", {}).get(faction_id, 0.0))
	return float(relations.get(canonical, 0.0))

func get_heat(faction_id: String) -> float:
	_ensure_defaults()
	var canonical := canonicalize_faction_id(faction_id)
	if canonical == "":
		return float(legacy_archive.get("heat", {}).get(faction_id, 0.0))
	return float(heat.get(canonical, 0.0))

func get_status_label(faction_id: String) -> String:
	var value: float = get_relation(faction_id)
	if value >= 70.0:
		return "aliado_firme"
	if value >= 50.0:
		return "aliado_instavel"
	if value <= -70.0:
		return "inimigo_declarado"
	if value <= -50.0:
		return "hostil"
	if value < 0.0:
		return "desconfiado"
	return "neutro"

func to_dict() -> Dictionary:
	_ensure_defaults()
	return {
		"state_version": STATE_VERSION,
		"active_faction_ids": ACTIVE_FACTIONS.duplicate(),
		"relations": relations.duplicate(true),
		"heat": heat.duplicate(true),
		"faction_flags": faction_flags.duplicate(true),
		"legacy_archive": legacy_archive.duplicate(true)
	}

func load_from_dict(data: Dictionary) -> void:
	reset()
	if data.is_empty():
		_ensure_defaults()
		return
	var incoming_archive: Dictionary = data.get("legacy_archive", {})
	for archive_key_value in ["relations", "heat", "faction_flags"]:
		var archive_key := str(archive_key_value)
		if typeof(incoming_archive.get(archive_key, {})) == TYPE_DICTIONARY:
			legacy_archive[archive_key] = incoming_archive.get(archive_key, {}).duplicate(true)
	_load_numeric_map(data.get("relations", {}), relations, -100.0, 100.0, "relations")
	_load_numeric_map(data.get("heat", {}), heat, 0.0, 100.0, "heat")
	_load_flag_map(data.get("faction_flags", {}))
	_ensure_defaults()

func _load_numeric_map(source: Dictionary, target: Dictionary, minimum: float, maximum: float, archive_key: String) -> void:
	for canonical_value in ACTIVE_FACTIONS:
		var canonical := str(canonical_value)
		var legacy := get_legacy_id(canonical)
		if source.has(canonical):
			target[canonical] = clampf(float(source[canonical]), minimum, maximum)
		elif legacy != "" and source.has(legacy):
			target[canonical] = clampf(float(source[legacy]), minimum, maximum)
	var archived: Dictionary = legacy_archive.get(archive_key, {})
	for source_key_value in source.keys():
		var source_key := str(source_key_value)
		if canonicalize_faction_id(source_key) == "":
			archived[source_key] = source[source_key_value]
	legacy_archive[archive_key] = archived

func _load_flag_map(source: Dictionary) -> void:
	for canonical_value in ACTIVE_FACTIONS:
		var canonical := str(canonical_value)
		var legacy := get_legacy_id(canonical)
		if source.has(canonical) and typeof(source[canonical]) == TYPE_DICTIONARY:
			faction_flags[canonical] = source[canonical].duplicate(true)
		elif legacy != "" and source.has(legacy) and typeof(source[legacy]) == TYPE_DICTIONARY:
			faction_flags[canonical] = source[legacy].duplicate(true)
	var archived: Dictionary = legacy_archive.get("faction_flags", {})
	for source_key_value in source.keys():
		var source_key := str(source_key_value)
		if canonicalize_faction_id(source_key) == "":
			archived[source_key] = source[source_key_value]
	legacy_archive["faction_flags"] = archived
