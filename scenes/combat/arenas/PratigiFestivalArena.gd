extends "res://scenes/combat/CombatArenaBase.gd"

const CONFIG_PATH := "res://data/arenas/pratigi_festival_v01.json"
const MAP_SCENE := "res://scenes/world/WorldMapScreen.tscn"

@onready var event_director: ClandestineEventDirector = $EventDirector
@onready var pratigi_backdrop: PratigiFestivalBackdrop = $ArenaBackdrop
@onready var water_line: AnimatedWaterLine = $AnimatedWaterLine
@onready var pre_fight_modal: Control = $PreFightModal
@onready var bet_amount: SpinBox = $PreFightModal/Center/Card/VBox/BetRow/BetAmount
@onready var potential_label: Label = $PreFightModal/Center/Card/VBox/Potential
@onready var pre_fight_message: Label = $PreFightModal/Center/Card/VBox/Message
@onready var heat_bar: ProgressBar = $EventHUD/VBox/HeatBar
@onready var heat_label: Label = $EventHUD/VBox/HeatLabel
@onready var bet_label: Label = $EventHUD/VBox/BetLabel
@onready var tide_label: Label = $EventHUD/VBox/TideLabel
@onready var warning_banner: Label = $WarningBanner
@onready var crowd_chant: Label = $CrowdChant
@onready var interdiction_overlay: Control = $InterdictionOverlay

var event_config: Dictionary = {}
var _interdiction_handled: bool = false
var _combat_started: bool = false
var _settled: bool = false
var _reduced_motion: bool = false
var _crowd_tween: Tween


func _ready() -> void:
	super._ready()
	event_config = _load_event_config()
	if event_config.is_empty():
		_disable_event("Configuração do Festival Maré Alta indisponível.")
		return
	event_director.configure(event_config)
	_connect_event_signals()
	_configure_presentation()
	_configure_betting_ui()
	_update_bet_ui(event_director.get_bet_snapshot())
	_on_heat_changed(event_director.heat, event_director.get_state_name())


func _connect_event_signals() -> void:
	event_director.bet_changed.connect(_update_bet_ui)
	event_director.heat_changed.connect(_on_heat_changed)
	event_director.warning_issued.connect(_on_warning_issued)
	event_director.interdiction_triggered.connect(_on_interdiction_triggered)
	event_director.event_settled.connect(_on_event_settled)
	water_line.tide_level_changed.connect(_on_tide_level_changed)
	$PreFightModal/Center/Card/VBox/PlaceBet.pressed.connect(_on_place_bet_pressed)
	$PreFightModal/Center/Card/VBox/StartEvent.pressed.connect(_on_start_event_pressed)
	$PreFightModal/Center/Card/VBox/Cancel.pressed.connect(_on_cancel_pressed)


func _configure_presentation() -> void:
	var presentation: Dictionary = event_config.get("presentation", {})
	pratigi_backdrop.crowd_count = int(presentation.get("crowd_count_mobile", 40))
	var accessibility: Dictionary = DataRegistry.settings.get("accessibility", {})
	_reduced_motion = bool(accessibility.get("reduced_motion", false))
	pratigi_backdrop.reduced_motion = _reduced_motion
	water_line.reduced_motion = _reduced_motion
	water_line.visual_cycle_seconds = float(event_config.get("tide", {}).get("visual_cycle_seconds", 124.2))
	pratigi_backdrop.set_crowd_intensity(0.72)


func _configure_betting_ui() -> void:
	var betting: Dictionary = event_config.get("betting", {})
	bet_amount.min_value = float(betting.get("minimum_stake", 0))
	bet_amount.max_value = float(betting.get("maximum_stake", 150))
	bet_amount.step = float(betting.get("stake_step", 25))
	bet_amount.value = 0.0
	bet_amount.allow_greater = false
	bet_amount.allow_lesser = false
	$PreFightModal/Center/Card/VBox/Wallet.text = "Carteira: R$ %d (somente moeda interna)" % WorldState.money
	_update_potential_label()
	if not bet_amount.value_changed.is_connected(_on_bet_amount_changed):
		bet_amount.value_changed.connect(_on_bet_amount_changed)


func _on_bet_amount_changed(_value: float) -> void:
	_update_potential_label()


