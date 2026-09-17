class_name MapAtlasPresenter
extends RefCounted
## Presentation only. Travel = WorldMapManager. Time/weather = WorldDirectorManager.
## NPC schedule = NPCEcologyEngineV1. Combat = CombatManager. Not an autoload.

const ATLAS_PATH := "res://data/maps/map_atlas_runtime_v1.json"
const MAP_V4_PATH := "res://data/world/world_map_v4.json"
const MOON_PATH := "res://data/world/moon_tide_v01.json"
const PAGE_DIR := "res://data/maps/pages/"

var atlas: Dictionary = {}
var world_map: Dictionary = {}
var moon_data: Dictionary = {}
var current_page: String = "02"

func load_defs() -> void:
	atlas = _load_json(ATLAS_PATH)
	world_map = _load_json(MAP_V4_PATH)
	moon_data = _load_json(MOON_PATH)

func set_page(page_id: String) -> void:
	current_page = page_id

func moon_index(week: int = -1, day_index: int = -1) -> int:
	var w := week if week >= 0 else int(WorldState.week)
	var d := day_index if day_index >= 0 else int(WorldState.day_index)
	var cycle := maxi(1, int(moon_data.get("cycle_days", 8)))
	return posmod(w * 7 + d, cycle)

func moon_phase() -> Dictionary:
	var idx := moon_index()
	var phases: Array = moon_data.get("phases", [])
	if idx >= 0 and idx < phases.size() and typeof(phases[idx]) == TYPE_DICTIONARY:
		return phases[idx]
	return {"index": idx, "id": "nova", "label": "Lua nova"}

func tide_id() -> String:
	var phase: Dictionary = moon_phase()
	var bias := str(phase.get("tide_bias", "enchente"))
	var block := "manha"
	if has_node_world_director():
		block = str(WorldDirectorManager.state.get("time_block", "manha"))
	var table: Dictionary = moon_data.get("tide_by_block", {}).get(block, {})
	return str(table.get(bias, bias))

func has_node_world_director() -> bool:
	return Engine.get_main_loop() != null and Engine.get_main_loop().root != null and Engine.get_main_loop().root.has_node("/root/WorldDirectorManager")

func weather_id_for_page(page: String = "") -> String:
	var page_now := page if page != "" else current_page
	var region := _region_for_page(page_now)
	if has_node_world_director():
		var by_region: Dictionary = WorldDirectorManager.state.get("weather_by_region", {})
		return str(by_region.get(region, "nublado_quente"))
	return "nublado_quente"

func shader_params(page: String = "") -> Dictionary:
	var page_now := page if page != "" else current_page
	var weather := weather_id_for_page(page_now)
	var mapped: Dictionary = atlas.get("weather_to_preset", {}).get(weather, {"preset": 0, "rain": 0.0, "water_speed": 0.07}).duplicate(true)
	var block := "tarde"
	if has_node_world_director():
		block = str(WorldDirectorManager.state.get("time_block", "tarde"))
	if block in ["noite", "madrugada"] and int(mapped.get("preset", 0)) == 0:
		mapped["preset"] = 2
	mapped["weather"] = weather
	mapped["time_block"] = block
	mapped["moon"] = moon_phase()
	mapped["tide"] = tide_id()
	mapped["amp_px"] = minf(2.0, float(atlas.get("layers", {}).get("L0_water", {}).get("amp_px_max", 2.0)))
	return mapped

func nodes_on_page(page: String = "") -> Array:
	var page_now := page if page != "" else current_page
	var out: Array = []
	for raw in world_map.get("nodes", []):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		if str(raw.get("pagina", "")) == page_now:
			var node: Dictionary = raw.duplicate(true)
			node["unlocked"] = node_unlocked(node)
			out.append(node)
	return out

