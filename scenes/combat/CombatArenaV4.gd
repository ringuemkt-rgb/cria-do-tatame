extends Control

var selected_card_id := ""
var player_id := "ruan_macacao"
var opponent_id := "davi_relampago"
var ai_busy := false

@onready var position_label: Label = $TopHUD/Position
@onready var timer_label: Label = $TopHUD/Timer
@onready var player_resources: Label = $TopHUD/PlayerResources
@onready var opponent_resources: Label = $TopHUD/OpponentResources
@onready var message_label: Label = $BottomHUD/Message
@onready var card_buttons: Array[Button] = [$BottomHUD/Cards/Card1, $BottomHUD/Cards/Card2, $BottomHUD/Cards/Card3]
@onready var command_buttons: Array[Button] = [$BottomHUD/Commands/Grip, $BottomHUD/Commands/Pressao, $BottomHUD/Commands/Transicao, $BottomHUD/Commands/Defesa, $BottomHUD/Commands/Encerrar]

func _ready() -> void:
	SignalBus.positional_snapshot_changed.connect(_refresh)
	SignalBus.defense_window_opened_v41.connect(_on_window_opened)
	SignalBus.technique_resolved.connect(_on_card_resolved)
	SignalBus.combat_finished.connect(_on_combat_finished)
	for index in range(card_buttons.size()):
		card_buttons[index].pressed.connect(_on_card_selected.bind(index))
	var commands := ["grip", "pressao", "transicao", "defesa", "encerrar"]
	for index in range(command_buttons.size()):
		command_buttons[index].pressed.connect(_on_command.bind(commands[index]))
	var result: Dictionary = CombatManager.start_positional_combat_v41("terreiro_da_luta", player_id, opponent_id, "OFICIAL")
	if not bool(result.get("ok", false)):
		message_label.text = "Falha ao iniciar combate v4.1: %s" % str(result.get("error", "desconhecida"))
		_set_controls_enabled(false)
		return
	message_label.text = "Selecione uma carta ou use os cinco comandos contextuais."
	_refresh(CombatManager.get_positional_snapshot_v41())

func _exit_tree() -> void:
	if CombatManager.has_method("stop_positional_mode_v41"):
		CombatManager.stop_positional_mode_v41()

func _on_card_selected(index: int) -> void:
	var hand := CombatManager.get_contextual_hand_v41(player_id)
	if index >= hand.size():
		return
	var card: Dictionary = hand[index]
	selected_card_id = str(card.get("id", ""))
	var result: Dictionary = CombatManager.select_card_v41(selected_card_id)
	if bool(result.get("ok", false)):
		message_label.text = "Carta selecionada: %s" % str(card.get("nome", selected_card_id))
	else:
		message_label.text = "Carta indisponível: %s" % str(result.get("error", "bloqueada")).replace("_", " ")
	_refresh(CombatManager.get_positional_snapshot_v41())

func _on_command(command: String) -> void:
	var snapshot: Dictionary = CombatManager.get_positional_snapshot_v41()
	if snapshot.is_empty() or str(snapshot.get("phase", "")) == "finished" or ai_busy:
		return
	if command == "transicao" and str(snapshot.get("phase", "")) == "submission":
		var pending: Dictionary = snapshot.get("pending_action", {})
		if str(pending.get("attacker_id", "")) == player_id:
			CombatManager.resolve_submission_v41(0.78, 0.48, false)
			return
	var result: Dictionary = CombatManager.execute_command_v41(
		player_id,
		command,
		selected_card_id if command == "transicao" else "",
		0.8
	)
	if not bool(result.get("ok", false)):
		message_label.text = "Ação bloqueada: %s" % str(result.get("error", "indisponível")).replace("_", " ")
		return
	if command == "transicao":
		selected_card_id = ""
	var after: Dictionary = CombatManager.get_positional_snapshot_v41()
	if str(after.get("phase", "")) == "decision":
		call_deferred("_run_ai_turn")

func _run_ai_turn() -> void:
	var snapshot: Dictionary = CombatManager.get_positional_snapshot_v41()
	if snapshot.is_empty() or str(snapshot.get("phase", "")) != "decision" or not CombatManager.is_running:
		return
	ai_busy = true
	_set_controls_enabled(false)
	await get_tree().create_timer(0.35).timeout
	var hand := CombatManager.get_contextual_hand_v41(opponent_id)
	var chosen := ""
	for card_value in hand:
		var card: Dictionary = card_value
		if bool(card.get("playable", false)):
			chosen = str(card.get("id", ""))
			break
	if chosen != "":
		CombatManager.play_card_v41(opponent_id, chosen, 0.55)
		message_label.text = "Davi iniciou uma técnica. Leia a janela e use DEFESA."
	else:
		CombatManager.execute_command_v41(opponent_id, "grip", "", 0.6)
		message_label.text = "Davi reforçou a pegada."
	ai_busy = false
	_set_controls_enabled(true)
	var after: Dictionary = CombatManager.get_positional_snapshot_v41()
	if str(after.get("phase", "")) == "submission" and str(after.get("pending_action", {}).get("attacker_id", "")) == opponent_id:
		call_deferred("_resolve_ai_submission")

