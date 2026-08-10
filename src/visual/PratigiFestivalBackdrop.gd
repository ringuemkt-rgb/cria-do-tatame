class_name PratigiFestivalBackdrop
extends Control

@export_range(12, 64, 1) var crowd_count: int = 40
@export var reduced_motion: bool = false

var _time: float = 0.0
var _heat_level: float = 0.0
var _crowd_intensity: float = 0.65
var _tide_level: float = 0.5


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta * (0.25 if reduced_motion else 1.0)
	queue_redraw()


func set_heat_level(value: float) -> void:
	_heat_level = clampf(value, 0.0, 100.0)
	queue_redraw()


func set_crowd_intensity(value: float) -> void:
	_crowd_intensity = clampf(value, 0.0, 1.0)
	queue_redraw()


func set_tide_level(value: float) -> void:
	_tide_level = clampf(value, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return
	_draw_sky(w, h)
	_draw_ocean(w, h)
	_draw_beach(w, h)
	_draw_stage(w, h)
	_draw_slow_lights(w, h)
	_draw_crowd_ring(w, h)
	_draw_community_referee(w, h)
	_draw_fight_area(w, h)
	_draw_corners(w, h)
	_draw_authority_glow(w, h)


func _draw_sky(w: float, h: float) -> void:
	draw_rect(Rect2(0.0, 0.0, w, h), Color("081124"))
	for i in range(10):
		var t := float(i) / 9.0
		var color := Color(0.04 + t * 0.18, 0.07 + t * 0.08, 0.16 + t * 0.12, 1.0)
		draw_rect(Rect2(0.0, h * 0.06 * i, w, h * 0.065 + 1.0), color)
	var moon_pos := Vector2(w * 0.82, h * 0.15)
	draw_circle(moon_pos, 42.0, Color(0.95, 0.86, 0.64, 0.82))
	draw_circle(moon_pos + Vector2(13.0, -8.0), 38.0, Color("0d1830"))


func _draw_ocean(w: float, h: float) -> void:
	var ocean_top := h * lerpf(0.35, 0.40, _tide_level)
	draw_rect(Rect2(0.0, ocean_top, w, h * 0.25), Color("0b4966"))
	for i in range(9):
		var y := ocean_top + 10.0 + i * 13.0
		var drift := sin(_time * 0.55 + i * 0.8) * 18.0
		draw_line(Vector2(drift, y), Vector2(w + drift, y), Color(0.22, 0.78, 0.84, 0.18), 2.0)


func _draw_beach(w: float, h: float) -> void:
	var sand_top := h * lerpf(0.50, 0.57, _tide_level)
	var sand := PackedVector2Array([
		Vector2(0.0, sand_top),
		Vector2(w, sand_top - 18.0),
		Vector2(w, h),
		Vector2(0.0, h)
	])
	draw_colored_polygon(sand, Color("b88945"))
	for i in range(26):
		var x := fposmod(float(i * 97), w)
		var y := sand_top + 18.0 + fposmod(float(i * 41), maxf(1.0, h - sand_top - 18.0))
		draw_circle(Vector2(x, y), 1.4, Color(0.32, 0.20, 0.09, 0.38))


func _draw_stage(w: float, h: float) -> void:
	var stage_rect := Rect2(w * 0.04, h * 0.18, w * 0.24, h * 0.25)
	draw_rect(stage_rect, Color("151320"))
	draw_rect(Rect2(stage_rect.position + Vector2(10.0, 12.0), stage_rect.size - Vector2(20.0, 26.0)), Color("241b36"))
	for x_ratio in [0.065, 0.245]:
		draw_rect(Rect2(w * x_ratio, h * 0.20, 24.0, h * 0.19), Color("08080c"))
		for i in range(3):
			draw_circle(Vector2(w * x_ratio + 12.0, h * (0.235 + i * 0.052)), 7.0, Color("39264e"))
	var booth := Rect2(w * 0.105, h * 0.31, w * 0.11, h * 0.075)
	draw_rect(booth, Color("07090e"))
	draw_line(booth.position + Vector2(8.0, 10.0), booth.end - Vector2(8.0, 12.0), Color("22d3ee"), 3.0)
	var dj_center := Vector2(w * 0.16, h * 0.275)
	draw_circle(dj_center, 10.0, Color("6f4d37"))
	draw_rect(Rect2(dj_center + Vector2(-11.0, 9.0), Vector2(22.0, 30.0)), Color("191d2b"))


func _draw_slow_lights(w: float, h: float) -> void:
	var phase := sin(_time * 0.42) * 0.5 + 0.5
	var colors := [Color(0.12, 0.83, 0.92, 0.10), Color(0.95, 0.35, 0.56, 0.08), Color(0.98, 0.72, 0.18, 0.08)]
	for i in range(3):
		var origin := Vector2(w * (0.09 + i * 0.075), h * 0.19)
		var target_x := w * (0.38 + i * 0.20) + (phase - 0.5) * 80.0
		var beam := PackedVector2Array([
			origin,
			Vector2(target_x - 58.0, h * 0.74),
			Vector2(target_x + 58.0, h * 0.74)
		])
		draw_colored_polygon(beam, colors[i])


func _draw_crowd_ring(w: float, h: float) -> void:
	for i in range(crowd_count):
		var left_side := i < crowd_count / 2
		var local_index := i if left_side else i - crowd_count / 2
		var side_count := maxi(1, crowd_count / 2)
		var x_base := lerpf(w * 0.02, w * 0.31, float(local_index) / side_count) if left_side else lerpf(w * 0.69, w * 0.98, float(local_index) / side_count)
		var row := i % 3
		var bounce := sin(_time * (1.2 + (i % 5) * 0.08) + i) * (2.0 + 5.0 * _crowd_intensity)
		var y := h * 0.57 + row * 32.0 + bounce
		var skin := [Color("6f4d37"), Color("8e6248"), Color("4d352b"), Color("b27b57")][i % 4]
		var shirt := [Color("202938"), Color("6f2338"), Color("164b58"), Color("8a5b19")][i % 4]
		draw_circle(Vector2(x_base, y), 7.0, skin)
		draw_rect(Rect2(x_base - 8.0, y + 7.0, 16.0, 20.0), shirt)
		if i % 5 == 0:
			draw_line(Vector2(x_base + 6.0, y + 13.0), Vector2(x_base + 13.0, y - 6.0 - bounce * 0.2), skin, 3.0)


func _draw_community_referee(w: float, h: float) -> void:
	var center := Vector2(w * 0.5, h * 0.515)
	draw_circle(center, 8.5, Color("77503b"))
	draw_rect(Rect2(center + Vector2(-8.0, 8.0), Vector2(16.0, 36.0)), Color("e5e7eb"))
	draw_line(center + Vector2(-7.0, 19.0), center + Vector2(-23.0, 30.0), Color("77503b"), 4.0)
	draw_line(center + Vector2(7.0, 19.0), center + Vector2(23.0, 30.0), Color("77503b"), 4.0)


func _draw_fight_area(w: float, h: float) -> void:
	var center := Vector2(w * 0.5, h * 0.77)
	var rx := minf(w * 0.27, 345.0)
	var ry := minf(h * 0.15, 102.0)
	var ring := PackedVector2Array([
		Vector2(center.x, center.y - ry),
		Vector2(center.x + rx, center.y),
		Vector2(center.x, center.y + ry),
		Vector2(center.x - rx, center.y)
	])
	draw_colored_polygon(ring, Color(0.08, 0.10, 0.13, 0.62))
	draw_polyline(ring, Color("f5c542"), 5.0, true)
	draw_arc(center, 45.0, 0.0, TAU, 32, Color("22d3ee"), 3.0)


func _draw_corners(w: float, h: float) -> void:
	var y := h * 0.77
	draw_rect(Rect2(w * 0.245, y - 30.0, 10.0, 60.0), Color("2f7df6"))
	draw_circle(Vector2(w * 0.25, y - 36.0), 10.0, Color("2f7df6"))
	draw_rect(Rect2(w * 0.747, y - 30.0, 10.0, 60.0), Color("f5c542"))
	draw_circle(Vector2(w * 0.752, y - 36.0), 10.0, Color("f5c542"))


func _draw_authority_glow(w: float, h: float) -> void:
	if _heat_level < 65.0:
		return
	var alpha := clampf((_heat_level - 65.0) / 35.0, 0.0, 1.0) * 0.18
	var pulse := 0.55 + sin(_time * 1.8) * 0.15
	draw_rect(Rect2(0.0, 0.0, w * 0.13, h), Color(0.10, 0.32, 0.92, alpha * pulse))
	draw_rect(Rect2(w * 0.87, 0.0, w * 0.13, h), Color(0.92, 0.12, 0.15, alpha * pulse))
