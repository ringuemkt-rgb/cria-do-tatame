extends Node

var relations: Dictionary = {
	"os_aleluia": 0.0,
	"la_ele_mil_vezes": 0.0,
	"nos_tem_um_molho": 0.0,
	"terreiro": 50.0,
	"raiz": 20.0
}

var heat: Dictionary = {
	"os_aleluia": 0.0,
	"la_ele_mil_vezes": 0.0,
	"nos_tem_um_molho": 0.0
}

var faction_flags: Dictionary = {}

func reset() -> void:
	relations = {"os_aleluia": 0.0, "la_ele_mil_vezes": 0.0, "nos_tem_um_molho": 0.0, "terreiro": 50.0, "raiz": 20.0}
	heat = {"os_aleluia": 0.0, "la_ele_mil_vezes": 0.0, "nos_tem_um_molho": 0.0}
	faction_flags = {}

func apply_choice_effects(effects: Dictionary) -> Dictionary:
	for faction_value in relations.keys():
		var faction_id: String = str(faction_value)
		if effects.has(faction_id):
			relations[faction_id] = clamp(float(relations[faction_id]) + float(effects[faction_id]), -100.0, 100.0)
	for faction_value in heat.keys():
		var faction_id: String = str(faction_value)
		var heat_key: String = faction_id + "_heat"
		if effects.has(heat_key):
			heat[faction_id] = clamp(float(heat[faction_id]) + float(effects[heat_key]), 0.0, 100.0)
	for axis_value in ["honra", "hype", "sombra", "legado", "moral", "raiz"]:
		var axis: String = str(axis_value)
		if effects.has(axis):
			WorldState.modify_reputation(axis, float(effects[axis]))
	if effects.has("money"):
		WorldState.money += int(effects["money"])
	if effects.has("tinker_event"):
		TinkerBondManager.apply_event(str(effects["tinker_event"]))
	return to_dict()

func apply_mission_choice(choice: Dictionary) -> Dictionary:
	var effects: Dictionary = choice.get("effects", {})
	return apply_choice_effects(effects)

func get_relation(faction_id: String) -> float:
	return float(relations.get(faction_id, 0.0))

func get_heat(faction_id: String) -> float:
	return float(heat.get(faction_id, 0.0))

func get_status_label(faction_id: String) -> String:
	var value: float = get_relation(faction_id)
	if value >= 50.0:
		return "aliado_instavel"
	if value <= -50.0:
		return "hostil"
	if value < 0.0:
		return "desconfiado"
	return "neutro"

func to_dict() -> Dictionary:
	return {"relations": relations, "heat": heat, "faction_flags": faction_flags}

func load_from_dict(data: Dictionary) -> void:
	relations = data.get("relations", relations)
	heat = data.get("heat", heat)
	faction_flags = data.get("faction_flags", {})
