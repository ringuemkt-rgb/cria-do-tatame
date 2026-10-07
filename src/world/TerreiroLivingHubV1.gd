class_name TerreiroLivingHubV1
extends RefCounted

const CONFIG_PATH := "res://data/world/terreiro_living_hub_v1.json"

var config: Dictionary = {}

func _init(config_data: Dictionary = {}) -> void:
	config = config_data.duplicate(true) if not config_data.is_empty() else _load_json(CONFIG_PATH)

func compose(world_snapshot: Dictionary) -> Dictionary:
	var time_block := str(world_snapshot.get("time_block", "manha"))
	var weather_id := str(world_snapshot.get("current_weather", "nublado_quente"))
	var time_def: Dictionary = config.get("time_blocks", {}).get(time_block, {}).duplicate(true)
	var weather_def: Dictionary = config.get("weather", {}).get(weather_id, {}).duplicate(true)
	var aliases: Array = config.get("hub_aliases", ["terreiro_da_luta", "terreiro"])
	var present: Array = []
	var npc_states: Dictionary = world_snapshot.get("npc_states", {})
	var npc_display: Dictionary = config.get("npc_display", {})
	for npc_id_value in npc_states.keys():
		var npc_id := str(npc_id_value)
		var state_value = npc_states[npc_id]
		if typeof(state_value) != TYPE_DICTIONARY:
			continue
		var npc_state: Dictionary = state_value
		if not bool(npc_state.get("available", true)):
			continue
		if not aliases.has(str(npc_state.get("hub", ""))):
			continue
		var meta: Dictionary = npc_display.get(npc_id, {})
		var activity_id := str(npc_state.get("activity", ""))
		var activity_label := str(config.get("activity_labels", {}).get(activity_id, activity_id.replace("_", " ")))
		present.append({
			"id": npc_id,
			"name": str(meta.get("name", npc_id.replace("_", " ").capitalize())),
			"role": str(meta.get("role", "npc")),
			"activity": activity_id,
			"activity_label": activity_label
		})
	present.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.get("id", "")) < str(b.get("id", "")))

	var ambience: Array[String] = []
	for item in time_def.get("ambience", []):
		_append_unique(ambience, str(item))
	for item in weather_def.get("ambience", []):
		_append_unique(ambience, str(item))
	var cap := maxi(1, int(config.get("max_ambience_layers", 4)))
	if ambience.size() > cap:
		ambience.resize(cap)

	return {
		"time_block": time_block,
		"time_label": str(time_def.get("label", time_block.to_upper())),
		"weather": weather_id,
		"weather_label": str(weather_def.get("label", weather_id.replace("_", " ").to_upper())),
		"focus": str(time_def.get("focus", "TREINO LIVRE")),
		"crowd": str(time_def.get("crowd", "baixo")),
		"light": str(time_def.get("light", "day")),
		"present_npcs": present,
		"ambience_layers": ambience,
		"active_events": world_snapshot.get("active_events", []).duplicate(true),
		"headline": "%s • %s • %s" % [
			str(time_def.get("label", time_block.to_upper())),
			str(weather_def.get("label", weather_id.replace("_", " ").to_upper())),
			str(time_def.get("focus", "TREINO LIVRE"))
		]
	}

func presence_text(composed: Dictionary) -> String:
	var present: Array = composed.get("present_npcs", [])
	if present.is_empty():
		return str(config.get("empty_presence_text", "Terreiro quieto."))
	var parts: Array[String] = []
	for raw in present:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = raw
		parts.append("%s — %s" % [str(item.get("name", "NPC")), str(item.get("activity_label", "presente"))])
	return " • ".join(parts)

func ambience_text(composed: Dictionary) -> String:
	var layers: Array = composed.get("ambience_layers", [])
	if layers.is_empty():
		return "Ambiente: silencioso"
	var names: Array[String] = []
	for value in layers:
		names.append(str(value).replace("_", " "))
	return "Ambiente: %s" % ", ".join(names)

func _append_unique(target: Array[String], value: String) -> void:
	if value != "" and not target.has(value):
		target.append(value)

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}
