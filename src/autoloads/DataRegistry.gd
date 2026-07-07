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
	"settings": "res://data/settings.json"
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
	if not arenas.has("terreiro_da_luta"):
		errors.append("arenas.json sem terreiro_da_luta")
	if techniques.is_empty():
		errors.append("techniques.json vazio")
	return {"ok": errors.is_empty(), "errors": errors, "characters": characters.size(), "arenas": arenas.size(), "techniques": techniques.size()}

func get_character(id):
	return characters.get(id, {})

func get_arena(id):
	return arenas.get(id, {})

func get_technique(id):
	return techniques.get(id, {})
