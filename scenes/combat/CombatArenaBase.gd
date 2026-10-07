extends Control

const RESULT_SCENE: String = "res://scenes/result/ResultScreen.tscn"
const FighterPlaceholderScript = preload("res://src/characters/FighterPlaceholder.gd")
const GameFeelManagerScript = preload("res://src/gamefeel/GameFeelManager.gd")
const DaviAIControllerScript = preload("res://src/combat/DaviAIController.gd")
const VisualTheme = preload("res://src/ui/CriaVisualTheme.gd")
const ArenaBackdropScript = preload("res://src/visual/ArenaBackdrop.gd")

var gamefeel: Node
var davi_ai: Node
var ruan_placeholder: Node
var davi_placeholder: Node
var action_buttons: Array[Button] = []
var ai_turn_delay: float = 0.35
var defense_window_seconds: float = 1.15
var _turn_in_progress := false
var _defense_window_open := false
var _selected_defense := ""
var _defense_elapsed := 0.0

var estados_ptbr: Dictionary = {
	"DISTANCE": "EM PE - NEUTRO",
	"GRIP": "DISPUTA DE PEGADA",
	"CLINCH": "CLINCH",
	"TAKEDOWN": "QUEDA",
	"GROUND": "CHAO",
	"TRANSITION": "TRANSICAO",
	"TECHNICAL": "ENCERRAMENTO TECNICO",
	"RESET": "REINICIANDO",
	"PLAYER_STANDING_NEUTRAL": "EM PE - NEUTRO",
	"PLAYER_TOP_CLINCH": "CLINCH POR CIMA",
	"PLAYER_BOTTOM_CLINCH": "CLINCH POR BAIXO",
	"PLAYER_TOP_GUARD": "POR CIMA DA GUARDA",
	"PLAYER_BOTTOM_GUARD": "GUARDA POR BAIXO",
	"PLAYER_TOP_SIDE": "CONTROLE LATERAL POR CIMA",
	"PLAYER_BOTTOM_SIDE": "CONTROLE LATERAL POR BAIXO",
	"PLAYER_TOP_MOUNT": "MONTADA POR CIMA",
	"PLAYER_BOTTOM_MOUNT": "MONTADA POR BAIXO",
	"PLAYER_BACK_ATTACK": "ATACANDO AS COSTAS",
	"PLAYER_BACK_DEFENSE": "DEFENDENDO AS COSTAS",
	"PLAYER_SUBMISSION_ATTACK": "CONTROLE DE FINALIZACAO",
	"PLAYER_SUBMISSION_DEFENSE": "DEFESA DE FINALIZACAO"
}

func _ready() -> void:
	_build_arena_visuals()
	_style_combat_panel()
	gamefeel = GameFeelManagerScript.new()
	add_child(gamefeel)
	davi_ai = DaviAIControllerScript.new()
	add_child(davi_ai)
	davi_ai.call("setup", "davi_relampago", "normal")
	_build_placeholder_fighters()
	_connect_buttons()
	_connect_runtime_signals()
	var preflight: Dictionary = CombatManager.get_pre_fight_plan_v2()
	var fight_arena := str(preflight.get("arena_id", "terreiro_da_luta"))
	var fight_opponent := str(preflight.get("opponent_id", "davi_relampago"))
	var fight_difficulty := str(preflight.get("difficulty", "normal"))
	davi_ai.call("setup", fight_opponent, fight_difficulty)
	ai_turn_delay = float(davi_ai.call("get_reaction_delay"))
	var start_result: Dictionary = CombatManager.start_combat(fight_arena, "ruan_macacao", fight_opponent)
	if not bool(start_result.get("ok", false)):
		push_error("[CombatArenaBase] Falha ao iniciar combate: %s" % str(start_result))
	_ensure_ai_hint()
	_refresh_v2_panel()
	_update_state_label(CombatManager.get_current_state_name())
	_refresh_action_buttons()
	AudioManager.play_music_cue("fight_dique")

func _build_arena_visuals() -> void:
	var backdrop := ArenaBackdropScript.new()
	backdrop.name = "ArenaBackdrop"
	backdrop.arena_id = "arena_do_dique"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	move_child(backdrop, 0)
	var lower_panel := Panel.new()
	lower_panel.name = "CombatPanelBackdrop"
	lower_panel.anchor_left = 0.025
	lower_panel.anchor_top = 0.665
	lower_panel.anchor_right = 0.975
	lower_panel.anchor_bottom = 0.985
	lower_panel.add_theme_stylebox_override("panel", VisualTheme.panel_style(0.93, VisualTheme.GOLD, 2, 10))
	lower_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lower_panel)
	move_child(lower_panel, 1)
	$Panel.z_index = 4

