extends Control

# Authoring preview only. No combat rules, save writes, animation or promotion.
var source_texture: Texture2D
var source_region := Rect2()
var body_height := 72.0
var show_guides := true

func set_source(texture: Texture2D, region: Rect2, height: float) -> void:
	source_texture = texture
	source_region = region
	body_height = height
	queue_redraw()

func get_normalized_rect() -> Rect2:
	if source_region.size.x <= 0.0 or source_region.size.y <= 0.0:
		return Rect2()
	var fitted := source_region.size * minf(body_height / source_region.size.y, 104.0 / source_region.size.x)
	return Rect2(Vector2(64.0 - fitted.x * 0.5, 96.0 - fitted.y), fitted)

func _draw() -> void:
	var zoom := maxf(1.0, floorf(minf(size.x, size.y) / 128.0))
	var origin := (size - Vector2(128.0, 128.0) * zoom) * 0.5
	draw_set_transform(origin, 0.0, Vector2(zoom, zoom))
	for row in range(16):
		for col in range(16):
			var color := Color("22272e") if (row + col) % 2 == 0 else Color("2b323a")
			draw_rect(Rect2(col * 8, row * 8, 8, 8), color)
	if source_texture != null:
		draw_texture_rect_region(source_texture, get_normalized_rect(), source_region)
	if show_guides:
		draw_rect(Rect2(0, 0, 128, 128), Color("c9971c"), false, 1.0)
		draw_line(Vector2(2, 96), Vector2(126, 96), Color(0.4, 0.8, 1.0, 0.8), 1.0)
		draw_line(Vector2(64, 91), Vector2(64, 101), Color("ede6d6"), 1.0)
		draw_line(Vector2(59, 96), Vector2(69, 96), Color("ede6d6"), 1.0)
	draw_set_transform(Vector2.ZERO)