func _on_window_opened(window: Dictionary) -> void:
	var defender := str(window.get("defender_id", ""))
	if defender == player_id:
		message_label.text = "JANELA DE DEFESA: %s" % str(window.get("defense", "generic")).replace("_", " ")
	else:
		call_deferred("_resolve_ai_defense")

func _resolve_ai_defense() -> void:
	await get_tree().create_timer(0.2).timeout
	var snapshot: Dictionary = CombatManager.get_positional_snapshot_v41()
	if str(snapshot.get("phase", "")) == "defense_window" and str(snapshot.get("pending_action", {}).get("defender_id", "")) == opponent_id:
		CombatManager.defend_v41(opponent_id, "generic", 0.42)
		if str(CombatManager.get_positional_snapshot_v41().get("phase", "")) == "decision":
			call_deferred("_run_ai_turn")

func _resolve_ai_submission() -> void:
	await get_tree().create_timer(0.4).timeout
	var snapshot: Dictionary = CombatManager.get_positional_snapshot_v41()
	if str(snapshot.get("phase", "")) == "submission":
		CombatManager.resolve_submission_v41(0.64, 0.58, false)

func _on_card_resolved(result: Dictionary) -> void:
	if not bool(result.get("v41", false)) and not result.has("card_id"):
		return
	var label := "defendida" if bool(result.get("defended", false)) else "executada"
	message_label.text = "%s: %s" % [str(result.get("card_id", "técnica")), label]

func _on_combat_finished(result: Dictionary) -> void:
	if not bool(result.get("v41", false)):
		return
	_set_controls_enabled(false)
	message_label.text = "Fim: %s · vencedor: %s" % [str(result.get("method", "")), str(result.get("winner", "empate"))]

func _refresh(snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		return
	position_label.text = "POSIÇÃO: %s · LADO: %s" % [snapshot.get("position", ""), snapshot.get("player_side", "")]
	timer_label.text = "TEMPO: %03d" % int(ceil(float(snapshot.get("time_left", 0.0))))
	var fighters: Dictionary = snapshot.get("fighters", {})
	player_resources.text = _resource_text("RUAN", fighters.get(player_id, {}))
	opponent_resources.text = _resource_text("DAVI", fighters.get(opponent_id, {}))
	var hand := CombatManager.get_contextual_hand_v41(player_id)
	for index in range(card_buttons.size()):
		var button := card_buttons[index]
		if index >= hand.size():
			button.text = "—"
			button.disabled = true
			continue
		var card: Dictionary = hand[index]
		var cost: Dictionary = card.get("custo", {})
		button.text = "%s\nG%d · F%d · P%d" % [card.get("nome", card.get("id", "")), int(cost.get("gas", 0)), int(cost.get("foco", 0)), int(cost.get("grip", 0))]
		button.disabled = not bool(card.get("playable", false))
		button.button_pressed = selected_card_id == str(card.get("id", ""))
	command_buttons[2].text = _transition_label(str(snapshot.get("position", "")), str(snapshot.get("player_side", "")), str(snapshot.get("phase", "")))
	command_buttons[3].disabled = str(snapshot.get("phase", "")) == "defense_window" and str(snapshot.get("pending_action", {}).get("defender_id", "")) != player_id

func _resource_text(name: String, resources: Dictionary) -> String:
	return "%s · INT %d · GÁS %d · FOCO %d · GRIP %d · PRESSÃO %d · GUARDA %d" % [
		name,
		int(resources.get("integridade", 0)),
		int(resources.get("gas", 0)),
		int(resources.get("foco", 0)),
		int(resources.get("grip", 0)),
		int(resources.get("pressao", 0)),
		int(resources.get("guarda", 0)),
	]

func _transition_label(current_position: String, side: String, phase_name: String) -> String:
	if phase_name == "submission":
		return "CONFIRMAR SUB"
	match current_position:
		"GUARD": return "PASSAR" if side == "top" else "RASPAR"
		"HALF": return "PASSAR" if side == "top" else "RECOMPOR"
		"SIDE_CONTROL", "MOUNT", "BACK_CONTROL": return "FINALIZAR" if side == "top" else "ESCAPAR"
		_: return "TRANSIÇÃO"

func _set_controls_enabled(enabled: bool) -> void:
	for button in card_buttons + command_buttons:
		button.disabled = not enabled
