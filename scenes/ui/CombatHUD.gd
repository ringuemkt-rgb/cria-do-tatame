extends CanvasLayer

var estados_ptbr := {
	"PLAYER_STANDING_NEUTRAL": "EM PE - NEUTRO",
	"PLAYER_TOP_CLINCH": "CLINCH - POR CIMA",
	"PLAYER_BOTTOM_CLINCH": "CLINCH - POR BAIXO",
	"PLAYER_TOP_GUARD": "GUARDA - POR CIMA",
	"PLAYER_BOTTOM_GUARD": "GUARDA - POR BAIXO",
	"PLAYER_TOP_SIDE": "LATERAL - POR CIMA",
	"PLAYER_BOTTOM_SIDE": "LATERAL - POR BAIXO",
	"PLAYER_TOP_MOUNT": "MONTADA - POR CIMA",
	"PLAYER_BOTTOM_MOUNT": "MONTADA - POR BAIXO",
	"PLAYER_BACK_ATTACK": "COSTAS - ATACANDO",
	"PLAYER_BACK_DEFENSE": "COSTAS - DEFENDENDO",
	"PLAYER_SUBMISSION_ATTACK": "ENCERRAMENTO - ATACANDO",
	"PLAYER_SUBMISSION_DEFENSE": "ENCERRAMENTO - DEFENDENDO",
	"RESET": "REINICIANDO"
}

func update_state(state_name: String) -> void:
	if has_node("TopBar/StateLabel"):
		$TopBar/StateLabel.text = estados_ptbr.get(state_name, state_name)

func update_player_resources(resources: Dictionary) -> void:
	_update_bar("TopBar/PlayerPanel/PlayerHP", resources.get("health", 100), 100)
	_update_bar("TopBar/PlayerPanel/PlayerGas", resources.get("gas", 100), 100)
	_update_bar("TopBar/PlayerPanel/PlayerGuarda", resources.get("guard", resources.get("grip_integrity", 100)), 100)
	_update_bar("TopBar/PlayerPanel/PlayerFoco", resources.get("focus", 100), 100)
	_update_bar("TopBar/PlayerPanel/PlayerMoral", resources.get("moral", 100), 100)

func update_opponent_resources(resources: Dictionary) -> void:
	_update_bar("TopBar/OpponentPanel/OpponentHP", resources.get("health", 100), 100)
	_update_bar("TopBar/OpponentPanel/OpponentGas", resources.get("gas", 100), 100)

func show_message(msg: String, duration: float = 2.0) -> void:
	if not has_node("MessageLabel"):
		return
	$MessageLabel.text = msg
	await get_tree().create_timer(duration).timeout
	$MessageLabel.text = ""

func _update_bar(path: String, value: float, max_value: float) -> void:
	if has_node(path):
		var bar = get_node(path)
		bar.max_value = max_value
		bar.value = value
