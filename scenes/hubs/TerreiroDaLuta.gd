extends Control

const COMBAT_SCENE := "res://scenes/combat/CombatArenaBase.tscn"
const CRIA_LIVE_SCENE := "res://scenes/ui/CriaLiveUI.tscn"
const MAIN_MENU_SCENE := "res://scenes/main_menu/MainMenu.tscn"

func _ready() -> void:
	_connect_if_exists("Panel/TrainBtn", _on_train)
	_connect_if_exists("Panel/FightDaviBtn", _on_fight_davi)
	_connect_if_exists("Panel/RestBtn", _on_rest)
	_connect_if_exists("Panel/SaveBtn", _on_save)
	_connect_if_exists("Panel/AdvanceDayBtn", _on_advance_day)
	_connect_if_exists("Panel/CriaLiveBtn", _on_cria_live)
	_connect_if_exists("Panel/MainMenuBtn", _on_main_menu)
	SignalBus.day_advanced.connect(_on_day_changed)
	_update_ui()

func _connect_if_exists(path: String, callable: Callable) -> void:
	if has_node(path):
		get_node(path).pressed.connect(callable)

func _update_ui() -> void:
	if has_node("Panel/Status"):
		$Panel/Status.text = "Semana %d - %s • R$ %d • Energia %d" % [WorldState.week, WorldState.days[WorldState.day_index].capitalize(), WorldState.money, int(WorldState.energy)]

func _show_message(msg: String) -> void:
	if has_node("Panel/Message"):
		$Panel/Message.text = msg

func _on_train() -> void:
	if WorldState.energy < 20.0:
		_show_message("Energia insuficiente para treinar.")
		return
	var result = CareerLoop.execute_activity(CareerLoop.get_today_activity())
	_show_message(result.get("message", "Treino concluido."))
	SaveManager.save_game(1)
	_update_ui()

func _on_fight_davi() -> void:
	if WorldState.energy < 30.0:
		_show_message("Energia insuficiente para lutar.")
		return
	get_tree().change_scene_to_file(COMBAT_SCENE)

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
	get_tree().change_scene_to_file(CRIA_LIVE_SCENE)

func _on_main_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _on_day_changed(_day, _week) -> void:
	_update_ui()
