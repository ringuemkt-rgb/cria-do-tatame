extends Node

## Fachada canônica v3. O domínio ativo possui exatamente três facções.
## IDs legados continuam aceitos como entrada durante uma release, mas nunca são
## devolvidos como facções ativas nem serializados como entidades independentes.

const ALL_FACTIONS := ["LEM", "NTM", "ALE"]
const LEGACY_ALIASES := {
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
const NON_FACTION_AXES := ["terreiro", "raiz", "cria_live", "circuito_oficial"]
const RETIRED_IDS := ["dragao_vermelho", "fantasma"]
const DEFAULT_RELATIONS := {"LEM": 0.0, "NTM": 0.0, "ALE": 0.0}
const DEFAULT_HEAT := {"LEM": 0.0, "NTM": 0.0, "ALE": 0.0}
const DEFAULT_LEGACY_AXES := {
	"terreiro_relation": 50.0,
	"terreiro_heat": 0.0,
	"raiz_relation": 20.0,
	"raiz_heat": 0.0,
	"cria_live_relation": 0.0,
	"cria_live_heat": 0.0,
	"circuito_oficial_relation": 0.0,
	"circuito_oficial_heat": 0.0,
}

var relations: Dictionary = DEFAULT_RELATIONS.duplicate(true)
var heat: Dictionary = DEFAULT_HEAT.duplicate(true)
var faction_flags: Dictionary = {"LEM": {}, "NTM": {}, "ALE": {}}
var legacy_axes: Dictionary = DEFAULT_LEGACY_AXES.duplicate(true)
var retired_lore: Dictionary = {}

func _ready() -> void:
	_ensure_defaults()

func reset() -> void:
	relations = DEFAULT_RELATIONS.duplicate(true)
	heat = DEFAULT_HEAT.duplicate(true)
	faction_flags = {"LEM": {}, "NTM": {}, "ALE": {}}
	legacy_axes = DEFAULT_LEGACY_AXES.duplicate(true)
	retired_lore = {}

func canonical_id(raw_id: String) -> String:
	return str(LEGACY_ALIASES.get(raw_id, ""))

func is_canonical_faction(raw_id: String) -> bool:
	return ALL_FACTIONS.has(raw_id)

func is_faction_input(raw_id: String) -> bool:
	return canonical_id(raw_id) != ""

func _ensure_defaults() -> void:
	for faction_id in ALL_FACTIONS:
		if not relations.has(faction_id):
			relations[faction_id] = float(DEFAULT_RELATIONS[faction_id])
		if not heat.has(faction_id):
			heat[faction_id] = float(DEFAULT_HEAT[faction_id])
		if not faction_flags.has(faction_id) or typeof(faction_flags[faction_id]) != TYPE_DICTIONARY:
			faction_flags[faction_id] = {}
	for key_value in DEFAULT_LEGACY_AXES.keys():
		if not legacy_axes.has(key_value):
			legacy_axes[key_value] = DEFAULT_LEGACY_AXES[key_value]
	# Remove qualquer ID que tenha escapado de um estado antigo.
	for container in [relations, heat, faction_flags]:
		for key_value in container.keys():
			if not ALL_FACTIONS.has(str(key_value)):
				container.erase(key_value)

func apply_choice_effects(effects: Dictionary) -> Dictionary:
	_ensure_defaults()
	for effect_key_value in effects.keys():
		var effect_key := str(effect_key_value)
		if effect_key.ends_with("_heat"):
			var source_id := effect_key.trim_suffix("_heat")
			if is_faction_input(source_id) or NON_FACTION_AXES.has(source_id) or RETIRED_IDS.has(source_id):
				apply_heat_delta(source_id, float(effects[effect_key_value]), "choice_effect")
			continue
		if is_faction_input(effect_key):
			apply_relation_delta(effect_key, float(effects[effect_key_value]), "choice_effect")
		elif NON_FACTION_AXES.has(effect_key):
			apply_relation_delta(effect_key, float(effects[effect_key_value]), "choice_effect")

	for axis_value in ["honra", "hype", "sombra", "legado", "moral", "raiz"]:
		var axis := str(axis_value)
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
	var canonical := canonical_id(faction_id)
	if canonical != "":
		var old_value := float(relations.get(canonical, 0.0))
		var new_value := clampf(old_value + delta, -100.0, 100.0)
		relations[canonical] = new_value
		if SignalBus.has_signal("faction_relation_changed"):
			SignalBus.faction_relation_changed.emit(canonical, delta, new_value, reason)
		return new_value
	if NON_FACTION_AXES.has(faction_id):
		var key := "%s_relation" % faction_id
		legacy_axes[key] = clampf(float(legacy_axes.get(key, 0.0)) + delta, -100.0, 100.0)
		return float(legacy_axes[key])
	if RETIRED_IDS.has(faction_id):
		retired_lore["%s_relation_attempt" % faction_id] = float(retired_lore.get("%s_relation_attempt" % faction_id, 0.0)) + delta
	return 0.0

func apply_heat_delta(faction_id: String, delta: float, reason: String = "system") -> float:
	_ensure_defaults()
	var canonical := canonical_id(faction_id)
	if canonical != "":
		var old_value := float(heat.get(canonical, 0.0))
		var new_value := clampf(old_value + delta, 0.0, 100.0)
		heat[canonical] = new_value
		if SignalBus.has_signal("faction_heat_changed"):
			SignalBus.faction_heat_changed.emit(canonical, delta, new_value, reason)
		return new_value
	if NON_FACTION_AXES.has(faction_id):
		var key := "%s_heat" % faction_id
		legacy_axes[key] = clampf(float(legacy_axes.get(key, 0.0)) + delta, 0.0, 100.0)
		return float(legacy_axes[key])
	if RETIRED_IDS.has(faction_id):
		retired_lore["%s_heat_attempt" % faction_id] = float(retired_lore.get("%s_heat_attempt" % faction_id, 0.0)) + delta
	return 0.0

func set_flag(faction_id: String, flag_id: String, value: Variant = true) -> void:
	var canonical := canonical_id(faction_id)
	if canonical != "":
		var faction_data: Dictionary = faction_flags.get(canonical, {})
		faction_data[flag_id] = value
		faction_flags[canonical] = faction_data
	elif NON_FACTION_AXES.has(faction_id):
		var axis_flags: Dictionary = legacy_axes.get("%s_flags" % faction_id, {})
		axis_flags[flag_id] = value
		legacy_axes["%s_flags" % faction_id] = axis_flags
	elif RETIRED_IDS.has(faction_id):
		var lore_flags: Dictionary = retired_lore.get("%s_flags" % faction_id, {})
		lore_flags[flag_id] = value
		retired_lore["%s_flags" % faction_id] = lore_flags

func get_flag(faction_id: String, flag_id: String, fallback: Variant = false) -> Variant:
	var canonical := canonical_id(faction_id)
	if canonical != "":
		return faction_flags.get(canonical, {}).get(flag_id, fallback)
	if NON_FACTION_AXES.has(faction_id):
		return legacy_axes.get("%s_flags" % faction_id, {}).get(flag_id, fallback)
	if RETIRED_IDS.has(faction_id):
		return retired_lore.get("%s_flags" % faction_id, {}).get(flag_id, fallback)
	return fallback

func get_relation(faction_id: String) -> float:
	_ensure_defaults()
	var canonical := canonical_id(faction_id)
	if canonical != "":
		return float(relations.get(canonical, 0.0))
	if NON_FACTION_AXES.has(faction_id):
		return float(legacy_axes.get("%s_relation" % faction_id, 0.0))
	return 0.0

func get_heat(faction_id: String) -> float:
	_ensure_defaults()
	var canonical := canonical_id(faction_id)
	if canonical != "":
		return float(heat.get(canonical, 0.0))
	if NON_FACTION_AXES.has(faction_id):
		return float(legacy_axes.get("%s_heat" % faction_id, 0.0))
	return 0.0

func get_status_label(faction_id: String) -> String:
	var value := get_relation(faction_id)
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

func get_active_factions() -> Array[String]:
	return ["LEM", "NTM", "ALE"]

func to_dict() -> Dictionary:
	_ensure_defaults()
	return {
		"schema_version": 3,
		"relations": relations.duplicate(true),
		"heat": heat.duplicate(true),
		"faction_flags": faction_flags.duplicate(true),
		"legacy_axes": legacy_axes.duplicate(true),
		"retired_lore": retired_lore.duplicate(true),
	}

func load_from_dict(data: Dictionary) -> void:
	reset()
	var saved_relations: Dictionary = data.get("relations", {})
	var saved_heat: Dictionary = data.get("heat", {})
	for faction_id_value in saved_relations.keys():
		var raw_id := str(faction_id_value)
		var canonical := canonical_id(raw_id)
		if canonical != "":
			relations[canonical] = clampf(float(relations.get(canonical, 0.0)) + float(saved_relations[faction_id_value]), -100.0, 100.0)
		elif NON_FACTION_AXES.has(raw_id):
			legacy_axes["%s_relation" % raw_id] = clampf(float(saved_relations[faction_id_value]), -100.0, 100.0)
		elif RETIRED_IDS.has(raw_id):
			retired_lore["%s_relation_final" % raw_id] = float(saved_relations[faction_id_value])
	for faction_id_value in saved_heat.keys():
		var raw_id := str(faction_id_value)
		var canonical := canonical_id(raw_id)
		if canonical != "":
			heat[canonical] = clampf(maxf(float(heat.get(canonical, 0.0)), float(saved_heat[faction_id_value])), 0.0, 100.0)
		elif NON_FACTION_AXES.has(raw_id):
			legacy_axes["%s_heat" % raw_id] = clampf(float(saved_heat[faction_id_value]), 0.0, 100.0)
		elif RETIRED_IDS.has(raw_id):
			retired_lore["%s_heat_final" % raw_id] = float(saved_heat[faction_id_value])
	var saved_flags: Dictionary = data.get("faction_flags", {})
	for faction_id_value in saved_flags.keys():
		var raw_id := str(faction_id_value)
		var canonical := canonical_id(raw_id)
		if canonical != "" and typeof(saved_flags[faction_id_value]) == TYPE_DICTIONARY:
			faction_flags[canonical].merge(saved_flags[faction_id_value], true)
		elif NON_FACTION_AXES.has(raw_id):
			legacy_axes["%s_flags" % raw_id] = saved_flags[faction_id_value]
		elif RETIRED_IDS.has(raw_id):
			retired_lore["%s_flags" % raw_id] = saved_flags[faction_id_value]
	legacy_axes.merge(data.get("legacy_axes", {}), true)
	retired_lore.merge(data.get("retired_lore", {}), true)
	_ensure_defaults()
