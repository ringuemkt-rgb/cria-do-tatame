class_name AnimatedWaterLine
extends Control

signal tide_level_changed(level: float)

@export_range(30.0, 300.0, 0.1) var visual_cycle_seconds: float = 124.2
@export var reduced_motion: bool = false

var level: float = 0.5
var _elapsed: float = 0.0
var _last_emitted_level: float = -1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _process(delta: float) -> void:
	var motion_scale := 0.2 if reduced_motion else 1.0
	_elapsed += delta * motion_scale
	level = 0.5 + 0.5 * sin((_elapsed / visual_cycle_seconds) * TAU)
	if absf(level - _last_emitted_level) >= 0.01:
		_last_emitted_level = level
		tide_level_changed.emit(level)
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return
	var base_y := h * lerpf(0.505, 0.565, level)
	for band in range(4):
		var points := PackedVector2Array()
		var amplitude := 3.0 + band * 1.2
		var y_offset := band * 5.0
		for x in range(0, int(w) + 17, 16):
			var wave := sin(float(x) * 0.035 + _elapsed * (0.7 + band * 0.08)) * amplitude
			points.append(Vector2(float(x), base_y + y_offset + wave))
		if points.size() > 1:
			draw_polyline(points, Color(0.55, 0.95, 1.0, 0.55 - band * 0.09), 2.0)


func get_state_name() -> String:
	if level < 0.35:
		return "baixa"
	if level > 0.65:
		return "alta"
	var derivative := cos((_elapsed / visual_cycle_seconds) * TAU)
	return "subindo" if derivative > 0.0 else "descendo"
