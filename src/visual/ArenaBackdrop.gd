extends Control
class_name ArenaBackdrop

@export var arena_id := "arena_do_dique"
var _time := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return
	if arena_id == "terreiro_da_luta":
		_draw_terreiro(w, h)
	else:
		_draw_dique(w, h)

func _draw_dique(w: float, h: float) -> void:
	draw_rect(Rect2(0, 0, w, h), Color("06080d"))
	for i in range(8):
		var band_y := h * float(i) / 8.0
		var shade := Color(0.025 + i * 0.006, 0.04 + i * 0.008, 0.075 + i * 0.014, 1.0)
		draw_rect(Rect2(0, band_y, w, h / 8.0 + 1.0), shade)
	var pulse := 0.55 + sin(_time * 1.7) * 0.08
	for x_ratio in [0.12, 0.32, 0.68, 0.88]:
		var top := Vector2(w * x_ratio, 0)
		var spread := 105.0 + sin(_time + x_ratio * 9.0) * 8.0
		draw_colored_polygon(PackedVector2Array([top, Vector2(w * x_ratio - spread, h * 0.64), Vector2(w * x_ratio + spread, h * 0.64)]), Color(0.25, 0.42, 0.64, 0.045 * pulse))
	_draw_crowd(w, h * 0.47)
	draw_rect(Rect2(0, h * 0.48, w, h * 0.06), Color("11161e"))
	for x in range(0, int(w) + 100, 180):
		draw_rect(Rect2(x + 14, h * 0.49, 138, h * 0.038), Color("1e3a5f"))
		draw_line(Vector2(x + 24, h * 0.52), Vector2(x + 140, h * 0.52), Color("b8860b"), 3.0)
	var floor := PackedVector2Array([Vector2(0, h * 0.54), Vector2(w, h * 0.54), Vector2(w, h), Vector2(0, h)])
	draw_colored_polygon(floor, Color("102846"))
	for i in range(7):
		var y := lerpf(h * 0.55, h, float(i) / 6.0)
		draw_line(Vector2(0, y), Vector2(w, y), Color(0.18, 0.34, 0.55, 0.35), 1.0)
	_draw_mat_mark(w, h)
	for i in range(5):
		var flash := fposmod(_time * (0.7 + i * 0.08) + i * 1.9, 5.0)
		if flash < 0.08:
			draw_circle(Vector2(w * (0.12 + i * 0.19), h * (0.24 + (i % 2) * 0.08)), 5.0, Color(0.8, 0.9, 1.0, 0.8))

func _draw_terreiro(w: float, h: float) -> void:
	draw_rect(Rect2(0, 0, w, h), Color("081014"))
	for i in range(8):
		var y := h * float(i) / 8.0
		var t := float(i) / 7.0
		draw_rect(Rect2(0, y, w, h / 8.0 + 1.0), Color(0.10 + t * 0.20, 0.13 + t * 0.10, 0.16 - t * 0.08, 1.0))
	draw_circle(Vector2(w * 0.78, h * 0.22), 54.0, Color(0.95, 0.56, 0.12, 0.45))
	for i in range(18):
		var x := w * float(i) / 17.0
		var sway := sin(_time * 0.8 + i) * 7.0
		draw_line(Vector2(x, h * 0.2), Vector2(x + sway, h * 0.58), Color("1b3519"), 14.0)
		draw_circle(Vector2(x + sway, h * 0.24), 38.0 + (i % 3) * 8.0, Color(0.08, 0.20, 0.08, 0.9))
	draw_rect(Rect2(0, h * 0.46, w, h * 0.14), Color("16384a"))
	for i in range(9):
		var glint_x := fposmod(_time * (22.0 + i) + i * 151.0, w)
		draw_line(Vector2(glint_x, h * (0.48 + (i % 4) * 0.024)), Vector2(glint_x + 36, h * (0.48 + (i % 4) * 0.024)), Color(0.82, 0.63, 0.22, 0.25), 2.0)
	draw_rect(Rect2(0, h * 0.58, w, h * 0.42), Color("17140f"))
	draw_colored_polygon(PackedVector2Array([Vector2(w * 0.08, h * 0.24), Vector2(w * 0.5, h * 0.10), Vector2(w * 0.92, h * 0.24), Vector2(w * 0.86, h * 0.30), Vector2(w * 0.14, h * 0.30)]), Color("17120e"))
	draw_rect(Rect2(w * 0.13, h * 0.28, w * 0.74, h * 0.30), Color(0.10, 0.075, 0.055, 0.88))
	draw_line(Vector2(w * 0.16, h * 0.52), Vector2(w * 0.84, h * 0.52), Color("b8860b"), 4.0)
	_draw_mat_mark(w, h)

func _draw_crowd(w: float, baseline: float) -> void:
	for row in range(4):
		for i in range(34):
			var x := (float(i) + 0.5 * (row % 2)) * w / 33.0
			var y := baseline - row * 36.0 - (i % 3) * 3.0
			var color := Color("202630") if (i + row) % 4 else Color("6a5120")
			draw_circle(Vector2(x, y), 7.0, color)
			draw_rect(Rect2(x - 8.0, y + 7.0, 16.0, 18.0), Color(color, 0.92))

func _draw_mat_mark(w: float, h: float) -> void:
	var center := Vector2(w * 0.5, h * 0.78)
	var rx := minf(w * 0.26, 330.0)
	var ry := minf(h * 0.16, 105.0)
	var diamond := PackedVector2Array([Vector2(center.x, center.y - ry), Vector2(center.x + rx, center.y), Vector2(center.x, center.y + ry), Vector2(center.x - rx, center.y)])
	draw_polyline(diamond, Color("b8860b"), 7.0, true)
	draw_circle(center, 44.0, Color(0.72, 0.53, 0.05, 0.12))
	draw_arc(center, 42.0, 0.0, TAU, 36, Color("f2c230"), 3.0)