func node_unlocked(node: Dictionary) -> bool:
	var lock = node.get("lock", {})
	if typeof(lock) != TYPE_DICTIONARY or lock.is_empty():
		return true
	var kind := str(lock.get("tipo", ""))
	match kind:
		"ato":
			return int(WorldState.act) >= int(lock.get("req", 1))
		"hype":
			var ok_hype := WorldState.get_reputation("hype") >= float(lock.get("req", 0))
			if lock.has("ato"):
				ok_hype = ok_hype and int(WorldState.act) >= int(lock.get("ato"))
			return ok_hype
		"heat":
			return int(WorldState.act) >= int(lock.get("ato", 1))
		"fragmentos":
			return bool(WorldState.story_flags.get("fragmentos_%s" % str(lock.get("req", 3)), false))
		"missao":
			return WorldState.completed_missions.has(str(lock.get("req", ""))) or bool(WorldState.story_flags.get(str(lock.get("req", "")), false))
		"composto":
			return _compound_ok(lock.get("req", []))
		_:
			return true

func _compound_ok(req) -> bool:
	if typeof(req) != TYPE_ARRAY:
		return false
	for raw in req:
		var token := str(raw)
		if token.begins_with("ato"):
			var n := token.substr(3).to_int()
			if n <= 0:
				n = 1
			if int(WorldState.act) < n:
				return false
		elif token == "lua_cheia":
			if str(moon_phase().get("id", "")) != "cheia":
				return false
		elif token == "mare_baixa":
			if tide_id() != "mare_baixa":
				return false
		elif token == "hype_10":
			if WorldState.get_reputation("hype") < 10.0:
				return false
		elif token == "hype_30":
			if WorldState.get_reputation("hype") < 30.0:
				return false
		elif token == "vencer_dique" or token == "vencer_terreiro":
			if not bool(WorldState.story_flags.get(token, false)):
				return false
		elif token == "infiltracao" or token == "investigacao" or token == "rota_lem" or token == "heat_baixo":
			if not bool(WorldState.story_flags.get(token, false)):
				return false
		elif token == "fragmentos_3":
			if not bool(WorldState.story_flags.get("fragmentos_3", false)):
				return false
	return true

func sea_route_open(from_id: String, to_id: String) -> bool:
	if tide_id() == "mare_baixa":
		var key := "%s:%s" % [from_id, to_id]
		var listed: Array = moon_data.get("sea_route_ids", [])
		if key in listed or ("%s:%s" % [to_id, from_id]) in listed:
			return false
	return true

func visible_life(page: String = "") -> Array:
	var page_now := page if page != "" else current_page
	var page_path := PAGE_DIR + "map_%s.json" % page_now
	if page_now == "02":
		page_path = PAGE_DIR + "map_02_itubera.json"
	var page_data := _load_json(page_path)
	var weather := weather_id_for_page(page_now)
	var block := "tarde"
	if has_node_world_director():
		block = str(WorldDirectorManager.state.get("time_block", "tarde"))
	var cap := 3
	for raw_page in atlas.get("pages", []):
		if str(raw_page.get("id", "")) == page_now:
			cap = int(raw_page.get("max_life_actors", 3))
	var out: Array = []
	for raw in page_data.get("life", []):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var actor: Dictionary = raw
		if actor.get("hide_if_weather", []).has(weather):
			continue
		var blocks = actor.get("time_blocks", [])
		if typeof(blocks) == TYPE_ARRAY and not blocks.is_empty() and not blocks.has(block):
			continue
		out.append(actor)
		if out.size() >= cap:
			break
	return out

func snapshot(page: String = "") -> Dictionary:
	var page_now := page if page != "" else current_page
	return {
		"page": page_now,
		"shipping": false,
		"weather": weather_id_for_page(page_now),
		"shaders": shader_params(page_now),
		"moon": moon_phase(),
		"tide": tide_id(),
		"nodes": nodes_on_page(page_now),
		"life": visible_life(page_now),
		"sea_blocked": tide_id() == "mare_baixa"
	}

func _region_for_page(page: String) -> String:
	for raw in atlas.get("pages", []):
		if str(raw.get("id", "")) == page:
			return str(raw.get("climate_region", "itubera_litoral"))
	return "itubera_litoral"

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed
	return {}
