extends Control

const COMBAT_SCENE := "res://scenes/combat/CombatArenaBase.tscn"
const CRIA_LIVE_SCENE := "res://scenes/ui/CriaLiveUI.tscn"
const MAIN_MENU_SCENE := "res://scenes/main_menu/MainMenu.tscn"
const DECK_SCENE := "res://scenes/ui/DeckBuilder.tscn"
const MAP_SCENE := "res://scenes/world/WorldMapScreen.tscn"
const NPCPresencePanelScript = preload("res://scenes/hubs/NPCPresencePanel.gd")
const VisualTheme = preload("res://src/ui/CriaVisualTheme.gd")
const FighterPlaceholderScript = preload("res://src/characters/FighterPlaceholder.gd")

var _transitioning := false

func _ready() -> void:
	WorldMapManager.current_hub = "itubera"
	WorldState.current_hub = "itubera"
	_style_interface()
	_build_npc_presence()
	_build_world_npcs()
	AudioManager.play_ambience("terreiro_river_loop")
	_connect_if_exists("Panel/TrainBtn", _on_train)
	_connect_if_exists("Panel/DeckBtn", _on_deck_builder)
	_connect_if_exists("Panel/FightDaviBtn", _on_fight_davi)
	_connect_if_exists("Panel/RestBtn", _on_rest)
	_connect_if_exists("Panel/SaveBtn", _on_save)
	_connect_if_exists("Panel/AdvanceDayBtn", _on_advance_day)
	_connect_if_exists("Panel/CriaLiveBtn", _on_cria_live)
	_connect_if_exists("Panel/MapBtn", _on_map)
	_connect_if_exists("Panel/MainMenuBtn", _on_main_menu)
	if not SignalBus.day_advanced.is_connected(_on_day_changed):
		SignalBus.day_advanced.connect(_on_day_changed)
	_update_ui()

func _build_npc_presence() -> void:
	if has_node("NPCPresencePanel"):
		return
	var presence := NPCPresencePanelScript.new()
	presence.call("configure", "itubera")
	add_child(presence)

func _build_world_npcs() -> void:
	var placements := [
		{"id": "mestre_dende", "name": "Mestre Dendê", "position": Vector2(292.0, 466.0), "scale": Vector2(0.70, 0.70)},
		{"id": "tinker_bell", "name": "Tinker Bell", "position": Vector2(1002.0, 474.0), "scale": Vector2(-0.68, 0.68)}
	]
	for placement_value in placements:
		var placement: Dictionary = placement_value
		var actor := FighterPlaceholderScript.new()
		actor.name = "WorldNPC_" + str(placement.get("id", "npc"))
		actor.fighter_id = str(placement.get("id", "npc"))
		actor.display_name = str(placement.get("name", "NPC"))
		actor.position = placement.get("position", Vector2.ZERO)
		actor.scale = placement.get("scale", Vector2.ONE)
		actor.z_index = 1
		add_child(actor)

func _style_interface() -> void:
	if has_node("Panel"):
		$Panel.z_index = 2
		var backdrop := Panel.new()
		backdrop.name = "InterfaceBackdrop"
		backdrop.anchor_left = 0.5
		backdrop.anchor_top = 0.5
		backdrop.anchor_right = 0.5
		backdrop.anchor_bottom = 0.5
		backdrop.offset_left = -330.0
		backdrop.offset_top = -360.0
		backdrop.offset_right = 330.0
		backdrop.offset_bottom = 360.0
		backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		backdrop.add_theme_stylebox_override("panel", VisualTheme.panel_style(0.86, VisualTheme.GOLD, 2, 14))
		add_child(backdrop)
		move_child(backdrop, 2)
	if has_node("Panel/Title"):
		VisualTheme.style_heading($Panel/Title, 30, VisualTheme.HONOR)
	if has_node("Panel/Status"):
		$Panel/Status.add_theme_color_override("font_color", VisualTheme.CYAN)
	if has_node("Panel/NextAction"):
		$Panel/NextAction.add_theme_color_override("font_color", VisualTheme.OFF_WHITE)
	if has_node("Panel/Message"):
		$Panel/Message.add_theme_color_override("font_color", VisualTheme.HONOR)
	for button_name in ["TrainBtn", "DeckBtn", "FightDaviBtn", "RestBtn", "SaveBtn", "AdvanceDayBtn", "CriaLiveBtn", "MapBtn", "MainMenuBtn"]:
		var path := "Panel/" + button_name
		if has_node(path):
			VisualTheme.apply_primary_button(get_node(path))

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

func _on_deck_builder() -> void:
	_change_scene(DECK_SCENE)

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

func _on_map() -> void:
	_change_scene(MAP_SCENE)

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

func _exit_tree() -> void:
	AudioManager.stop_ambience()