func _style_combat_panel() -> void:
	VisualTheme.style_heading($Panel/Title, 20, VisualTheme.HONOR)
	$Panel/State.add_theme_color_override("font_color", VisualTheme.CYAN)
	$Panel/State.add_theme_font_size_override("font_size", 16)
	$Panel/Resources.add_theme_color_override("font_color", VisualTheme.OFF_WHITE)
	$Panel/Message.add_theme_color_override("font_color", Color("f2c230"))
	$Panel/Message.add_theme_font_size_override("font_size", 15)
	$Panel/AIHint.add_theme_color_override("font_color", Color("a8b7c9"))
	for i in range(6):
		var button: Button = get_node("Panel/Buttons/Action%s" % [i + 1])
		VisualTheme.apply_action_button(button, VisualTheme.GOLD if i != 4 else VisualTheme.CONFLICT)

func _connect_runtime_signals() -> void:
	if not SignalBus.resources_changed.is_connected(_on_resources_changed):
		SignalBus.resources_changed.connect(_on_resources_changed)
	if not SignalBus.combat_state_changed.is_connected(_on_combat_state_changed):
		SignalBus.combat_state_changed.connect(_on_combat_state_changed)
	if not SignalBus.combat_finished.is_connected(_on_combat_finished):
		SignalBus.combat_finished.connect(_on_combat_finished)
	if not SignalBus.technique_resolved.is_connected(_on_technique_resolved):
		SignalBus.technique_resolved.connect(_on_technique_resolved)
	if not SignalBus.combat_v2_hand_changed.is_connected(_on_v2_hand_changed):
		SignalBus.combat_v2_hand_changed.connect(_on_v2_hand_changed)
	if not SignalBus.combat_v2_card_selected.is_connected(_on_v2_card_selected):
		SignalBus.combat_v2_card_selected.connect(_on_v2_card_selected)
	if not SignalBus.combat_v2_defense_selected.is_connected(_on_v2_defense_selected):
		SignalBus.combat_v2_defense_selected.connect(_on_v2_defense_selected)
	if not SignalBus.combat_corner_suggestion.is_connected(_on_corner_suggestion):
		SignalBus.combat_corner_suggestion.connect(_on_corner_suggestion)

func _build_placeholder_fighters() -> void:
	ruan_placeholder = FighterPlaceholderScript.new()
	ruan_placeholder.fighter_id = "ruan_macacao"
	ruan_placeholder.display_name = "Ruan Macacao"
	ruan_placeholder.position = Vector2(430, 385)
	add_child(ruan_placeholder)
	davi_placeholder = FighterPlaceholderScript.new()
	davi_placeholder.fighter_id = "davi_relampago"
	davi_placeholder.display_name = "Davi Relampago"
	davi_placeholder.primary_color = Color(0.22, 0.28, 0.34)
	davi_placeholder.accent_color = Color(0.55, 0.75, 1.0)
	davi_placeholder.position = Vector2(850, 385)
	davi_placeholder.scale = Vector2(-1, 1)
	add_child(davi_placeholder)

func _ensure_ai_hint() -> void:
	if has_node("Panel") and not has_node("Panel/AIHint"):
		var label := Label.new()
		label.name = "AIHint"
		label.text = "Davi esta lendo seu ritmo. Varie as entradas."
		get_node("Panel").add_child(label)

func _set_ai_hint(text: String) -> void:
	if has_node("Panel/AIHint"):
		$Panel/AIHint.text = text

func _connect_buttons() -> void:
	action_buttons.clear()
	for i in range(6):
		var path: String = "Panel/Buttons/Action%s" % [i + 1]
		if not has_node(path):
			continue
		var button: Button = get_node(path)
		action_buttons.append(button)
		button.pressed.connect(_on_action_button_pressed.bind(button))
	if has_node("Panel/ViradaBtn") and not $Panel/ViradaBtn.pressed.is_connected(_on_virada_pressed):
		$Panel/ViradaBtn.pressed.connect(_on_virada_pressed)

