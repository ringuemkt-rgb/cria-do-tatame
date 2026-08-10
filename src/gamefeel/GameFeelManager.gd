extends Node
class_name GameFeelManager

const CombatImpactOverlayScript = preload("res://src/gamefeel/CombatImpactOverlay.gd")

var budgets: Dictionary = {}
var accessibility: Dictionary = {}
var overlay: CombatImpactOverlay
var _hitstop_ticket: int = 0
var _shake_ticket: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_overlay()


func configure(settings: Dictionary, presentation_budgets: Dictionary = {}) -> void:
	budgets = presentation_budgets.duplicate(true)
	var accessibility_settings: Dictionary = settings.get("accessibility", {})
	var video_settings: Dictionary = settings.get("video", {})
	accessibility = {
		"reduced_motion": bool(accessibility_settings.get("reduced_motion", false)),
		"screen_shake": bool(video_settings.get("screen_shake", true)),
		"haptics": bool(accessibility_settings.get("haptics", true))
	}
	_ensure_overlay()
	overlay.configure(budgets, bool(accessibility.get("reduced_motion", false)))


func apply_presentation(presentation: Dictionary, success: bool = true, screen_position: Vector2 = Vector2(-1.0, -1.0)) -> void:
	if presentation.is_empty():
		return
	var reduced_motion := bool(accessibility.get("reduced_motion", false))
	var motion_scale := 0.25 if reduced_motion else 1.0
	var max_hit_stop := int(budgets.get("max_hit_stop_ms", 100))
	var hit_stop_ms := mini(int(presentation.get("hit_stop_ms", 0)), max_hit_stop)
	if hit_stop_ms > 0:
		_hitstop(float(hit_stop_ms) / 1000.0 * motion_scale, float(presentation.get("time_scale", 0.3)))

	var shake_enabled := bool(accessibility.get("screen_shake", true)) and not reduced_motion
	var shake_px := minf(float(presentation.get("shake_px", 0.0)), float(budgets.get("max_shake_px", 8.0)))
	var shake_ms := mini(int(presentation.get("shake_ms", 0)), int(budgets.get("max_shake_ms", 140)))
	if shake_enabled and shake_px > 0.0 and shake_ms > 0:
		_screen_shake(shake_px, float(shake_ms) / 1000.0)

	_ensure_overlay()
	var color := _color_from(presentation.get("vfx_color", "ffffff"))
	var max_flash := float(budgets.get("max_flash_alpha", 0.16))
	var flash_alpha := minf(float(presentation.get("flash_alpha", 0.0)), max_flash)
	if not reduced_motion and flash_alpha > 0.0:
		overlay.flash(color, flash_alpha)
	overlay.spawn_impact(
		str(presentation.get("vfx", "none")),
		color,
		1.0 if success else 0.65,
		screen_position
	)

	if bool(accessibility.get("haptics", true)):
		var max_haptic := int(budgets.get("max_haptic_ms", 45))
		var haptic_ms := mini(int(presentation.get("haptic_ms", 0)), max_haptic)
		if haptic_ms > 0:
			Input.vibrate_handheld(haptic_ms, clampf(float(presentation.get("haptic_amplitude", 0.25)), 0.0, 1.0))


func apply_for_technique(technique_id: String, success: bool) -> void:
	# Compatibilidade com cenas antigas. Novas cenas usam CombatPresentationDirector.
	var fallback := {
		"hit_stop_ms": 30 if success else 0,
		"time_scale": 0.3,
		"shake_px": 0.0,
		"shake_ms": 0,
		"vfx": "impact_control" if success else "defense_read",
		"vfx_color": "f2c230" if success else "a8b7c9",
		"haptic_ms": 12 if success else 6
	}
	match technique_id:
		"baiana":
			fallback.merge({"hit_stop_ms": 60, "shake_px": 8.0, "shake_ms": 100, "vfx": "mat_impact"}, true)
		"corte_joelho":
			fallback.merge({"hit_stop_ms": 40, "shake_px": 5.0, "shake_ms": 80, "vfx": "pass_line"}, true)
		"encerramento_tecnico":
			fallback.merge({"hit_stop_ms": 100, "shake_px": 8.0, "shake_ms": 140, "vfx": "technical_finish"}, true)
	apply_presentation(fallback, success)


func _ensure_overlay() -> void:
	if overlay != null and is_instance_valid(overlay):
		return
	overlay = CombatImpactOverlayScript.new()
	overlay.name = "CombatImpactOverlay"
	add_child(overlay)


func _hitstop(duration: float, target_scale: float) -> void:
	if duration <= 0.0:
		return
	_hitstop_ticket += 1
	var ticket := _hitstop_ticket
	Engine.time_scale = clampf(target_scale, 0.05, 1.0)
	await get_tree().create_timer(duration, true, false, true).timeout
	if ticket == _hitstop_ticket:
		Engine.time_scale = 1.0


func _screen_shake(amount: float, duration: float) -> void:
	var viewport := get_viewport()
	if viewport == null:
		return
	var camera := viewport.get_camera_2d()
	if camera == null:
		return
	_shake_ticket += 1
	var ticket := _shake_ticket
	var original := camera.offset
	var started_at := Time.get_ticks_msec()
	while ticket == _shake_ticket and is_instance_valid(camera) and float(Time.get_ticks_msec() - started_at) / 1000.0 < duration:
		camera.offset = original + Vector2(randf_range(-amount, amount), randf_range(-amount, amount))
		await get_tree().process_frame
	if ticket == _shake_ticket and is_instance_valid(camera):
		camera.offset = original


func _color_from(value) -> Color:
	var text := str(value).strip_edges().trim_prefix("#")
	if text.length() not in [6, 8]:
		return Color.WHITE
	return Color("#" + text)


func _exit_tree() -> void:
	_hitstop_ticket += 1
	_shake_ticket += 1
	Engine.time_scale = 1.0
