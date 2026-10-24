extends Control

const VisualTheme = preload("res://src/ui/CriaVisualTheme.gd")

var _cutscene_id := ""
var _beat_count := 0

@onready var _title: Label = $Frame/Content/Stack/Title
@onready var _speaker: Label = $Frame/Content/Stack/Speaker
@onready var _dialogue: Label = $Frame/Content/Stack/Dialogue
@onready var _progress: Label = $Frame/Content/Stack/Progress
@onready var _continue_button: Button = $Frame/Content/Stack/Actions/Continue
@onready var _skip_button: Button = $Frame/Content/Stack/Actions/Skip

func _ready() -> void:
	VisualTheme.panel_style()
	$Frame.add_theme_stylebox_override("panel", VisualTheme.panel_style(0.98))
	VisualTheme.style_heading(_title, 25)
	VisualTheme.apply_primary_button(_continue_button)
	VisualTheme.apply_action_button(_skip_button, VisualTheme.RIVER)
	_continue_button.custom_minimum_size.y = 52
	_skip_button.custom_minimum_size.y = 52
	_dialogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue.add_theme_color_override("font_color", VisualTheme.OFF_WHITE)
	_dialogue.add_theme_font_size_override("font_size", 20)
	_speaker.add_theme_color_override("font_color", VisualTheme.HONOR)
	_speaker.add_theme_font_size_override("font_size", 17)
	_progress.add_theme_color_override("font_color", Color("c8c1b2"))
	_continue_button.pressed.connect(_on_continue_pressed)
	_skip_button.pressed.connect(_on_skip_pressed)
	if not CutsceneRuntime.cutscene_line.is_connected(_on_cutscene_line):
		CutsceneRuntime.cutscene_line.connect(_on_cutscene_line)
	if not CutsceneRuntime.cutscene_finished.is_connected(_on_cutscene_finished):
		CutsceneRuntime.cutscene_finished.connect(_on_cutscene_finished)

func start_cutscene(cutscene_id: String) -> bool:
	var scene_data: Dictionary = CutsceneRuntime.get_cutscene(cutscene_id)
	if scene_data.is_empty():
		return false
	_cutscene_id = cutscene_id
	var raw_beats = scene_data.get("beats", [])
	_beat_count = raw_beats.size() if typeof(raw_beats) == TYPE_ARRAY else 0
	_title.text = str(scene_data.get("title", "O CHAO FALA"))
	var started: Dictionary = CutsceneRuntime.start_cutscene(cutscene_id)
	if started.is_empty():
		_cutscene_id = ""
		return false
	if _beat_count == 0:
		CutsceneRuntime.finish_current()
	return true

func _on_cutscene_line(cutscene_id: String, speaker_id: String, line: String) -> void:
	if cutscene_id != _cutscene_id:
		return
	_speaker.text = _speaker_name(speaker_id)
	_dialogue.text = line
	_progress.text = "%02d / %02d" % [CutsceneRuntime.current_index + 1, _beat_count]
	_continue_button.text = "CONCLUIR" if CutsceneRuntime.current_index + 1 >= _beat_count else "CONTINUAR"

func _speaker_name(speaker_id: String) -> String:
	match speaker_id:
		"mestre_dende": return "MESTRE DENDÊ"
		"ruan_macacao": return "RUAN"
		"davi_relampago": return "DAVI RELÂMPAGO"
		"narrador": return "NARRADOR"
		_: return speaker_id.replace("_", " ").to_upper()

func _on_continue_pressed() -> void:
	if _cutscene_id != "":
		CutsceneRuntime.next_line()

func _on_skip_pressed() -> void:
	if _cutscene_id != "":
		CutsceneRuntime.finish_current()

func _on_cutscene_finished(cutscene_id: String) -> void:
	if cutscene_id != _cutscene_id:
		return
	_cutscene_id = ""
	if not SaveManager.save_game(1):
		push_warning("[CutsceneOverlay] A cena terminou, mas o progresso nao foi salvo.")
	queue_free()