func _refresh_action_buttons() -> void:
	var available: Array = CombatManager.get_available_techniques()
	for index in range(action_buttons.size()):
		var button: Button = action_buttons[index]
		if index < available.size():
			var technique: Dictionary = available[index]
			var technique_id: String = str(technique.get("id", ""))
			var label_text: String = str(technique.get("nome", technique.get("name", technique_id)))
			var cost: Dictionary = technique.get("cost", technique.get("custo", {}))
			var gas_cost: int = int(cost.get("gas", technique.get("gas_cost", 0)))
			var focus_cost: int = int(cost.get("focus", cost.get("foco", technique.get("focus_cost", 0))))
			var affordable: bool = bool(technique.get("affordable", true))
			button.text = label_text
			button.set_meta("action_id", technique_id)
			button.set_meta("affordable", affordable)
			button.disabled = _turn_in_progress or not affordable or not CombatManager.is_running
			button.tooltip_text = "Gas %d • Foco %d" % [gas_cost, focus_cost]
		else:
			var is_reset: bool = index == 0 and available.is_empty()
			button.text = "REINICIAR POSICAO" if is_reset else "—"
			button.set_meta("action_id", "reset_position" if is_reset else "")
			button.set_meta("affordable", is_reset)
			button.disabled = _turn_in_progress or not is_reset or not CombatManager.is_running
			button.tooltip_text = ""

func _on_action_button_pressed(button: Button) -> void:
	if not CombatManager.is_running:
		return
	var action_id: String = str(button.get_meta("action_id", ""))
	if action_id == "" or not bool(button.get_meta("affordable", true)):
		return
	await _execute_player_action(action_id)

func _execute_player_action(action_id: String) -> void:
	if _turn_in_progress or action_id == "" or not CombatManager.is_running:
		return
	_turn_in_progress = true
	AudioManager.play_sfx("botao")
	_set_actions_enabled(false)
	if ruan_placeholder != null:
		ruan_placeholder.call("play_action", action_id)
	var result: Dictionary = CombatManager.apply_player_action(action_id)
	if result.has("error"):
		_set_ai_hint(_humanize_message(str(result["error"])))
		_turn_in_progress = false
		_refresh_action_buttons()
		_set_actions_enabled(true)
		return
	davi_ai.call("record_player_action", action_id)
	var success: bool = bool(result.get("success", false))
	AudioManager.play_sfx(action_id)
	gamefeel.call("apply_for_technique", action_id, success)
	if CombatManager.is_running:
		await _run_davi_turn()
	if not is_inside_tree():
		return
	_turn_in_progress = false
	if CombatManager.is_running:
		_refresh_action_buttons()
		_set_actions_enabled(true)
		_refresh_v2_panel()

func _run_davi_turn() -> void:
	_set_ai_hint("%s Davi esta escolhendo a resposta..." % str(davi_ai.call("pressure_message")))
	await get_tree().create_timer(ai_turn_delay).timeout
	if not is_inside_tree() or not CombatManager.is_running:
		return
	var technique: Dictionary = davi_ai.call("choose_technique", CombatManager)
	if technique.is_empty():
		_set_ai_hint("Davi nao encontrou uma acao segura e preservou a base.")
		return
	var technique_id := str(technique.get("id", ""))
	var technique_name := str(technique.get("nome", technique.get("name", technique_id)))
	_set_ai_hint("%s Davi comprometeu: %s." % [str(davi_ai.call("pressure_message")), technique_name])
	if davi_placeholder != null:
		davi_placeholder.call("play_action", technique_id)
	AudioManager.play_sfx(technique_id)

	var defense_options: Array = CombatManager.get_defense_options(CombatManager.opponent_id, technique_id)
	var defense_context: Dictionary = {}
	if not defense_options.is_empty():
		defense_context = await _await_player_defense(technique_id, technique_name, defense_options)
	if not is_inside_tree() or not CombatManager.is_running:
		return

	var defense_id := str(defense_context.get("technique_id", ""))
	var result: Dictionary
	if defense_id != "":
		result = CombatManager.apply_opponent_action_with_defense(
			technique_id,
			defense_id,
			float(defense_context.get("input_frame", 0.0))
		)
	else:
		result = CombatManager.apply_opponent_action(technique_id)

	if bool(result.get("denied", false)):
		_set_ai_hint("Ruan leu a entrada e respondeu com %s." % str(defense_context.get("name", defense_id)).replace("_", " "))
	elif defense_context.get("timed_out", false):
		_set_ai_hint("Janela fechou. Davi completou a acao.")
	gamefeel.call("apply_for_technique", technique_id, bool(result.get("success", false)))

