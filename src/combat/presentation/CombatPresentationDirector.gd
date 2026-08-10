extends Node
class_name CombatPresentationDirector

signal presentation_resolved(payload: Dictionary)

const CONFIG_PATH := "res://data/combat/combat_presentation_v01.json"

var config: Dictionary = {}
var gamefeel: GameFeelManager
var _last_state: String = ""


func _ready() -> void:
	_load_config()
	_connect_signals()


func configure(target_gamefeel: GameFeelManager) -> void:
	gamefeel = target_gamefeel
	if gamefeel != null:
		gamefeel.configure(
			DataRegistry.settings if has_node("/root/DataRegistry") else {},
			config.get("android_budgets", {})
		)
	if has_node("/root/AudioManager"):
		AudioManager.apply_settings(DataRegistry.settings if has_node("/root/DataRegistry") else {})


func resolve_for_result(result: Dictionary) -> Dictionary:
	var success := bool(result.get("success", false))
	var technique_id := str(result.get("technique_id", result.get("action_id", "")))
	var technique: Dictionary = DataRegistry.get_technique(technique_id) if has_node("/root/DataRegistry") else {}
	var family := str(result.get("family", technique.get("family", technique.get("familia", "geral"))))
	var presentation := _base_presentation(success)
	if success:
		presentation.merge(config.get("families", {}).get(family, {}), true)
		presentation.merge(config.get("techniques", {}).get(technique_id, {}), true)
	_merge_frame_data(presentation, result.get("frame_data", {}))
	_apply_budgets(presentation)
	return {
		"technique_id": technique_id,
		"family": family,
		"success": success,
		"actor_id": str(result.get("actor_id", "")),
		"presentation": presentation
	}


func _on_technique_resolved(result) -> void:
	if typeof(result) != TYPE_DICTIONARY:
		return
	var payload := resolve_for_result(result)
	var presentation: Dictionary = payload.get("presentation", {})
	var cue := str(presentation.get("audio_cue", "none"))
	if cue != "none" and has_node("/root/AudioManager"):
		AudioManager.play_sfx(cue)
	if gamefeel != null:
		gamefeel.apply_presentation(presentation, bool(payload.get("success", false)))
	presentation_resolved.emit(payload)
	if has_node("/root/SignalBus") and SignalBus.has_signal("combat_presentation_requested"):
		SignalBus.combat_presentation_requested.emit(payload.duplicate(true))


func _on_combat_state_changed(_old_state, new_state) -> void:
	var state := str(new_state)
	if state == _last_state:
		return
	_last_state = state
	var cue := str(config.get("state_audio", {}).get(state, ""))
	if cue != "" and has_node("/root/AudioManager"):
		AudioManager.play_sfx(cue, {"gain_db": -2.0})


func _on_card_selected(_card: Dictionary) -> void:
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("ui_confirm", {"gain_db": -2.0, "pitch_scale": 1.08})


func _base_presentation(success: bool) -> Dictionary:
	var key := "success" if success else "failure"
	return config.get("defaults", {}).get(key, {}).duplicate(true)


func _merge_frame_data(presentation: Dictionary, frame_data_value) -> void:
	if typeof(frame_data_value) != TYPE_DICTIONARY:
		return
	var frame_data: Dictionary = frame_data_value
	var deck_clash: Dictionary = frame_data.get("deck_clash", {})
	var outcome := str(deck_clash.get("outcome", ""))
	if outcome != "":
		presentation.merge(config.get("deck_clash", {}).get(outcome, {}), true)
	var authored: Dictionary = frame_data.get("presentation", {})
	for key in ["hit_stop_ms", "time_scale", "vfx", "audio_cue", "counter_window_ms"]:
		if authored.has(key) and authored[key] != "none":
			presentation[key] = authored[key]


func _apply_budgets(presentation: Dictionary) -> void:
	var budgets: Dictionary = config.get("android_budgets", {})
	presentation["hit_stop_ms"] = clampi(int(presentation.get("hit_stop_ms", 0)), 0, int(budgets.get("max_hit_stop_ms", 100)))
	presentation["shake_px"] = clampf(float(presentation.get("shake_px", 0.0)), 0.0, float(budgets.get("max_shake_px", 8.0)))
	presentation["shake_ms"] = clampi(int(presentation.get("shake_ms", 0)), 0, int(budgets.get("max_shake_ms", 140)))
	presentation["flash_alpha"] = clampf(float(presentation.get("flash_alpha", 0.0)), 0.0, float(budgets.get("max_flash_alpha", 0.16)))
	presentation["haptic_ms"] = clampi(int(presentation.get("haptic_ms", 0)), 0, int(budgets.get("max_haptic_ms", 45)))


func _load_config() -> void:
	config = {}
	if not FileAccess.file_exists(CONFIG_PATH):
		push_warning("[CombatPresentationDirector] Configuracao ausente")
		return
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		config = parsed


func _connect_signals() -> void:
	if not has_node("/root/SignalBus"):
		return
	if not SignalBus.technique_resolved.is_connected(_on_technique_resolved):
		SignalBus.technique_resolved.connect(_on_technique_resolved)
	if not SignalBus.combat_state_changed.is_connected(_on_combat_state_changed):
		SignalBus.combat_state_changed.connect(_on_combat_state_changed)
	if not SignalBus.combat_card_selected.is_connected(_on_card_selected):
		SignalBus.combat_card_selected.connect(_on_card_selected)
