extends Node

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
	var honra := WorldState.get_reputation("honra")
	var hype := WorldState.get_reputation("hype")
	var sombra := WorldState.get_reputation("sombra")
	var legado := WorldState.get_reputation("legado")
	var tinker_present := TinkerBondManager.is_tinker_present()
	if honra >= 70.0 and legado >= 70.0 and sombra < 30.0 and tinker_present:
		return "heroi_duas_aguas"
	if hype >= 70.0 and honra < 50.0 and not tinker_present:
		return "estrela_vazia"
	if sombra >= 70.0 and WorldState.get_reputation("moral") < 40.0 and not tinker_present:
		return "rei_dos_atalhos"
	if hype >= 60.0 and sombra >= 60.0:
		return "traidor_silencioso"
	if honra >= 70.0 and legado >= 70.0 and tinker_present:
		return "raiz_eterna"
	return "heroi_duas_aguas"