func _await_player_defense(attack_id: String, attack_name: String, options: Array) -> Dictionary:
	if options.is_empty() or not has_node("CombatDeckHUD"):
		return {}
	_defense_window_open = true
	_selected_defense = ""
	_defense_elapsed = 0.0
	var window := maxf(0.15, defense_window_seconds)
	var payload := {
		"attack_id": attack_id,
		"attack_name": attack_name,
		"options": options.duplicate(true),
		"window_seconds": window
	}
	$CombatDeckHUD.open_defense_window(options, window)
	SignalBus.combat_v2_defense_window_opened.emit(payload.duplicate(true))
	_set_ai_hint("DEFENDA AGORA • %s esta entrando." % attack_name)

	while _defense_window_open and _defense_elapsed < window and CombatManager.is_running and is_inside_tree():
		await get_tree().process_frame
		if not is_inside_tree():
			break
		_defense_elapsed += maxf(0.0, get_process_delta_time())
		$CombatDeckHUD.set_defense_window_remaining(window - _defense_elapsed)

	var selected := _selected_defense
	var elapsed := minf(_defense_elapsed, window)
	_defense_window_open = false
	if has_node("CombatDeckHUD"):
		$CombatDeckHUD.close_defense_window()
	var close_payload := {
		"attack_id": attack_id,
		"technique_id": selected,
		"elapsed": elapsed,
		"timed_out": selected == ""
	}
	SignalBus.combat_v2_defense_window_closed.emit(close_payload.duplicate(true))
	if selected == "":
		return close_payload

	var selected_option: Dictionary = {}
	for option_value in options:
		if typeof(option_value) == TYPE_DICTIONARY and str(option_value.get("id", "")) == selected:
			selected_option = option_value
			break
	var commit_frame := float(selected_option.get("commit_frame", 0.0))
	var defense_ratio := float(selected_option.get("defense_window", 0.0))
	var logical_window_frames := maxf(0.0, commit_frame * defense_ratio)
	var timing_ratio := clampf(elapsed / window, 0.0, 1.0)
	close_payload["input_frame"] = logical_window_frames * timing_ratio
	close_payload["name"] = str(selected_option.get("name", selected))
	return close_payload

func _set_actions_enabled(enabled: bool) -> void:
	if has_node("CombatDeckHUD"):
		$CombatDeckHUD.set_actions_enabled(enabled)
	for button in action_buttons:
		if enabled:
			var action_id: String = str(button.get_meta("action_id", ""))
			var affordable: bool = bool(button.get_meta("affordable", true))
			button.disabled = action_id == "" or not affordable
		else:
			button.disabled = true

func _on_resources_changed(fighter_id, resources) -> void:
	if str(fighter_id) != CombatManager.player_id or typeof(resources) != TYPE_DICTIONARY:
		return
	if has_node("Panel/Resources"):
		$Panel/Resources.text = "PTS %d • VANT %d • Gas %d • Foco %d • Grip %d • Controle %d" % [
			int(resources.get("score", 0)),
			int(resources.get("advantages", 0)),
			int(resources.get("gas", 0)),
			int(resources.get("focus", 0)),
			int(resources.get("grip_integrity", 0)),
			int(resources.get("control", 0))
		]

func _on_combat_state_changed(_old_state, new_state) -> void:
	_update_state_label(new_state)
	if CombatManager.is_running:
		_refresh_action_buttons()

func _on_technique_resolved(result) -> void:
	if typeof(result) != TYPE_DICTIONARY:
		return
	if has_node("Panel/Message"):
		var technique_id: String = str(result.get("technique_id", result.get("action_id", "")))
		var technique: Dictionary = DataRegistry.get_technique(technique_id)
		var name_text: String = str(technique.get("nome", technique.get("name", technique_id)))
		var message: String = str(result.get("message", "sucesso" if result.get("success", false) else "defendido"))
		var actor_id := str(result.get("actor_id", "ruan_macacao"))
		var actor_name := "Ruan" if actor_id == CombatManager.player_id else "Davi"
		$Panel/Message.text = "%s • %s: %s" % [actor_name, name_text, _humanize_message(message)]
	if SignalBus.has_signal("technique_executed"):
		SignalBus.technique_executed.emit(StringName(result.get("actor_id", "ruan_macacao")), StringName(result.get("technique_id", "unknown")))
	if SignalBus.has_signal("tecnica_executada"):
		SignalBus.tecnica_executada.emit(StringName(result.get("actor_id", "ruan_macacao")), StringName(result.get("technique_id", "unknown")), bool(result.get("success", false)))

func _humanize_message(message: String) -> String:
	match message:
		"estado_posicional_incorreto": return "essa tecnica nao esta disponivel nesta posicao"
		"recurso_insuficiente": return "gas ou foco insuficiente"
		"technique_not_found": return "tecnica nao encontrada"
	return message.replace("_", " ")