func _update_potential_label() -> void:
	var multiplier: float = float(event_config.get("betting", {}).get("payout_multiplier", 1.0))
	var payout := int(round(bet_amount.value * multiplier))
	potential_label.text = "Retorno transparente se vencer: R$ %d" % payout


func _on_place_bet_pressed() -> void:
	var result := event_director.place_bet(int(bet_amount.value), WorldState.money)
	if not bool(result.get("ok", false)):
		pre_fight_message.text = _bet_error_text(str(result.get("reason", "unknown")))
		return
	WorldState.money += int(result.get("wallet_delta", 0))
	$PreFightModal/Center/Card/VBox/Wallet.text = "Carteira: R$ %d (somente moeda interna)" % WorldState.money
	pre_fight_message.text = "Aposta registrada." if event_director.bet_placed else "Você escolheu lutar sem apostar."
	SaveManager.save_game(1)


func _on_start_event_pressed() -> void:
	if _combat_started:
		return
	var start_result := event_director.start_event()
	if not bool(start_result.get("ok", false)):
		pre_fight_message.text = "O evento ainda não pode começar."
		return
	_combat_started = true
	pre_fight_modal.visible = false
	$EventHUD.visible = true
	_start_configured_combat()
	AudioManager.play_sfx("crowd_roar")
	_show_crowd_shout("MACACÃO! MACACÃO!")
	_apply_configured_consequence("participation")
	WorldState.story_flags["pratigi_festival_entered"] = true
	SaveManager.save_game(1)


func _on_cancel_pressed() -> void:
	if _combat_started:
		return
	var refund := event_director.cancel_bet()
	WorldState.money += int(refund.get("wallet_delta", 0))
	SaveManager.save_game(1)
	get_tree().change_scene_to_file(MAP_SCENE)


func _update_bet_ui(snapshot: Dictionary) -> void:
	var stake := int(snapshot.get("stake", 0))
	var potential := int(snapshot.get("potential_payout", 0))
	bet_label.text = "Aposta: R$ %d • retorno R$ %d" % [stake, potential]
	$PreFightModal/Center/Card/VBox/StartEvent.text = "ENTRAR NA ARENA" if stake == 0 else "ENTRAR NA ARENA COM APOSTA"


func _on_heat_changed(value: float, state_name: String) -> void:
	heat_bar.value = value
	heat_label.text = "HEAT %d%% • %s" % [int(round(value)), _heat_state_text(state_name)]
	pratigi_backdrop.set_heat_level(value)


func _on_tide_level_changed(value: float) -> void:
	pratigi_backdrop.set_tide_level(value)
	tide_label.text = "Maré: %s • %d%%" % [water_line.get_state_name(), int(round(value * 100.0))]


func _on_warning_issued(_snapshot: Dictionary) -> void:
	warning_banner.visible = true
	warning_banner.text = "ATENÇÃO: AUTORIDADES A CAMINHO — o evento pode ser interditado"
	AudioManager.play_music_cue("authority_warning")
	CriaLiveManager.create_post(
		"O Festival Maré Alta entrou no radar. A praia ainda grita, mas o relógio agora pesa.",
		"alerta_autoridade",
		"cria_live",
		{
			"source_event": "pratigi_heat_warning",
			"metrics": {"reach": 90, "polarization": 5, "authority_attention": 9}
		}
	)


func _on_interdiction_triggered(snapshot: Dictionary) -> void:
	if _interdiction_handled:
		return
	_interdiction_handled = true
	_set_actions_enabled(false)
	interdiction_overlay.visible = true
	$InterdictionOverlay/Center/VBox/Details.text = "Heat %d%% • combate encerrado com segurança • sem minigame de fuga" % int(snapshot.get("heat", 100))
	AudioManager.play_music_cue("authority_warning")
	_complete_interdiction()


func _complete_interdiction() -> void:
	if CombatManager.is_running:
		CombatManager.finish_combat({
			"winner": "",
			"loser": "",
			"method": "evento_interditado",
			"technical": false,
			"interrupted": true,
			"skip_career_result": true,
			"arena_id": configured_arena_id,
			"heat": event_director.heat
		})


