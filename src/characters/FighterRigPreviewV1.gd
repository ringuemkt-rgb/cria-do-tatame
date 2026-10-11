extends Node2D
class_name FighterRigPreviewV1

## Procedural, license-independent gameplay preview. NOT a final sprite.
## Local coordinates share a foot/mat baseline at y=72 with FighterPlaceholder.
## No collision, score, result or combat state is owned by this view.

@export var gi_color := Color("e9e2d2")
@export var skin_color := Color("a96e48")
@export var trim_color := Color("23282c")
@export var belt_color := Color("ece9d9")
var pose_id := "stance"
var _previous_points: Dictionary = {}
var _blend_elapsed := 1.0
const POSE_BLEND_SECONDS := 0.085

func _ready() -> void:
	set_process(false)

func _process(delta: float) -> void:
	_blend_elapsed = minf(POSE_BLEND_SECONDS, _blend_elapsed + maxf(0.0, delta))
	queue_redraw()
	if _blend_elapsed >= POSE_BLEND_SECONDS:
		set_process(false)

func set_visual_pose(value: String) -> void:
	var normalized := value if value in ["idle", "stance", "guard", "grip", "shot", "sprawl", "top", "bottom", "pass", "mount", "submission", "defense", "impact", "victory"] else "stance"
	if normalized == pose_id:
		return
	_previous_points = _blended_points()
	pose_id = normalized
	_blend_elapsed = 0.0
	set_process(true)
	queue_redraw()

func _points_for_pose(target_pose: String) -> Dictionary:
	var p := {
		"head": Vector2(0, -36),
		"ls": Vector2(-19, -12), "rs": Vector2(19, -12),
		"le": Vector2(-30, 10), "re": Vector2(32, 11),
		"lh": Vector2(-22, 25), "rh": Vector2(31, 22),
		"hip": Vector2(0, 35),
		"lk": Vector2(-18, 51), "rk": Vector2(18, 50),
		"lf": Vector2(-28, 72), "rf": Vector2(31, 72)
	}
	match target_pose:
		"idle":
			p["le"] = Vector2(-22, 20)
			p["re"] = Vector2(23, 18)
			p["lh"] = Vector2(-19, 35)
			p["rh"] = Vector2(23, 34)
		"guard", "defense":
			p["le"] = Vector2(-28, -9)
			p["re"] = Vector2(29, -10)
			p["lh"] = Vector2(-9, -27)
			p["rh"] = Vector2(12, -25)
		"grip":
			p["le"] = Vector2(-6, -9)
			p["re"] = Vector2(35, -12)
			p["lh"] = Vector2(24, -13)
			p["rh"] = Vector2(56, -24)
		"shot":
			p["head"] = Vector2(20, 8)
			p["ls"] = Vector2(7, 25)
			p["rs"] = Vector2(33, 23)
			p["le"] = Vector2(35, 27)
			p["re"] = Vector2(49, 38)
			p["lh"] = Vector2(56, 35)
			p["rh"] = Vector2(68, 48)
			p["hip"] = Vector2(-16, 49)
			p["lk"] = Vector2(-37, 54)
			p["rk"] = Vector2(1, 58)
			p["lf"] = Vector2(-57, 72)
			p["rf"] = Vector2(15, 72)
		"sprawl":
			p["head"] = Vector2(38, 22)
			p["ls"] = Vector2(15, 39)
			p["rs"] = Vector2(32, 40)
			p["le"] = Vector2(37, 47)
			p["re"] = Vector2(51, 48)
			p["lh"] = Vector2(43, 65)
			p["rh"] = Vector2(63, 65)
			p["hip"] = Vector2(-24, 49)
			p["lk"] = Vector2(-51, 57)
			p["rk"] = Vector2(-25, 66)
			p["lf"] = Vector2(-78, 72)
			p["rf"] = Vector2(-43, 72)
		"top", "pass", "mount":
			p["head"] = Vector2(15, 5 if pose_id == "top" else -8)
			p["ls"] = Vector2(-4, 15)
			p["rs"] = Vector2(29, 11)
			p["le"] = Vector2(18, 37)
			p["re"] = Vector2(46, 34)
			p["lh"] = Vector2(32, 59)
			p["rh"] = Vector2(61, 59)
			p["hip"] = Vector2(-6, 44)
			p["lk"] = Vector2(-25, 56)
			p["rk"] = Vector2(14, 56)
			p["lf"] = Vector2(-39, 72)
			p["rf"] = Vector2(19, 72)
		"bottom", "impact":
			p["head"] = Vector2(-44, 48)
			p["ls"] = Vector2(-26, 46)
			p["rs"] = Vector2(-22, 64)
			p["le"] = Vector2(-52, 31)
			p["re"] = Vector2(-9, 43)
			p["lh"] = Vector2(-65, 39)
			p["rh"] = Vector2(14, 37)
			p["hip"] = Vector2(9, 51)
			p["lk"] = Vector2(35, 30)
			p["rk"] = Vector2(37, 56)
			p["lf"] = Vector2(52, 38)
			p["rf"] = Vector2(70, 71)
		"submission":
			p["head"] = Vector2(12, 3)
			p["ls"] = Vector2(-6, 12)
			p["rs"] = Vector2(20, 18)
			p["le"] = Vector2(32, 33)
			p["re"] = Vector2(36, 28)
			p["lh"] = Vector2(52, 49)
			p["rh"] = Vector2(58, 43)
			p["hip"] = Vector2(-9, 45)
			p["lk"] = Vector2(-23, 58)
			p["rk"] = Vector2(15, 58)
			p["lf"] = Vector2(-40, 72)
			p["rf"] = Vector2(30, 72)
		"victory":
			p["le"] = Vector2(-33, -44)
			p["re"] = Vector2(33, -44)
			p["lh"] = Vector2(-45, -75)
			p["rh"] = Vector2(47, -75)
	return p

