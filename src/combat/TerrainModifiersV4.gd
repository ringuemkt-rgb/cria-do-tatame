class_name TerrainModifiersV4
extends RefCounted

const TAGS := {
	"areia_fofa": {"gas_cost_mult":1.25,"movement_mult":0.8},
	"mobilidade_instavel": {"gas_cost_mult":1.12,"defense_threshold_add":0.05},
	"plateia": {"focus_drain_per_sec":0.35,"morale_variance":0.08},
	"por_do_sol": {"defense_threshold_add":0.04,"visual_flash":0.3},
	"strobo": {"focus_drain_per_sec":0.75,"defense_threshold_add":0.08,"visual_flash":0.8},
	"batida_bpm": {"on_beat_effect_mult":1.2,"off_beat_gas_mult":1.3},
	"manto_olhar": {"focus_drain_per_sec":0.9,"dirty_roxo_mult":2.0},
	"lama": {"gas_cost_mult":1.2,"movement_mult":0.72},
	"entulho": {"positional_damage_mult":1.08,"escape_cost_mult":1.15},
	"estreito_vento": {"focus_drain_per_sec":0.25,"defense_threshold_add":0.03},
	"silencio_eco": {"focus_regen_mult":1.25,"defense_threshold_add":-0.04}
}

static func combine(tags: Array, reduced_flash: bool = false) -> Dictionary:
	var output := {
		"gas_cost_mult":1.0,
		"movement_mult":1.0,
		"defense_threshold_add":0.0,
		"focus_drain_per_sec":0.0,
		"focus_regen_mult":1.0,
		"positional_damage_mult":1.0,
		"escape_cost_mult":1.0,
		"dirty_roxo_mult":1.0,
		"on_beat_effect_mult":1.0,
		"off_beat_gas_mult":1.0,
		"visual_flash":0.0,
		"morale_variance":0.0,
	}
	for tag_value in tags:
		var tag := str(tag_value)
		var modifier: Dictionary = TAGS.get(tag, {})
		for key_value in modifier.keys():
			var key := str(key_value)
			var value := float(modifier[key_value])
			if key.ends_with("_mult"):
				output[key] = float(output.get(key, 1.0)) * value
			else:
				output[key] = float(output.get(key, 0.0)) + value
	if reduced_flash:
		output["visual_flash"] = minf(float(output["visual_flash"]), 0.2)
	return output

static func adjusted_cost(cost: Dictionary, modifiers: Dictionary, action_kind: String = "transition", on_beat: bool = true) -> Dictionary:
	var output := cost.duplicate(true)
	var gas_multiplier := float(modifiers.get("gas_cost_mult", 1.0))
	if action_kind == "escape":
		gas_multiplier *= float(modifiers.get("escape_cost_mult", 1.0))
	if not on_beat:
		gas_multiplier *= float(modifiers.get("off_beat_gas_mult", 1.0))
	output["gas"] = int(ceil(float(output.get("gas", 0.0)) * gas_multiplier))
	return output

static func adjusted_damage(base_damage: float, modifiers: Dictionary, on_beat: bool = true) -> float:
	var value := base_damage * float(modifiers.get("positional_damage_mult", 1.0))
	if on_beat:
		value *= float(modifiers.get("on_beat_effect_mult", 1.0))
	return value

static func validate_tags(tags: Array) -> Dictionary:
	var unknown: Array[String] = []
	for value in tags:
		if not TAGS.has(str(value)):
			unknown.append(str(value))
	return {"ok": unknown.is_empty(), "unknown": unknown}
