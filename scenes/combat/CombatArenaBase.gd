extends Control

const RESULT_SCENE: String = "res://scenes/result/ResultScreen.tscn"
const FighterPlaceholderScript = preload("res://src/characters/FighterPlaceholder.gd")
const GameFeelManagerScript = preload("res://src/gamefeel/GameFeelManager.gd")
const DaviAIControllerScript = preload("res://src/combat/DaviAIController.gd")
const VisualTheme = preload("res://src/ui/CriaVisualTheme.gd")
const ArenaBackdropScript = preload("res://src/visual/ArenaBackdrop.gd")
const CombatVFXControllerScript = preload("res://src/gamefeel/CombatVFXController.gd")

@export var arena_id: String = "arena_do_dique"

var gamefeel: Node
var davi_ai: Node
var ruan_placeholder: Node
var davi_placeholder: Node
var action_buttons: Array[Button] = []
var ai_turn_delay: float = 0.35
var combat_vfx: Node2D

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
	gamefeel.call("setup", self)
	davi_ai = DaviAIControllerScript.new()
	add_child(davi_ai)
	davi_ai.call("setup", "davi_relampago", "normal")
	_build_placeholder_fighters()
	_connect_buttons()
	_connect_runtime_signals()
	var arena: Dictionary = DataRegistry.get_arena(arena_id)
	if has_node("Panel/Title"):
		$Panel/Title.text = "%s • RUAN MACACAO vs DAVI RELAMPAGO" % str(arena.get("name", "Arena do Dique")).to_upper()
	CombatManager.start_combat(arena_id, "ruan_macacao", "davi_relampago")
	_ensure_ai_hint()
	_update_state_label(CombatManager.get_current_state_name())
	_refresh_action_buttons()
	AudioManager.play_music_cue(arena_id)
	AudioManager.play_ambience("arena_idle_loop")

func _build_arena_visuals() -> void:
	var backdrop := ArenaBackdropScript.new()
	backdrop.name = "ArenaBackdrop"
	backdrop.arena_id = arena_id
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
	combat_vfx = CombatVFXControllerScript.new()
	combat_vfx.name = "CombatVFX"
	add_child(combat_vfx)
	$Panel.z_index = 4

func _style_combat_panel() -> void:
	VisualTheme.style_heading($Panel/Title, 20, VisualTheme.HONOR)
	$Panel/State.add_theme_color_override("font_color", VisualTheme.CYAN)
	$Panel/State.add_theme_font_size_override("font_size", 16)
	$Panel/Resources.add_theme_color_override("font_color", VisualTheme.OFF_WHITE)
	$Panel/Message.add_theme_color_override("font_color", Color("f2c230"))
	$Panel/Message.add_theme_font_size_override("font_size", 15)
	$Panel/AIHint.add_theme_color_override("font_color", Color("a8b7c9"))
	for i in range(5):
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
	if not SignalBus.technique_clash_resolved.is_connected(_on_technique_clash_resolved):
		SignalBus.technique_clash_resolved.connect(_on_technique_clash_resolved)

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
	for i in range(5):
		var path: String = "Panel/Buttons/Action%s" % [i + 1]
		if not has_node(path):
			continue
		var button: Button = get_node(path)
		action_buttons.append(button)
		button.pressed.connect(_on_action_button_pressed.bind(button))

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
			button.disabled = not affordable
			button.tooltip_text = "Gas %d • Foco %d" % [gas_cost, focus_cost]
		else:
			var is_reset: bool = index == 0 and available.is_empty()
			button.text = "REINICIAR POSICAO" if is_reset else "—"
			button.set_meta("action_id", "reset_position" if is_reset else "")
			button.set_meta("affordable", is_reset)
			button.disabled = not is_reset
			button.tooltip_text = ""

func _on_action_button_pressed(button: Button) -> void:
	if not CombatManager.is_running:
		return
	var action_id: String = str(button.get_meta("action_id", ""))
	if action_id == "" or not bool(button.get_meta("affordable", true)):
		return
	AudioManager.play_sfx("botao")
	_set_actions_enabled(false)
	if ruan_placeholder != null:
		ruan_placeholder.call("play_action", action_id)
	var result: Dictionary = CombatManager.apply_player_action(action_id)
	davi_ai.call("record_player_action", action_id)
	var success: bool = bool(result.get("success", false))
	AudioManager.play_sfx(action_id)
	gamefeel.call("apply_for_technique", action_id, success)
	if CombatManager.is_running:
		await _run_davi_turn()
	if not is_inside_tree():
		return
	if CombatManager.is_running:
		_refresh_action_buttons()
		_set_actions_enabled(true)

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
	_set_ai_hint("%s Resposta escolhida: %s." % [str(davi_ai.call("pressure_message")), technique_name])
	if davi_placeholder != null:
		davi_placeholder.call("play_action", technique_id)
	AudioManager.play_sfx(technique_id)
	var result: Dictionary = CombatManager.apply_opponent_action(technique_id)
	gamefeel.call("apply_for_technique", technique_id, bool(result.get("success", false)))

func _set_actions_enabled(enabled: bool) -> void:
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
		$Panel/Resources.text = "Gas %d • Foco %d • Grip %d • Controle %d" % [
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
	if combat_vfx != null and ruan_placeholder != null and davi_placeholder != null:
		var contact_point: Vector2 = (ruan_placeholder.position + davi_placeholder.position) * 0.5 + Vector2(0.0, 18.0)
		combat_vfx.call("emit_technique", str(result.get("technique_id", result.get("action_id", ""))), contact_point, bool(result.get("success", false)))
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

func _on_technique_clash_resolved(result: Dictionary) -> void:
	if combat_vfx == null or ruan_placeholder == null or davi_placeholder == null:
		return
	var contact_point: Vector2 = (ruan_placeholder.position + davi_placeholder.position) * 0.5 + Vector2(0.0, 8.0)
	combat_vfx.call("emit_clash", contact_point, int(result.get("level_gap", 0)))

func _update_state_label(value) -> void:
	if has_node("Panel/State"):
		$Panel/State.text = "Estado: " + str(estados_ptbr.get(str(value), str(value).replace("_", " ")))

func _on_combat_finished(result) -> void:
	if typeof(result) != TYPE_DICTIONARY:
		return
	WorldState.last_combat_result = result
	SaveManager.save_game(1)
	AudioManager.play_music_cue("vitoria" if result.get("winner", "") == "ruan_macacao" else "derrota")
	var error: Error = get_tree().change_scene_to_file(RESULT_SCENE)
	if error != OK:
		push_error("[CombatArenaBase] Falha ao abrir resultado: %s" % error_string(error))

func _exit_tree() -> void:
	if AudioManager != null:
		AudioManager.stop_ambience()