func _on_technique_resolved(result) -> void:
	super._on_technique_resolved(result)
	if typeof(result) == TYPE_DICTIONARY:
		event_director.register_technique(result)
		if bool(result.get("success", false)) and event_director.get_state_name() in ["live", "warning"]:
			var actor_id := str(result.get("actor_id", ""))
			_show_crowd_shout("VAI, MACACÃO!" if actor_id == configured_player_id else "SEGURA A BASE!")


func _show_crowd_shout(text: String) -> void:
	if _crowd_tween != null and _crowd_tween.is_valid():
		_crowd_tween.kill()
	crowd_chant.text = text
	crowd_chant.visible = true
	crowd_chant.modulate.a = 1.0
	crowd_chant.scale = Vector2.ONE
	_crowd_tween = create_tween()
	if not _reduced_motion:
		crowd_chant.scale = Vector2(0.96, 0.96)
		_crowd_tween.tween_property(crowd_chant, "scale", Vector2.ONE, 0.12)
	_crowd_tween.tween_interval(0.45)
	_crowd_tween.tween_property(crowd_chant, "modulate:a", 0.0, 0.55)
	_crowd_tween.tween_callback(func(): crowd_chant.visible = false)


func _on_combat_finished(result) -> void:
	if typeof(result) != TYPE_DICTIONARY or _settled:
		return
	_settled = true
	var settlement := event_director.settle(result, configured_player_id)
	WorldState.money += int(settlement.get("wallet_delta", 0))
	result["bet_settlement"] = settlement
	result["heat"] = event_director.heat
	WorldState.story_flags["pratigi_last_event"] = {
		"week": WorldState.week,
		"status": settlement.get("status", "unknown"),
		"heat": event_director.heat,
		"stake": settlement.get("stake", 0),
		"payout": settlement.get("payout", 0)
	}
	if bool(result.get("interrupted", false)):
		_apply_configured_consequence("interdiction")
		WorldState.last_combat_result = result
		SaveManager.save_game(1)
		await get_tree().create_timer(1.0).timeout
		get_tree().change_scene_to_file(MAP_SCENE)
		return
	if str(result.get("winner", "")) == configured_player_id:
		_apply_configured_consequence("clean_win")
	SaveManager.save_game(1)
	super._on_combat_finished(result)


func _on_event_settled(settlement: Dictionary) -> void:
	match str(settlement.get("status", "")):
		"won":
			$Panel/Message.text = "Aposta liquidada: +R$ %d." % int(settlement.get("payout", 0))
		"lost":
			$Panel/Message.text = "A aposta ficou na areia. O resultado cobra."
		"interdicted":
			$Panel/Message.text = "Evento interditado: aposta sem pagamento."


func _apply_configured_consequence(consequence_id: String) -> void:
	var changes: Dictionary = event_config.get("consequences", {}).get(consequence_id, {})
	for axis_value in changes.keys():
		var axis := str(axis_value)
		if axis in ["honra", "hype", "sombra", "legado", "moral", "raiz"]:
			WorldState.modify_reputation(axis, float(changes[axis_value]))


func _load_event_config() -> Dictionary:
	if not FileAccess.file_exists(CONFIG_PATH):
		return {}
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func _disable_event(message: String) -> void:
	pre_fight_message.text = message
	$PreFightModal/Center/Card/VBox/PlaceBet.disabled = true
	$PreFightModal/Center/Card/VBox/StartEvent.disabled = true


func _bet_error_text(reason: String) -> String:
	match reason:
		"insufficient_funds": return "Dinheiro insuficiente. Entre sem apostar ou reduza o valor."
		"invalid_stake": return "Valor fora dos limites transparentes do evento."
		"unsafe_betting_config": return "A configuração de aposta foi bloqueada por segurança."
		"betting_closed": return "As apostas já fecharam."
	return "Não foi possível registrar a aposta."


func _heat_state_text(state_name: String) -> String:
	match state_name:
		"setup": return "organização"
		"ready": return "pronto"
		"live": return "evento ativo"
		"warning": return "autoridades a caminho"
		"interdicted": return "interditado"
		"resolved": return "encerrado"
	return state_name


func _exit_tree() -> void:
	if not _combat_started and event_director != null and event_director.bet_placed and not event_director.bet_locked:
		var refund := event_director.cancel_bet()
		WorldState.money += int(refund.get("wallet_delta", 0))
