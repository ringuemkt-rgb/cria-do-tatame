extends Node

const ALL_FACTIONS := [
	"terreiro",
	"os_aleluia",
	"la_ele_mil_vezes",
	"nos_tem_um_molho",
	"raiz",
	"dragao_vermelho",
	"fantasma"
]

const DEFAULT_RELATIONS := {
	"terreiro": 50.0,
	"os_aleluia": 0.0,
	"la_ele_mil_vezes": 0.0,
	"nos_tem_um_molho": 0.0,
	"raiz": 20.0,
	"dragao_vermelho": -10.0,
	"fantasma": 0.0
}

const DEFAULT_HEAT := {
	"terreiro": 0.0,
	"os_aleluia": 0.0,
	"la_ele_mil_vezes": 0.0,
	"nos_tem_um_molho": 0.0,
	"raiz": 0.0,
	"dragao_vermelho": 10.0,
	"fantasma": 5.0
}

var relations: Dictionary = DEFAULT_RELATIONS.duplicate(true)
var heat: Dictionary = DEFAULT_HEAT.duplicate(true)
var faction_flags: Dictionary = {}

func _ready() -> void:
	_ensure_defaults()

func reset() -> void:
	relations = DEFAULT_RELATIONS.duplicate(true)
	heat = DEFAULT_HEAT.duplicate(true)
	faction_flags = {}

func _ensure_defaults() -> void:
	for faction_id in ALL_FACTIONS:
		if not relations.has(faction_id):
			relations[faction_id] = float(DEFAULT_RELATIONS.get(faction_id, 0.0))
		if not heat.has(faction_id):
			heat[faction_id] = float(DEFAULT_HEAT.get(faction_id, 0.0))

func apply_choice_effects(effects: Dictionary) -> Dictionary:
	_ensure_defaults()
	for faction_id in ALL_FACTIONS:
		if effects.has(faction_id):
			apply_relation_delta(faction_id, float(effects[faction_id]), "choice_effect")
		var heat_key := faction_id + "_heat"
		if effects.has(heat_key):
			apply_heat_delta(faction_id, float(effects[heat_key]), "choice_effect")
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

func apply_relation_delta(faction_id: String, delta: float, reason := "system") -> float:
	_ensure_defaults()
	if not relations.has(faction_id):
		return 0.0
	var old_value := float(relations[faction_id])
	var new_value := clamp(old_value + delta, -100.0, 100.0)
	relations[faction_id] = new_value
	if SignalBus.has_signal("faction_relation_changed"):
		SignalBus.faction_relation_changed.emit(faction_id, delta, new_value, reason)
	return new_value

func apply_heat_delta(faction_id: String, delta: float, reason := "system") -> float:
	_ensure_defaults()
	if not heat.has(faction_id):
		return 0.0
	var old_value := float(heat[faction_id])
	var new_value := clamp(old_value + delta, 0.0, 100.0)
	heat[faction_id] = new_value
	if SignalBus.has_signal("faction_heat_changed"):
		SignalBus.faction_heat_changed.emit(faction_id, delta, new_value, reason)
	return new_value

func set_flag(faction_id: String, flag_id: String, value = true) -> void:
	var faction_data: Dictionary = faction_flags.get(faction_id, {})
	faction_data[flag_id] = value
	faction_flags[faction_id] = faction_data

func get_flag(faction_id: String, flag_id: String, fallback = false):
	return faction_flags.get(faction_id, {}).get(flag_id, fallback)

func get_relation(faction_id: String) -> float:
	_ensure_defaults()
	return float(relations.get(faction_id, 0.0))

func get_heat(faction_id: String) -> float:
	_ensure_defaults()
	return float(heat.get(faction_id, 0.0))

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

func to_dict() -> Dictionary:
	_ensure_defaults()
	return {
		"relations": relations.duplicate(true),
		"heat": heat.duplicate(true),
		"faction_flags": faction_flags.duplicate(true)
	}

func load_from_dict(data: Dictionary) -> void:
	relations = DEFAULT_RELATIONS.duplicate(true)
	heat = DEFAULT_HEAT.duplicate(true)
	var saved_relations: Dictionary = data.get("relations", {})
	var saved_heat: Dictionary = data.get("heat", {})
	for faction_id in saved_relations.keys():
		relations[str(faction_id)] = clamp(float(saved_relations[faction_id]), -100.0, 100.0)
	for faction_id in saved_heat.keys():
		heat[str(faction_id)] = clamp(float(saved_heat[faction_id]), 0.0, 100.0)
	faction_flags = data.get("faction_flags", {}).duplicate(true)
	_ensure_defaults()
