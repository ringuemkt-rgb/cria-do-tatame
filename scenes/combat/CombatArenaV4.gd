extends Control

const V4DataBridgeScript = preload("res://src/compat/V4DataBridge.gd")
const SkillHubScript = preload("res://src/hub/SkillHubLoadoutV41.gd")
const CommandRouterScript = preload("res://src/combat/CombatCommandRouterV41.gd")

var bridge
var hub
var combat: PositionalCardCombatV41
var router: CombatCommandRouterV41
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
	bridge = V4DataBridgeScript.new()
	var report: Dictionary = bridge.load_all()
	if not bool(report.get("ok", false)):
		message_label.text = "Dados v4 inválidos: %s" % report.get("errors", [])
		_set_controls_enabled(false)
		return
	hub = SkillHubScript.new()
	hub.configure(bridge.cards)
	for card_id in ["raspagem_tesoura", "knee_cut_pass", "montada", "kimura", "triangulo", "mata_leao"]:
		hub.unlock(card_id, "training")
	hub.set_deck_points(player_id, 100)
	hub.set_deck_points(opponent_id, 100)
	var deck := [
		"grip_de_ferro", "baiana", "guarda_fechada", "raspagem_tesoura",
		"knee_cut_pass", "cem_quilos", "montada", "kimura",
		"triangulo", "mata_leao", "grip_de_ferro", "baiana",
	]
	hub.set_loadout(player_id, deck)
	hub.set_loadout(opponent_id, deck)
	combat = bridge.create_combat({player_id: deck, opponent_id: deck})
	add_child(combat)
	router = CommandRouterScript.new()
	router.setup(combat)
	combat.snapshot_changed.connect(_refresh)
	combat.action_window_opened.connect(_on_window_opened)
	combat.card_resolved.connect(_on_card_resolved)
	combat.combat_finished.connect(_on_combat_finished)
	for index in range(card_buttons.size()):
		card_buttons[index].pressed.connect(_on_card_selected.bind(index))
	var commands := ["grip", "pressao", "transicao", "defesa", "encerrar"]
	for index in range(command_buttons.size()):
		command_buttons[index].pressed.connect(_on_command.bind(commands[index]))
	combat.start_combat(player_id, opponent_id, "OFICIAL")
	message_label.text = "Selecione uma carta ou use os cinco comandos contextuais."

func _process(delta: float) -> void:
	if combat != null:
		combat.tick(delta)

func _on_card_selected(index: int) -> void:
	var hand := combat.get_contextual_hand(player_id)
	if index >= hand.size():
		return
	var card: Dictionary = hand[index]
	selected_card_id = str(card.get("id", ""))
	message_label.text = "Carta selecionada: %s" % str(card.get("nome", selected_card_id))
	_refresh(combat.snapshot())

func _on_command(command: String) -> void:
	if combat == null or combat.phase == "finished" or ai_busy:
		return
	var result: Dictionary = router.execute(player_id, command, selected_card_id if command == "transicao" else "", 0.8)
	if not bool(result.get("ok", false)):
		message_label.text = "Ação bloqueada: %s" % str(result.get("error", "indisponível")).replace("_", " ")
		return
	if command == "transicao":
		selected_card_id = ""
	if combat.phase == "decision":
		call_deferred("_run_ai_turn")

func _run_ai_turn() -> void:
	if combat == null or combat.phase != "decision" or combat.phase == "finished":
		return
	ai_busy = true
	_set_controls_enabled(false)
	await get_tree().create_timer(0.35).timeout
	var hand := combat.get_contextual_hand(opponent_id)
	var chosen := ""
	for card_value in hand:
		var card: Dictionary = card_value
		if bool(card.get("playable", false)):
			chosen = str(card.get("id", ""))
			break
	if chosen != "":
		combat.play_card(opponent_id, chosen, 0.55)
		message_label.text = "Davi iniciou uma técnica. Leia a janela e use DEFESA."
	else:
		router.execute(opponent_id, "grip")
		message_label.text = "Davi reforçou a pegada."
	ai_busy = false
	_set_controls_enabled(true)

func _on_window_opened(window: Dictionary) -> void:
	var defender := str(window.get("defender_id", ""))
	if defender == player_id:
		message_label.text = "JANELA DE DEFESA: %s" % str(window.get("defense", "generic")).replace("_", " ")
	else:
		call_deferred("_resolve_ai_defense")

func _resolve_ai_defense() -> void:
	await get_tree().create_timer(0.2).timeout
	if combat.phase == "defense_window" and str(combat.pending_action.get("defender_id", "")) == opponent_id:
		combat.defend(opponent_id, "generic", 0.42)
		if combat.phase == "decision":
			call_deferred("_run_ai_turn")

func _on_card_resolved(result: Dictionary) -> void:
	var label := "defendida" if bool(result.get("defended", false)) else "executada"
	message_label.text = "%s: %s" % [str(result.get("card_id", "técnica")), label]

func _on_combat_finished(result: Dictionary) -> void:
	_set_controls_enabled(false)
	message_label.text = "Fim: %s · vencedor: %s" % [str(result.get("method", "")), str(result.get("winner_id", "empate"))]

func _refresh(snapshot: Dictionary) -> void:
	position_label.text = "POSIÇÃO: %s · LADO: %s" % [snapshot.get("position", ""), snapshot.get("player_side", "")]
	timer_label.text = "TEMPO: %03d" % int(ceil(float(snapshot.get("time_left", 0.0))))
	var fighters: Dictionary = snapshot.get("fighters", {})
	player_resources.text = _resource_text("RUAN", fighters.get(player_id, {}))
	opponent_resources.text = _resource_text("DAVI", fighters.get(opponent_id, {}))
	var hand := combat.get_contextual_hand(player_id)
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
	command_buttons[2].text = _transition_label(str(snapshot.get("position", "")), str(snapshot.get("player_side", "")))
	command_buttons[3].disabled = combat.phase == "defense_window" and str(combat.pending_action.get("defender_id", "")) != player_id

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

func _transition_label(current_position: String, side: String) -> String:
	match current_position:
		"GUARD": return "PASSAR" if side == "top" else "RASPAR"
		"HALF": return "PASSAR" if side == "top" else "RECOMPOR"
		"SIDE_CONTROL", "MOUNT", "BACK_CONTROL": return "FINALIZAR" if side == "top" else "ESCAPAR"
		_: return "TRANSIÇÃO"

func _set_controls_enabled(enabled: bool) -> void:
	for button in card_buttons + command_buttons:
		button.disabled = not enabled
