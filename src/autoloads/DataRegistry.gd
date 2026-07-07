extends Node

var characters := {}
var arenas := {}
var techniques := {}
var missions := {}
var factions := {}
var dialogues := {}
var economy := {}
var progression := {}
var cria_live_posts := {}
var settings := {}
var sponsors := {}
var reputation_events := {}
var tinker_bond := {}
var finais_adultos := {}
var story_missions := {}
var story_scenes := {}
var arena_story_gameplay := {}
var story_visual_manifest := {}
var faction_drama_bible := {}
var faction_missions := {}
var faction_scenes := {}
var hubs_dense := {}
var gear_catalog := {}
var player_progression := {}
var customization_options := {}
var training_minigames := {}
var cria_live_interactive := {}
var hub_activities := {}
var complete_game_flow := {}
var campaign_cinematics := {}
var rival_ai_profiles := {}
var full_completion_backlog := {}
var character_bible := {}
var world_bible := {}
var visual_production_manifest := {}
var validation_report := {}

const DATA_FILES := {
	"characters": "res://data/characters.json",
	"arenas": "res://data/arenas.json",
	"techniques": "res://data/techniques.json",
	"missions": "res://data/missions.json",
	"factions": "res://data/factions.json",
	"dialogues": "res://data/dialogues.json",
	"economy": "res://data/economy.json",
	"progression": "res://data/progression.json",
	"cria_live_posts": "res://data/cria_live_posts.json",
	"settings": "res://data/settings.json",
	"sponsors": "res://data/sponsors.json",
	"reputation_events": "res://data/reputation_events.json",
	"tinker_bond": "res://data/tinker_bond.json",
	"finais_adultos": "res://data/finais_adultos.json",
	"story_missions": "res://data/missions/story_missions_v01.json",
	"story_scenes": "res://data/story/story_scenes_v01.json",
	"arena_story_gameplay": "res://data/arenas/arena_story_gameplay_v01.json",
	"story_visual_manifest": "res://data/visual/story_visual_manifest_v01.json",
	"faction_drama_bible": "res://data/factions/faction_drama_bible_v01.json",
	"faction_missions": "res://data/missions/faction_missions_v01.json",
	"faction_scenes": "res://data/story/faction_scenes_v01.json",
	"hubs_dense": "res://data/world/hubs_dense_v01.json",
	"gear_catalog": "res://data/gear/gear_catalog_v01.json",
	"player_progression": "res://data/player/player_progression.json",
	"customization_options": "res://data/customization/customization_options.json",
	"training_minigames": "res://data/training/training_minigames_v01.json",
	"cria_live_interactive": "res://data/cria_live/cria_live_interactive_v01.json",
	"hub_activities": "res://data/missions/hub_activities_v01.json",
	"complete_game_flow": "res://data/gameplay/complete_game_flow_v01.json",
	"campaign_cinematics": "res://data/story/campaign_cinematics_v01.json",
	"rival_ai_profiles": "res://data/ai/rival_ai_profiles_v01.json",
	"full_completion_backlog": "res://data/production/full_completion_backlog_v01.json",
	"character_bible": "res://data/lore/character_bible_v01.json",
	"world_bible": "res://data/lore/world_bible_v01.json",
	"visual_production_manifest": "res://data/lore/visual_production_manifest_v01.json"
}

func _ready():
	load_all()

func load_all():
	characters = _load_keyed("characters")
	arenas = _load_keyed("arenas")
	techniques = _load_keyed("techniques")
	missions = _load_keyed("missions")
	factions = _load_keyed("factions")
	dialogues = _load_keyed("dialogues")
	economy = _load_raw("economy")
	progression = _load_raw("progression")
	cria_live_posts = _load_raw("cria_live_posts")
	settings = _load_raw("settings")
	sponsors = _load_keyed("sponsors")
	reputation_events = _load_keyed("reputation_events")
	tinker_bond = _load_raw("tinker_bond")
	finais_adultos = _load_raw("finais_adultos")
	story_missions = _load_raw("story_missions")
	story_scenes = _load_raw("story_scenes")
	arena_story_gameplay = _load_raw("arena_story_gameplay")
	story_visual_manifest = _load_raw("story_visual_manifest")
	faction_drama_bible = _load_raw("faction_drama_bible")
	faction_missions = _load_raw("faction_missions")
	faction_scenes = _load_raw("faction_scenes")
	hubs_dense = _load_raw("hubs_dense")
	gear_catalog = _load_raw("gear_catalog")
	player_progression = _load_raw("player_progression")
	customization_options = _load_raw("customization_options")
	training_minigames = _load_raw("training_minigames")
	cria_live_interactive = _load_raw("cria_live_interactive")
	hub_activities = _load_raw("hub_activities")
	complete_game_flow = _load_raw("complete_game_flow")
	campaign_cinematics = _load_raw("campaign_cinematics")
	rival_ai_profiles = _load_raw("rival_ai_profiles")
	full_completion_backlog = _load_raw("full_completion_backlog")
	character_bible = _load_raw("character_bible")
	world_bible = _load_raw("world_bible")
	visual_production_manifest = _load_raw("visual_production_manifest")
	validation_report = validate_core_data()
	SignalBus.data_validation_finished.emit(validation_report)
	SignalBus.data_loaded.emit()

