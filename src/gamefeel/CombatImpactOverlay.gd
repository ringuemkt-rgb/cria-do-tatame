extends Control
class_name CombatImpactOverlay

var max_concurrent_impacts: int = 5
var reduced_motion: bool = false
var _impacts: Array[Dictionary] = []
var _flash_color: Color = Color.TRANSPARENT
var _flash_alpha: float = 0.0
var _flash_duration: float = 0.08
var _flash_elapsed: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if get_parent() is Control:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	else:
		_sync_to_viewport()
		var viewport := get_viewport()
		if viewport != null and not viewport.size_changed.is_connected(_sync_to_viewport):
			viewport.size_changed.connect(_sync_to_viewport)
	z_index = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)


func _sync_to_viewport() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size


func configure(budgets: Dictionary, use_reduced_motion: bool) -> void:
	max_concurrent_impacts = maxi(1, int(budgets.get("max_concurrent_impacts", 5)))
	reduced_motion = use_reduced_motion


func flash(color: Color, alpha: float, duration: float = 0.08) -> void:
	if reduced_motion or alpha <= 0.0:
		return
	_flash_color = color
	_flash_alpha = clampf(alpha, 0.0, 1.0)
	_flash_duration = maxf(0.02, duration)
	_flash_elapsed = 0.0
	set_process(true)
	queue_redraw()


func spawn_impact(
	vfx_id: String,
	color: Color,
	intensity: float = 1.0,
	screen_position: Vector2 = Vector2(-1.0, -1.0)
) -> void:
	if vfx_id == "" or vfx_id == "none":
		return
	while _impacts.size() >= max_concurrent_impacts:
		_impacts.pop_front()
	_impacts.append({
		"id": vfx_id,
		"color": color,
		"intensity": clampf(intensity, 0.1, 1.5),
		"position": screen_position,
		"elapsed": 0.0,
		"duration": 0.16 if reduced_motion else 0.32
	})
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	if _flash_alpha > 0.0:
		_flash_elapsed += delta
		if _flash_elapsed >= _flash_duration:
			_flash_alpha = 0.0
	var alive: Array[Dictionary] = []
	for impact_value in _impacts:
		var impact: Dictionary = impact_value
		impact["elapsed"] = float(impact.get("elapsed", 0.0)) + delta
		if float(impact["elapsed"]) < float(impact.get("duration", 0.32)):
			alive.append(impact)
	_impacts = alive
	queue_redraw()
	if _flash_alpha <= 0.0 and _impacts.is_empty():
		set_process(false)


func _draw() -> void:
	if _flash_alpha > 0.0:
		var flash_progress := clampf(_flash_elapsed / maxf(_flash_duration, 0.001), 0.0, 1.0)
		var flash := _flash_color
		flash.a = _flash_alpha * (1.0 - flash_progress)
		draw_rect(Rect2(Vector2.ZERO, size), flash)
	for impact_value in _impacts:
		_draw_impact(impact_value)


func _draw_impact(impact: Dictionary) -> void:
	var duration := maxf(float(impact.get("duration", 0.32)), 0.001)
	var progress := clampf(float(impact.get("elapsed", 0.0)) / duration, 0.0, 1.0)
	var center: Vector2 = impact.get("position", Vector2(-1.0, -1.0))
	if center.x < 0.0 or center.y < 0.0:
		center = size * Vector2(0.5, 0.46)
	var intensity := float(impact.get("intensity", 1.0))
	var color: Color = impact.get("color", Color.WHITE)
	color.a = (1.0 - progress) * 0.82
	var radius := lerpf(12.0, 72.0 * intensity, progress)
	var width := maxf(1.0, 5.0 * (1.0 - progress) * intensity)
	draw_arc(center, radius, 0.0, TAU, 36, color, width, true)
	if reduced_motion:
		return
	var diagonal := radius * 0.72
	for direction_value in [Vector2(1, 0), Vector2(0, 1), Vector2(0.707, 0.707), Vector2(0.707, -0.707)]:
		var direction: Vector2 = direction_value
		var inner: Vector2 = center + direction * diagonal * 0.72
		var outer: Vector2 = center + direction * diagonal
		draw_line(inner, outer, color, width, true)
