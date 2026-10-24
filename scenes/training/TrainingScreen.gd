extends Control

const VisualTheme = preload("res://src/ui/CriaVisualTheme.gd")
const HUB_SCENE := "res://scenes/hubs/TerreiroDaLuta.tscn"
const TECHNIQUE_ID := "grip_de_ferro"
const TARGET_REPETITIONS := 3

var _repetitions := 0
var _completed := false
var _energy_cost := 25.0

@onready var _title: Label = $Frame/Content/Stack/Title
@onready var _instruction: Label = $Frame/Content/Stack/Instruction
@onready var _counter: Label = $Frame/Content/Stack/Counter
@onready var _progress: ProgressBar = $Frame/Content/Stack/Progress
@onready var _status: Label = $Frame/Content/Stack/Status
@onready var _repeat_button: Button = $Frame/Content/Stack/Actions/Repeat
@onready var _back_button: Button = $Frame/Content/Stack/Actions/Back

func _ready() -> void:
	$Frame.add_theme_stylebox_override("panel", VisualTheme.panel_style(0.98))
	VisualTheme.style_heading(_title, 25)
	VisualTheme.apply_primary_button(_repeat_button)
	VisualTheme.apply_action_button(_back_button, VisualTheme.RIVER)
	_repeat_button.custom_minimum_size.y = 54
	_back_button.custom_minimum_size.y = 54
	_instruction.add_theme_color_override("font_color", VisualTheme.OFF_WHITE)
	_instruction.add_theme_font_size_override("font_size", 18)
	_status.add_theme_color_override("font_color", Color("d5cdbd"))
	_status.add_theme_font_size_override("font_size", 15)
	VisualTheme.style_progress(_progress, VisualTheme.HONOR)
	_progress.max_value = TARGET_REPETITIONS
	_repeat_button.pressed.connect(_on_repeat_pressed)
	_back_button.pressed.connect(_return_to_hub)
	_load_training_data()
	_refresh_ui()

func _load_training_data() -> void:
	var training_data: Dictionary = DataRegistry.training_minigames.get("technical_training", {}).get("rolagem_tecnica", {})
	_energy_cost = float(training_data.get("energy_cost", 25.0))
	_instruction.text = "GRIP DE FERRO\nEstabeleça a pegada, mantenha a base e complete três repetições."

func _on_repeat_pressed() -> void:
	if _completed:
		_return_to_hub()
		return
	if WorldState.energy < _energy_cost:
		_status.text = "Energia insuficiente. Descanse no Terreiro e tente novamente."
		_refresh_ui()
		return
	_repetitions = mini(_repetitions + 1, TARGET_REPETITIONS)
	if _repetitions >= TARGET_REPETITIONS:
		_complete_training()
	else:
		_status.text = "Boa. Ajuste a base e faça a próxima repetição."
	_refresh_ui()

func _complete_training() -> void:
	var result: Dictionary = TrainingManager.run_technical_training(TECHNIQUE_ID, _repetitions)
	if not bool(result.get("ok", false)):
		_repetitions = 0
		_status.text = str(result.get("message", "Não foi possível concluir o treino."))
		return
	_completed = true
	GameFlowManager.complete_step("primeiro_treino_basico")
	_status.text = "%s\nA maestria de Grip de Ferro recebeu %.0f XP." % [str(result.get("message", "Treino concluído.")), float(result.get("mastery_xp", 0.0))]
	if not SaveManager.save_game(1):
		_status.text += "\nAviso: falha ao salvar o progresso."
	_repeat_button.text = "VOLTAR AO TERREIRO"

func _refresh_ui() -> void:
	_counter.text = "REPETIÇÕES  %d / %d" % [_repetitions, TARGET_REPETITIONS]
	_progress.value = _repetitions
	if _completed:
		_repeat_button.disabled = false
		_back_button.text = "SAIR"
	elif WorldState.energy < _energy_cost:
		_repeat_button.disabled = true
		_status.text = "Energia necessária: %d. Disponível: %d." % [int(_energy_cost), int(WorldState.energy)]
	else:
		_repeat_button.disabled = false
		_repeat_button.text = "FAZER REPETIÇÃO"
		if _repetitions == 0:
			_status.text = "Toque para iniciar a primeira repetição."

func _return_to_hub() -> void:
	if _completed:
		SaveManager.save_game(1)
	var error := get_tree().change_scene_to_file(HUB_SCENE)
	if error != OK:
		push_error("[TrainingScreen] Falha ao voltar ao Terreiro: %s" % error_string(error))
