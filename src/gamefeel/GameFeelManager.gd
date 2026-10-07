extends Node
class_name GameFeelManager

const PROFILE_PATH := "res://data/combat/combat_feedback_v1.json"
const SETTINGS_PATH := "res://data/settings.json"

var profile_data: Dictionary = {}
var settings_data: Dictionary = {}
var _effect_serial := 0

func _ready() -> void:
	reload_profiles()

func reload_profiles() -> void:
	profile_data = _load_json(PROFILE_PATH)
	settings_data = _load_json(SETTINGS_PATH)

func apply_for_technique(technique_id: String, success: bool) -> void:
	if not success:
		return
	if profile_data.is_empty():
		reload_profiles()
	var profiles: Dictionary = profile_data.get("profiles", {})
	var feedback: Dictionary = profiles.get(technique_id, profile_data.get("default", {})).duplicate(true)
	var accessibility: Dictionary = profile_data.get("accessibility", {})
	var reduced_motion := bool(settings_data.get("accessibility", {}).get("reduced_motion", false))
	var screen_shake_enabled := bool(settings_data.get("video", {}).get("screen_shake", true))
	var hitstop_ms := float(feedback.get("hitstop_ms", 0.0))
	var shake_px := float(feedback.get("shake_px", 0.0))
	var shake_ms := float(feedback.get("shake_ms", 0.0))

	if reduced_motion:
		hitstop_ms *= clampf(float(accessibility.get("reduced_motion_hitstop_multiplier", 0.25)), 0.0, 1.0)
		if bool(accessibility.get("reduced_motion_disables_shake", true)):
			shake_px = 0.0
			shake_ms = 0.0
	if bool(accessibility.get("screen_shake_setting_required", true)) and not screen_shake_enabled:
		shake_px = 0.0
		shake_ms = 0.0

	_effect_serial += 1
	var serial := _effect_serial
	if hitstop_ms > 0.0:
		_hitstop(hitstop_ms / 1000.0, serial)
	if shake_px > 0.0 and shake_ms > 0.0:
		_screen_shake(shake_px, shake_ms / 1000.0, serial)

func feedback_for(technique_id: String) -> Dictionary:
	if profile_data.is_empty():
		reload_profiles()
	return profile_data.get("profiles", {}).get(
		technique_id,
		profile_data.get("default", {})
	).duplicate(true)

func _hitstop(duration: float, serial: int) -> void:
	var safe_duration := clampf(duration, 0.0, 0.15)
	if safe_duration <= 0.0:
		return
	Engine.time_scale = 0.08
	await get_tree().create_timer(safe_duration, true, false, true).timeout
	if serial == _effect_serial:
		Engine.time_scale = 1.0

func _screen_shake(amount: float, duration: float, serial: int) -> void:
	var viewport := get_viewport()
	if viewport == null:
		return
	var camera := viewport.get_camera_2d()
	if camera == null:
		return
	var original := camera.offset
	var elapsed := 0.0
	var frame := 0
	var safe_duration := clampf(duration, 0.0, 0.2)
	while elapsed < safe_duration and serial == _effect_serial:
		var progress := elapsed / maxf(safe_duration, 0.001)
		var falloff := 1.0 - progress
		var phase := float(frame)
		var x := sin(phase * 2.173) * amount * falloff
		var y := cos(phase * 1.619) * amount * 0.65 * falloff
		camera.offset = original + Vector2(x, y)
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		frame += 1
	if is_instance_valid(camera):
		camera.offset = original

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}
