extends Control

const RESULT_SCENE := "res://scenes/result/ResultScreen.tscn"
const FighterPlaceholderScript := preload("res://src/characters/FighterPlaceholder.gd")
const GameFeelManagerScript := preload("res://src/gamefeel/GameFeelManager.gd")
const DaviAIControllerScript := preload("res://src/combat/DaviAIController.gd")

var actions := ["grip_de_ferro", "baiana", "corte_joelho", "sprawl", "encerramento_tecnico"]
var labels := ["Grip de Ferro", "Baiana", "Corte de Joelho", "Sprawl", "Encerrar"]
var gamefeel
var davi_ai
var ruan_placeholder
var davi_placeholder

var estados_ptbr := {
	"DISTANCE": "EM PÉ - NEUTRO",
	"GRIP": "DISPUTA DE PEGADA",
	"CLINCH": "CLINCH",
	"TAKEDOWN": "QUEDA",
	"GROUND": "CHÃO",
	"TRANSITION": "TRANSIÇÃO",
	"TECHNICAL": "ENCERRAMENTO TÉCNICO",
	"RESET": "REINICIANDO"
}

func _ready() -> void:
	gamefeel = GameFeelManagerScript.new()
	add_child(gamefeel)
	davi_ai = DaviAIControllerScript.new()
	add_child(davi_ai)
	_build_placeholder_fighters()
	CombatManager.start_combat("terreiro_da_luta", "ruan_macacao", "davi_relampago")
	SignalBus.resources_changed.connect(_on_resources_changed)
	SignalBus.combat_state_changed.connect(_on_combat_state_changed)
	SignalBus.combat_finished.connect(_on_combat_finished)
	SignalBus.technique_resolved.connect(_on_technique_resolved)
	_connect_buttons()
	_update_state_label("DISTANCE")
	AudioManager.play_music_cue("terreiro")

func _build_placeholder_fighters() -> void:
	ruan_placeholder = FighterPlaceholderScript.new()
	ruan_placeholder.fighter_id = "ruan_macacao"
	ruan_placeholder.display_name = "Ruan Macacão"
	ruan_placeholder.position = Vector2(420, 360)
	add_child(ruan_placeholder)
	davi_placeholder = FighterPlaceholderScript.new()
	davi_placeholder.fighter_id = "davi_relampago"
	davi_placeholder.display_name = "Davi Relâmpago"
	davi_placeholder.primary_color = Color(0.22, 0.28, 0.34)
	davi_placeholder.accent_color = Color(0.55, 0.75, 1.0)
	davi_placeholder.position = Vector2(760, 360)
	davi_placeholder.scale.x = -1
	add_child(davi_placeholder)

func _connect_buttons() -> void:
	for i in range(actions.size()):
		var path = "Panel/Buttons/Action%s" % [i + 1]
		if has_node(path):
			var btn = get_node(path)
			btn.text = labels[i]
			btn.pressed.connect(_on_action_pressed.bind(actions[i]))

func _on_action_pressed(action_id: String) -> void:
	AudioManager.play_sfx("botao")
	if ruan_placeholder != null:
		ruan_placeholder.play_action(action_id)
	var result = CombatManager.apply_player_action(action_id)
	davi_ai.record_player_action(action_id)
	var success := bool(result.get("result", result).get("success", false))
	AudioManager.play_sfx(action_id)
	gamefeel.apply_for_technique(action_id, success)
	_update_ai_hint(result)

func _update_ai_hint(result: Dictionary) -> void:
	if not has_node("Panel/AIHint"):
		return
	var phase := str(result.get("phase", result.get("combat_state", "DISTANCE")))
	var player_resources := CombatManager.fighters.get("ruan_macacao", {})
	var response := davi_ai.choose_response(phase, player_resources)
	$Panel/AIHint.text = "%s Próxima leitura: %s" % [davi_ai.pressure_message(), response]
	if davi_placeholder != null:
		davi_placeholder.play_action(response)

func _on_resources_changed(fighter_id, resources) -> void:
	if has_node("Panel/Resources"):
		$Panel/Resources.text = "%s • Gás %s • Foco %s • Grip %s • Controle %s" % [fighter_id, resources.get("gas", 0), resources.get("focus", 0), resources.get("grip_integrity", 0), resources.get("control", 0)]

func _on_combat_state_changed(old_state, new_state) -> void:
	_update_state_label(new_state)

func _on_technique_resolved(result) -> void:
	if has_node("Panel/Message"):
		var nome = DataRegistry.get_technique(str(result.get("technique_id", ""))).get("nome", result.get("technique_id", ""))
		$Panel/Message.text = "%s: %s" % [nome, "sucesso" if result.get("success", false) else "defendido"]
	SignalBus.technique_executed.emit(StringName(result.get("actor_id", "ruan_macacao")), StringName(result.get("technique_id", "unknown")))

func _update_state_label(value) -> void:
	if has_node("Panel/State"):
		$Panel/State.text = "Estado: " + estados_ptbr.get(str(value), str(value))

func _on_combat_finished(result) -> void:
	WorldState.last_combat_result = result
	SaveManager.save_game(1)
	AudioManager.play_music_cue("vitoria" if result.get("winner", "") == "ruan_macacao" else "derrota")
	get_tree().change_scene_to_file(RESULT_SCENE)
