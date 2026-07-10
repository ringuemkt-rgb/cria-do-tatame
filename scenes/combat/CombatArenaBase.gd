extends Control

const RESULT_SCENE := "res://scenes/result/ResultScreen.tscn"
const FighterPlaceholderScript := preload("res://src/characters/FighterPlaceholder.gd")
const GameFeelManagerScript := preload("res://src/gamefeel/GameFeelManager.gd")
const DaviAIControllerScript := preload("res://src/combat/DaviAIController.gd")

var gamefeel
var davi_ai
var ruan_placeholder
var davi_placeholder
var action_buttons: Array[Button] = []

var estados_ptbr := {
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
	gamefeel = GameFeelManagerScript.new()
	add_child(gamefeel)
	davi_ai = DaviAIControllerScript.new()
	add_child(davi_ai)
	_build_placeholder_fighters()
	_connect_buttons()
	_connect_runtime_signals()
	CombatManager.start_combat("terreiro_da_luta", "ruan_macacao", "davi_relampago")
	_ensure_ai_hint()
	_update_state_label(CombatManager.get_current_state_name())
	_refresh_action_buttons()
	AudioManager.play_music_cue("terreiro")

func _connect_runtime_signals() -> void:
	if not SignalBus.resources_changed.is_connected(_on_resources_changed):
		SignalBus.resources_changed.connect(_on_resources_changed)
	if not SignalBus.combat_state_changed.is_connected(_on_combat_state_changed):
		SignalBus.combat_state_changed.connect(_on_combat_state_changed)
	if not SignalBus.combat_finished.is_connected(_on_combat_finished):
		SignalBus.combat_finished.connect(_on_combat_finished)
	if not SignalBus.technique_resolved.is_connected(_on_technique_resolved):
		SignalBus.technique_resolved.connect(_on_technique_resolved)

func _build_placeholder_fighters() -> void:
	ruan_placeholder = FighterPlaceholderScript.new()
	ruan_placeholder.fighter_id = "ruan_macacao"
	ruan_placeholder.display_name = "Ruan Macacao"
	ruan_placeholder.position = Vector2(420, 360)
	add_child(ruan_placeholder)
	davi_placeholder = FighterPlaceholderScript.new()
	davi_placeholder.fighter_id = "davi_relampago"
	davi_placeholder.display_name = "Davi Relampago"
	davi_placeholder.primary_color = Color(0.22, 0.28, 0.34)
	davi_placeholder.accent_color = Color(0.55, 0.75, 1.0)
	davi_placeholder.position = Vector2(760, 360)
	davi_placeholder.scale.x = -1
	add_child(davi_placeholder)

func _ensure_ai_hint() -> void:
	if has_node("Panel") and not has_node("Panel/AIHint"):
		var label := Label.new()
		label.name = "AIHint"
		label.text = "Davi esta lendo seu ritmo. Varie as entradas."
		get_node("Panel").add_child(label)

func _connect_buttons() -> void:
	action_buttons.clear()
	for i in range(5):
		var path := "Panel/Buttons/Action%s" % [i + 1]
		if not has_node(path):
			continue
		var button: Button = get_node(path)
		action_buttons.append(button)
		button.pressed.connect(_on_action_button_pressed.bind(button))

func _refresh_action_buttons() -> void:
	var available := CombatManager.get_available_techniques()
	for index in range(action_buttons.size()):
		var button := action_buttons[index]
		if index < available.size():
			var technique: Dictionary = available[index]
			var technique_id := str(technique.get("id", ""))
			var label := str(technique.get("nome", technique.get("name", technique_id)))
			var cost: Dictionary = technique.get("cost", technique.get("custo", {}))
			var gas_cost := int(cost.get("gas", technique.get("gas_cost", 0)))
			var focus_cost := int(cost.get("focus", cost.get("foco", technique.get("focus_cost", 0))))
			var affordable := bool(technique.get("affordable", true))
			button.text = label
			button.set_meta("action_id", technique_id)
			button.set_meta("affordable", affordable)
			button.disabled = not affordable
			button.tooltip_text = "Gas %d • Foco %d" % [gas_cost, focus_cost]
		else:
			var is_reset := index == 0 and available.is_empty()
			button.text = "REINICIAR POSICAO" if is_reset else "—"
			button.set_meta("action_id", "reset_position" if is_reset else "")
			button.set_meta("affordable", is_reset)
			button.disabled = not is_reset
			button.tooltip_text = ""

func _on_action_button_pressed(button: Button) -> void:
	if not CombatManager.is_running:
		return
	var action_id := str(button.get_meta("action_id", ""))
	if action_id == "" or not bool(button.get_meta("affordable", true)):
		return
	AudioManager.play_sfx("botao")
	_set_actions_enabled(false)
	if ruan_placeholder != null:
		ruan_placeholder.play_action(action_id)
	var result: Dictionary = CombatManager.apply_player_action(action_id)
	davi_ai.record_player_action(action_id)
	var success := bool(result.get("success", false))
	AudioManager.play_sfx(action_id)
	gamefeel.apply_for_technique(action_id, success)
	_update_ai_hint(result)
	if CombatManager.is_running:
		_refresh_action_buttons()
		_set_actions_enabled(true)

func _set_actions_enabled(enabled: bool) -> void:
	for button in action_buttons:
		if enabled:
			var action_id := str(button.get_meta("action_id", ""))
			var affordable := bool(button.get_meta("affordable", true))
			button.disabled = action_id == "" or not affordable
		else:
			button.disabled = true

func _update_ai_hint(result: Dictionary) -> void:
	if not has_node("Panel/AIHint"):
		return
	var phase_name := str(result.get("phase", "DISTANCE"))
	var player_resources: Dictionary = CombatManager.fighters.get("ruan_macacao", {})
	var response := davi_ai.choose_response(phase_name, player_resources)
	$Panel/AIHint.text = "%s Proxima leitura: %s" % [davi_ai.pressure_message(), response]
	if davi_placeholder != null:
		davi_placeholder.play_action(response)

func _on_resources_changed(fighter_id, resources) -> void:
	if str(fighter_id) != CombatManager.player_id:
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
		var technique_id := str(result.get("technique_id", result.get("action_id", "")))
		var technique: Dictionary = DataRegistry.get_technique(technique_id)
		var name := str(technique.get("nome", technique.get("name", technique_id)))
		var message := str(result.get("message", "sucesso" if result.get("success", false) else "defendido"))
		$Panel/Message.text = "%s: %s" % [name, _humanize_message(message)]
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
		$Panel/State.text = "Estado: " + estados_ptbr.get(str(value), str(value).replace("_", " "))

func _on_combat_finished(result) -> void:
	WorldState.last_combat_result = result
	SaveManager.save_game(1)
	AudioManager.play_music_cue("vitoria" if result.get("winner", "") == "ruan_macacao" else "derrota")
	var error := get_tree().change_scene_to_file(RESULT_SCENE)
	if error != OK:
		push_error("[CombatArenaBase] Falha ao abrir resultado: %s" % error_string(error))
