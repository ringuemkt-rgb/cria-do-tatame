extends Node

const EndingsCalculatorScript = preload("res://src/narrative/EndingsCalculator.gd")

var current_scene_id := ""
var current_scene := {}
var beat_index := 0

func load_scene(scene_id: String) -> Dictionary:
	current_scene_id = scene_id
	current_scene = _find_scene(scene_id)
	beat_index = 0
	if not current_scene.is_empty():
		SignalBus.dialogue_started.emit(scene_id)
	return current_scene

func next_beat() -> Dictionary:
	if current_scene.is_empty():
		return {}
	var beats: Array = current_scene.get("beats", [])
	if beat_index >= beats.size():
		SignalBus.dialogue_ended.emit(current_scene_id)
		return {}
	var beat: Dictionary = beats[beat_index]
	beat_index += 1
	return beat

func is_finished() -> bool:
	return current_scene.is_empty() or beat_index >= current_scene.get("beats", []).size()

func _find_scene(scene_id: String) -> Dictionary:
	var path := "res://data/story/story_scenes_v01.json"
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	for item in parsed.get("scenes", []):
		if str(item.get("id", "")) == scene_id:
			return item
	return {}

func get_final_id() -> String:
	var tinker_state := TinkerBondManager.get_state()
	return EndingsCalculatorScript.calculate(WorldState.reputation, tinker_state, DataRegistry.finais_adultos)