func _load_raw(key):
	return _load_json(DATA_FILES.get(key, ""))

func _load_keyed(key):
	var parsed = _load_json(DATA_FILES.get(key, ""))
	var output := {}
	for item in parsed.get(key, []):
		if item.has("id"):
			output[str(item.id)] = item
	return output

func _load_json(path):
	if path == "" or not FileAccess.file_exists(path):
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var result = JSON.parse_string(file.get_as_text())
	if typeof(result) != TYPE_DICTIONARY:
		return {}
	return result

func validate_core_data():
	var errors := []
	if not characters.has("ruan_macacao"):
		errors.append("characters.json sem ruan_macacao")
	else:
		var ruan: Dictionary = characters.get("ruan_macacao", {})
		if ruan.get("canon", false) != true:
			errors.append("ruan_macacao precisa ter canon=true")
		if str(ruan.get("name", "")).find("Caio") >= 0 or str(ruan.get("name", "")).find("Ravel") >= 0:
			errors.append("ruan_macacao contem nome legado proibido")
	if not arenas.has("terreiro_da_luta"):
		errors.append("arenas.json sem terreiro_da_luta")
	if techniques.is_empty():
		errors.append("techniques.json vazio")
	if tinker_bond.is_empty():
		errors.append("tinker_bond.json nao carregado")
	if finais_adultos.is_empty():
		errors.append("finais_adultos.json nao carregado")
	if hubs_dense.is_empty():
		errors.append("hubs_dense_v01.json nao carregado")
	if player_progression.is_empty():
		errors.append("player_progression.json nao carregado")
	if complete_game_flow.is_empty():
		errors.append("complete_game_flow_v01.json nao carregado")
	if campaign_cinematics.is_empty():
		errors.append("campaign_cinematics_v01.json nao carregado")
	if rival_ai_profiles.is_empty():
		errors.append("rival_ai_profiles_v01.json nao carregado")
	if character_bible.is_empty():
		errors.append("character_bible_v01.json nao carregado")
	if world_bible.is_empty():
		errors.append("world_bible_v01.json nao carregado")
	if visual_production_manifest.is_empty():
		errors.append("visual_production_manifest_v01.json nao carregado")
	return {"ok": errors.is_empty(), "errors": errors, "characters": characters.size(), "arenas": arenas.size(), "techniques": techniques.size(), "factions": factions.size()}

func get_character(id):
	return characters.get(str(id), {})

func get_arena(id):
	return arenas.get(str(id), {})

func get_technique(id):
	return techniques.get(str(id), {})

func get_lore_character(id):
	return character_bible.get("characters", {}).get(str(id), {})

func get_story_mission(id):
	for mission in story_missions.get("missions", []):
		if str(mission.get("id", "")) == str(id):
			return mission
	return {}

func get_faction_mission(id):
	for mission in faction_missions.get("missions", []):
		if str(mission.get("id", "")) == str(id):
			return mission
	return {}

func get_story_scene(id):
	for scene in story_scenes.get("scenes", []):
		if str(scene.get("id", "")) == str(id):
			return scene
	for scene in faction_scenes.get("scenes", []):
		if str(scene.get("id", "")) == str(id):
			return scene
	return {}

func get_campaign_cutscene(id):
	for scene in campaign_cinematics.get("cutscenes", []):
		if str(scene.get("id", "")) == str(id):
			return scene
	return {}