func _update_state_label(value) -> void:
	if has_node("Panel/State"):
		$Panel/State.text = "Estado: " + str(estados_ptbr.get(str(value), str(value).replace("_", " ")))

func _on_combat_finished(result) -> void:
	if typeof(result) != TYPE_DICTIONARY:
		return
	_defense_window_open = false
	if has_node("CombatDeckHUD"):
		$CombatDeckHUD.close_defense_window()
	_set_actions_enabled(false)
	WorldState.last_combat_result = result
	SaveManager.save_game(1)
	var music_cue := "terreiro" if bool(result.get("draw", false)) else ("vitoria" if result.get("winner", "") == "ruan_macacao" else "derrota")
	AudioManager.play_music_cue(music_cue)
	var error: Error = get_tree().change_scene_to_file(RESULT_SCENE)
	if error != OK:
		push_error("[CombatArenaBase] Falha ao abrir resultado: %s" % error_string(error))


func _process(delta: float) -> void:
	if not CombatManager.is_running or not CombatManager.is_combat_v2_active():
		return
	var timer_result: Dictionary = CombatManager.tick_combat_timer(delta)
	if has_node("Panel/Message"):
		for score_event_value in timer_result.get("scoring_events", []):
			if typeof(score_event_value) != TYPE_DICTIONARY:
				continue
			var score_event: Dictionary = score_event_value
			if bool(score_event.get("awarded", false)):
				$Panel/Message.text = "PONTUACAO CONFIRMADA • %s estabilizada." % _score_event_label(str(score_event.get("event_id", "")))
			elif bool(score_event.get("cancelled", false)):
				$Panel/Message.text = "PONTUACAO NAO CONSOLIDADA • estabilizacao interrompida."
	if has_node("Panel/Timer"):
		var state: Dictionary = CombatManager.get_combat_state_v2()
		$Panel/Timer.text = "TEMPO %02d:%02d%s" % [
			int(state.get("timer", 0)) / 60,
			int(state.get("timer", 0)) % 60,
			" • OT" if bool(state.get("overtime", false)) else ""
		]
	if bool(timer_result.get("expired", false)) and has_node("Panel/Message"):
		var final_result: Dictionary = timer_result.get("payload", {}).get("result", {})
		$Panel/Message.text = "Tempo esgotado • resultado por %s." % str(final_result.get("method", "criterio_de_desempate")).replace("_", " ")

func _score_event_label(event_id: String) -> String:
	match event_id:
		"takedown": return "queda"
		"sweep": return "raspagem"
		"guard_pass": return "passagem"
		"mount": return "montada"
		"back_control": return "costas"
		"advantage": return "vantagem"
	return event_id.replace("_", " ")

func _on_v2_hand_changed(_hand: Array) -> void:
	if CombatManager.is_running:
		_refresh_action_buttons()
		_refresh_v2_panel()

func _on_v2_card_selected(technique_id) -> void:
	if CombatManager.is_running and not _defense_window_open:
		_execute_player_action(str(technique_id))

func _on_v2_defense_selected(technique_id) -> void:
	if not CombatManager.is_running or not _defense_window_open or _selected_defense != "":
		return
	_selected_defense = str(technique_id)
	_defense_window_open = false

func _on_corner_suggestion(suggestion) -> void:
	if typeof(suggestion) != TYPE_DICTIONARY:
		return
	if has_node("Panel/Corner"):
		$Panel/Corner.text = "TINKER: %s" % str(suggestion.get("reason", "Lê a resposta antes de forçar."))

func _on_virada_pressed() -> void:
	if _turn_in_progress:
		return
	var result: Dictionary = CombatManager.activate_virada_do_cria(1)
	if has_node("Panel/Message"):
		$Panel/Message.text = "VIRADA DO CRIA: foco, moral e gás recuperados." if bool(result.get("ok", false)) else "Virada ainda não está disponível."
	_refresh_v2_panel()

func _refresh_v2_panel() -> void:
	if not CombatManager.is_combat_v2_active():
		if has_node("Panel/ViradaBtn"):
			$Panel/ViradaBtn.visible = false
		return
	if has_node("Panel/ViradaBtn"):
		$Panel/ViradaBtn.visible = true
		var state: Dictionary = CombatManager.get_combat_state_v2()
		$Panel/ViradaBtn.disabled = not bool(state.get("virada_disponivel", {}).get("p1", false))
	if has_node("Panel/Corner"):
		var suggestion: Dictionary = CombatManager.get_corner_suggestion()
		if not suggestion.is_empty():
			$Panel/Corner.text = "TINKER: %s" % str(suggestion.get("reason", "Joga o plano."))
