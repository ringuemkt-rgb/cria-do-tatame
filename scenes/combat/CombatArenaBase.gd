extends Control

const RESULT_SCENE := "res://scenes/result/ResultScreen.tscn"

var actions := ["grip_de_ferro", "baiana", "corte_joelho", "sprawl", "encerramento_tecnico"]
var labels := ["Grip de Ferro", "Baiana", "Corte de Joelho", "Sprawl", "Encerrar"]

var estados_ptbr := {
	"DISTANCE": "EM PE - NEUTRO",
	"GRIP": "DISPUTA DE PEGADA",
	"CLINCH": "CLINCH",
	"TAKEDOWN": "QUEDA",
	"GROUND": "CHAO",
	"TRANSITION": "TRANSICAO",
	"TECHNICAL": "ENCERRAMENTO TECNICO",
	"RESET": "REINICIANDO"
}

func _ready() -> void:
	CombatManager.start_combat("terreiro_da_luta", "ruan_macacao", "davi_relampago")
	SignalBus.resources_changed.connect(_on_resources_changed)
	SignalBus.combat_state_changed.connect(_on_combat_state_changed)
	SignalBus.combat_finished.connect(_on_combat_finished)
	SignalBus.technique_resolved.connect(_on_technique_resolved)
	_connect_buttons()
	_update_state_label("DISTANCE")

func _connect_buttons() -> void:
	for i in range(actions.size()):
		var path = "Panel/Buttons/Action%s" % [i + 1]
		if has_node(path):
			var btn = get_node(path)
			btn.text = labels[i]
			btn.pressed.connect(_on_action_pressed.bind(actions[i]))

func _on_action_pressed(action_id: String) -> void:
	CombatManager.apply_player_action(action_id)

func _on_resources_changed(fighter_id, resources) -> void:
	if has_node("Panel/Resources"):
		$Panel/Resources.text = "%s • Gas %s • Foco %s • Grip %s • Controle %s" % [fighter_id, resources.get("gas", 0), resources.get("focus", 0), resources.get("grip_integrity", 0), resources.get("control", 0)]

func _on_combat_state_changed(old_state, new_state) -> void:
	_update_state_label(new_state)

func _on_technique_resolved(result) -> void:
	if has_node("Panel/Message"):
		var nome = DataRegistry.get_technique(str(result.get("technique_id", ""))).get("nome", result.get("technique_id", ""))
		$Panel/Message.text = "%s: %s" % [nome, "sucesso" if result.get("success", false) else "defendido"]

func _update_state_label(value) -> void:
	if has_node("Panel/State"):
		$Panel/State.text = "Estado: " + estados_ptbr.get(str(value), str(value))

func _on_combat_finished(result) -> void:
	WorldState.last_combat_result = result
	SaveManager.save_game(1)
	get_tree().change_scene_to_file(RESULT_SCENE)
