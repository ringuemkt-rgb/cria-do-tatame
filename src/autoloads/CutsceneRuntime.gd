extends Node

signal cutscene_started(cutscene_id: String)
signal cutscene_line(cutscene_id: String, speaker: String, line: String)
signal cutscene_finished(cutscene_id: String)

var current_cutscene := ""
var current_index := 0
var active_beats := []

func start_cutscene(cutscene_id: String) -> Dictionary:
	var scene := get_cutscene(cutscene_id)
	if scene.is_empty():
		push_warning("[CutsceneRuntime] Cena nao encontrada: %s" % cutscene_id)
		return {}
	current_cutscene = cutscene_id
	current_index = 0
	active_beats = scene.get("beats", [])
	cutscene_started.emit(cutscene_id)
	if not active_beats.is_empty():
		_emit_current_line()
	return scene

func next_line() -> bool:
	if current_cutscene == "":
		return false
	current_index += 1
	if current_index >= active_beats.size():
		finish_current()
		return false
	_emit_current_line()
	return true

func finish_current() -> void:
	var finished := current_cutscene
	current_cutscene = ""
	current_index = 0
	active_beats = []
	if finished != "":
		cutscene_finished.emit(finished)
		GameFlowManager.advance_to(finished)

func _emit_current_line() -> void:
	var beat: Dictionary = active_beats[current_index]
	cutscene_line.emit(current_cutscene, str(beat.get("speaker", "narrador")), str(beat.get("line", beat.get("text", ""))))

func get_cutscene(cutscene_id: String) -> Dictionary:
	for scene in DataRegistry.campaign_cinematics.get("cutscenes", []):
		if str(scene.get("id", "")) == cutscene_id:
			return scene
	return DataRegistry.get_story_scene(cutscene_id)

func get_cutscene_for_trigger(trigger_id: String) -> Dictionary:
	for scene in DataRegistry.campaign_cinematics.get("cutscenes", []):
		if str(scene.get("trigger", "")) == trigger_id:
			return scene
	return {}