func _blended_points() -> Dictionary:
	var target := _points_for_pose(pose_id)
	if _previous_points.is_empty() or _blend_elapsed >= POSE_BLEND_SECONDS:
		return target
	var alpha := smoothstep(0.0, POSE_BLEND_SECONDS, _blend_elapsed)
	var intermediate := {}
	for key in target.keys():
		intermediate[key] = _previous_points.get(key, target[key]).lerp(target[key], alpha)
	return intermediate

func _draw() -> void:
	var p: Dictionary = _blended_points()
	var outline := Color("18191e")
	var gi_shade := gi_color.darkened(0.25)
	var skin_shade := skin_color.darkened(0.27)
	var hip: Vector2 = p["hip"]
	var left_shoulder: Vector2 = p["ls"]
	var right_shoulder: Vector2 = p["rs"]
	var head: Vector2 = p["head"]
	# Feet shadow belongs to the view, independent of camera or physics.
	draw_ellipse_shadow()
	for side in ["l", "r"]:
		var knee: Vector2 = p[side + "k"]
		var foot: Vector2 = p[side + "f"]
		_draw_segment(hip, knee, outline, gi_shade, 20.0)
		_draw_segment(knee, foot, outline, gi_color, 15.0)
		_draw_segment(foot, foot + Vector2(10, 0), outline, skin_color, 9.0)
	var shoulders := (left_shoulder + right_shoulder) * 0.5
	var shirt := PackedVector2Array([
		left_shoulder + Vector2(-7, -4), right_shoulder + Vector2(7, -4),
		hip + Vector2(17, 4), hip + Vector2(-17, 4)
	])
	draw_colored_polygon(shirt, outline)
	var inset := PackedVector2Array([
		left_shoulder, right_shoulder, hip + Vector2(12, -1), hip + Vector2(-12, -1)
	])
	draw_colored_polygon(inset, gi_color)
	draw_line(shoulders, hip + Vector2(4, -4), gi_shade, 5.0, false)
	# Belt/costume stays with the fighter in all procedural poses.
	draw_line(hip + Vector2(-16, -10), hip + Vector2(16, -10), belt_color, 5.0, false)
	draw_rect(Rect2(hip + Vector2(-3, -13), Vector2(6, 6)), trim_color)
	for side in ["l", "r"]:
		var shoulder: Vector2 = p[side + "s"]
		var elbow: Vector2 = p[side + "e"]
		var hand: Vector2 = p[side + "h"]
		_draw_segment(shoulder, elbow, outline, gi_shade, 16.0)
		_draw_segment(elbow, hand, outline, gi_color, 13.0)
		draw_circle(hand, 6.0, skin_shade)
		draw_circle(hand + Vector2(-1, -1), 4.0, skin_color)
	draw_circle(head + Vector2(0, -4), 16.0, outline)
	draw_circle(head + Vector2(0, -5), 13.0, Color("14171c"))
	draw_circle(head + Vector2(0, 2), 11.0, skin_color)
	draw_line(head + Vector2(1, 3), head + Vector2(8, 3), skin_shade, 2.0, false)
	draw_line(head + Vector2(-2, 11), head + Vector2(7, 10), skin_shade, 2.0, false)
	draw_circle(shoulders.lerp(hip, 0.35) + Vector2(8, -1), 4.0, trim_color)

func _draw_segment(start: Vector2, finish: Vector2, border: Color, inside: Color, width: float) -> void:
	draw_line(start, finish, border, width + 3.0, false)
	draw_line(start, finish, inside, width, false)

func draw_ellipse_shadow() -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(-56, 77), Vector2(-31, 71), Vector2(30, 71),
		Vector2(59, 77), Vector2(28, 81), Vector2(-35, 81)
	]), Color(0, 0, 0, 0.22))
