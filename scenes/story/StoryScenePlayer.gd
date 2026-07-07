extends Control

const HUB_SCENE := "res://scenes/hubs/TerreiroDaLuta.tscn"

var scene_id := "cena_ruan_derrota_mangue"

func _ready() -> void:
	if has_node("Panel/Next"):
		$Panel/Next.pressed.connect(_on_next_pressed)
	if has_node("Panel/Back"):
		$Panel/Back.pressed.connect(_on_back_pressed)
	StorySceneDirector.load_scene(scene_id)
	_show_header()
	_show_next_beat()

func set_scene_id(id: String) -> void:
	scene_id = id

func _show_header() -> void:
	var scene := StorySceneDirector.current_scene
	if has_node("Panel/Title"):
		$Panel/Title.text = scene.get("title", "Cena")
	if has_node("Panel/Location"):
		$Panel/Location.text = scene.get("location", "")
	if has_node("Panel/Mood"):
		$Panel/Mood.text = scene.get("mood", "")

func _show_next_beat() -> void:
	var beat := StorySceneDirector.next_beat()
	if beat.is_empty():
		if has_node("Panel/Text"):
			$Panel/Text.text = "Cena concluida."
		return
	var line := ""
	if beat.has("speaker"):
		line = "%s: %s" % [str(beat.get("speaker", "")).replace("_", " ").capitalize(), beat.get("line", "")]
	else:
		line = beat.get("text", "")
	if has_node("Panel/Text"):
		$Panel/Text.text = line

func _on_next_pressed() -> void:
	if StorySceneDirector.is_finished():
		get_tree().change_scene_to_file(HUB_SCENE)
	else:
		_show_next_beat()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(HUB_SCENE)
