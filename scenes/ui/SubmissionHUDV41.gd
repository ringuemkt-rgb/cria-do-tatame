extends Control

@export var reduced_motion := false
@export var attempts_required := 3
@export var attempt_duration := 1.6

var active := false
var player_is_attacker := false
var attacker_id := ""
var defender_id := ""
var elapsed := 0.0
var attempt_index := 0
var player_total := 0.0
var ai_total := 0.0

@onready var title_label: Label = $Panel/Margin/VBox/Title
@onready var instruction_label: Label = $Panel/Margin/VBox/Instruction
@onready var timing_bar: ProgressBar = $Panel/Margin/VBox/TimingBar
@onready var progress_label: Label = $Panel/Margin/VBox/ProgressLabel
@onready var action_button: Button = $Panel/Margin/VBox/Buttons/Action
@onready var release_button: Button = $Panel/Margin/VBox/Buttons/Release

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	action_button.pressed.connect(_on_action_pressed)
	release_button.pressed.connect(_on_release_pressed)
	SignalBus.positional_snapshot_changed.connect(_on_snapshot)
	SignalBus.combat_finished.connect(_on_combat_finished)

func _process(delta: float) -> void:
	if not active:
		return
	elapsed += delta
	var normalized := fmod(elapsed / attempt_duration, 1.0)
	var value := 50.0 if reduced_motion else (normalized * 200.0 if normalized <= 0.5 else (1.0 - normalized) * 200.0)
	timing_bar.value = clampf(value, 0.0, 100.0)
	if elapsed >= attempt_duration:
		_register_attempt(0.25)

func _on_snapshot(snapshot: Dictionary) -> void:
	if str(snapshot.get("phase", "")) != "submission":
		if active:
			_stop()
		return
	var pending: Dictionary = snapshot.get("pending_action", {})
	var next_attacker := str(pending.get("attacker_id", ""))
	if next_attacker == "" or (active and next_attacker == attacker_id):
		return
	_start(snapshot, next_attacker)

func _start(snapshot: Dictionary, next_attacker: String) -> void:
	active = true
	visible = true
	attacker_id = next_attacker
	defender_id = str(snapshot.get("pending_action", {}).get("defender_id", ""))
	player_is_attacker = attacker_id == str(CombatManager.player_id)
	elapsed = 0.0
	attempt_index = 0
	player_total = 0.0
	ai_total = 0.0
	title_label.text = "FINALIZAÇÃO ATIVA" if player_is_attacker else "DEFESA DE FINALIZAÇÃO"
	instruction_label.text = "Acione perto do centro. Técnica e leitura valem mais que velocidade."
	action_button.text = "APLICAR TÉCNICA" if player_is_attacker else "ESCAPAR"
	release_button.visible = player_is_attacker
	release_button.text = "SOLTAR"
	_update_progress()
	action_button.grab_focus()

func _on_action_pressed() -> void:
	if not active:
		return
	var quality := 1.0 - absf(float(timing_bar.value) - 50.0) / 50.0
	_register_attempt(clampf(quality, 0.0, 1.0))

func _register_attempt(quality: float) -> void:
	if not active:
		return
	player_total += quality
	var seed_text := "%s|%s|%s|%s" % [attacker_id, defender_id, attempt_index, CombatManager.positional_ruleset_id]
	var ai_quality := 0.42 + float(absi(hash(seed_text)) % 31) / 100.0
	ai_total += clampf(ai_quality, 0.0, 1.0)
	attempt_index += 1
	elapsed = 0.0
	_update_progress()
	if attempt_index >= attempts_required:
		_resolve()

func _update_progress() -> void:
	progress_label.text = "LEITURAS %d/%d · SUA PRECISÃO %d%%" % [attempt_index, attempts_required, int(round((player_total / maxf(1.0, float(maxi(1, attempt_index)))) * 100.0))]

func _resolve() -> void:
	var player_average := player_total / maxf(1.0, float(attempts_required))
	var ai_average := ai_total / maxf(1.0, float(attempts_required))
	active = false
	action_button.disabled = true
	if player_is_attacker:
		CombatManager.resolve_submission_v41(player_average, ai_average, false)
	else:
		CombatManager.resolve_submission_v41(ai_average, player_average, false)
	call_deferred("_stop")

func _on_release_pressed() -> void:
	if not active or not player_is_attacker:
		return
	active = false
	CombatManager.resolve_submission_v41(0.0, 0.0, true)
	_stop()

func _on_combat_finished(_result: Dictionary) -> void:
	_stop()

func _stop() -> void:
	active = false
	visible = false
	action_button.disabled = false
	elapsed = 0.0
