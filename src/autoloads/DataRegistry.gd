extends Node

var characters := {}
var arenas := {}
var techniques := {}
var missions := {}
var factions := {}
var dialogues := {}

const DATA_FILES := {
	"characters": "res://data/characters.json",
	"arenas": "res://data/arenas.json",
	"techniques": "res://data/techniques.json",
	"missions": "res://data/missions.json",
	"factions": "res://data/factions.json",
	"dialogues": "res://data/dialogues.json"
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
	if Engine.has_singleton("SignalBus"):
		SignalBus.data_loaded.emit()

func _load_keyed(key):
	var path = DATA_FILES.get(key, "")
	var parsed = _load_json(path)
	var output := {}
	for item in parsed.get(key, []):
		if item.has("id"):
			output[item.id] = item
	return output

func _load_json(path):
	if not FileAccess.file_exists(path):
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	var text = file.get_as_text()
	var result = JSON.parse_string(text)
	if typeof(result) != TYPE_DICTIONARY:
		return {}
	return result
