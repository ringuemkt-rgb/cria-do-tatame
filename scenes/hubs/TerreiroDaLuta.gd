extends Control

const COMBAT_SCENE := "res://scenes/combat/CombatArenaBase.tscn"
const CRIA_LIVE_SCENE := "res://scenes/ui/CriaLiveUI.tscn"
const MAIN_MENU_SCENE := "res://scenes/main_menu/MainMenu.tscn"

var _transitioning := false

func _ready() -> void:
	_connect_if_exists("Panel/TrainBtn", _on_train)
	_connect_if_exists("Panel/FightDaviBtn", _on_fight_davi)
	_connect_if_exists("Panel/RestBtn", _on_rest)
	_connect_if_exists("Panel/SaveBtn", _on_save)
	_connect_if_exists("Panel/AdvanceDayBtn", _on_advance_day)
	_connect_if_exists("Panel/CriaLiveBtn", _on_cria_live)
	_connect_if_exists("Panel/MainMenuBtn", _on_main_menu)
	if not SignalBus.day_advanced.is_connected(_on_day_changed):
		SignalBus.day_advanced.connect(_on_day_changed)
	_update_ui()

func _connect_if_exists(path: String, callback: Callable) -> void:
	if not has_node(path):
		push_warning("[TerreiroDaLuta] Node ausente: " + path)
		return
	var button: Button = get_node(path)
	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)

func _update_ui() -> void:
	if has_node("Panel/Status"):
		$Panel/Status.text = "Semana %d - %s • R$ %d • Energia %d • Faixa %s" % [
			WorldState.week,
			WorldState.days[WorldState.day_index].capitalize(),
			WorldState.money,
			int(WorldState.energy),
			WorldState.belt.capitalize()
		]
	if has_node("Panel/NextAction"):
		var recommendation: Dictionary = GameFlowManager.next_recommended_action()
		$Panel/NextAction.text = "Proximo passo: %s" % _recommendation_text(recommendation)
	if has_node("Panel/TrainBtn"):
		$Panel/TrainBtn.disabled = WorldState.energy < 20.0
	if has_node("Panel/FightDaviBtn"):
		$Panel/FightDaviBtn.disabled = WorldState.energy < 30.0

func _recommendation_text(data: Dictionary) -> String:
	var kind := str(data.get("type", "atividade"))
	match kind:
		"cutscene": return "cena %s" % str(data.get("id", "intro"))
		"training": return "treino %s" % str(data.get("id", "tecnico"))
		"combat": return "combate contra %s" % str(data.get("opponent", "rival"))
		"cria_live": return "publicar no Cria Live"
		"mission": return "missao %s" % str(data.get("id", "disponivel"))
	return kind.replace("_", " ")

func _show_message(message: String) -> void:
	if has_node("Panel/Message"):
		$Panel/Message.text = message

func _on_train() -> void:
	if WorldState.energy < 20.0:
		_show_message("Energia insuficiente para treinar.")
		return
	var result: Dictionary = CareerLoop.execute_activity(CareerLoop.get_today_activity())
	GameFlowManager.advance_to("primeiro_treino_basico")
	_show_message(str(result.get("message", "Treino concluido.")))
	SaveManager.save_game(1)
	_update_ui()

func _on_fight_davi() -> void:
	if WorldState.energy < 30.0:
		_show_message("Energia insuficiente para lutar.")
		return
	_change_scene(COMBAT_SCENE)

func _on_rest() -> void:
	WorldState.energy = min(100.0, WorldState.energy + 40.0)
	_show_message("Voce descansou. Energia recuperada.")
	SaveManager.save_game(1)
	_update_ui()

func _on_save() -> void:
	_show_message("Jogo salvo com sucesso!" if SaveManager.save_game(1) else "Erro ao salvar.")

func _on_advance_day() -> void:
	WorldState.advance_day()
	SaveManager.save_game(1)
	_update_ui()
	_show_message("Dia avancado para %s." % WorldState.days[WorldState.day_index].capitalize())

func _on_cria_live() -> void:
	_change_scene(CRIA_LIVE_SCENE)

func _on_main_menu() -> void:
	SaveManager.save_game(1)
	_change_scene(MAIN_MENU_SCENE)

func _change_scene(path: String) -> void:
	if _transitioning:
		return
	_transitioning = true
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		_transitioning = false
		_show_message("Falha ao abrir a proxima tela.")
		push_error("[TerreiroDaLuta] Falha ao trocar para %s: %s" % [path, error_string(error)])

func _on_day_changed(_day, _week) -> void:
	_update_ui()
