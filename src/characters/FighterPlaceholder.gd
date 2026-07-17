extends Node2D
class_name FighterPlaceholder

const AnimationLibrary = preload("res://src/animation/CharacterAnimationLibrary.gd")

@export var fighter_id := "ruan_macacao"
@export var display_name := "Ruan Macacao"
@export var primary_color := Color(0.95, 0.95, 0.92)
@export var accent_color := Color(0.85, 0.65, 0.15)

var body: ColorRect
var head: ColorRect
var name_label: Label
var shadow: ColorRect
var animated_sprite: AnimatedSprite2D
var _base_position := Vector2.ZERO
var _base_scale := Vector2.ONE

func _ready() -> void:
	_base_position = position
	_base_scale = scale
	_build()
	play_action("idle")

func _build() -> void:
	shadow = ColorRect.new()
	shadow.color = Color(0, 0, 0, 0.35)
	shadow.size = Vector2(92, 12)
	shadow.position = Vector2(-46, 76)
	add_child(shadow)
	animated_sprite = AnimatedSprite2D.new()
	animated_sprite.name = "AnimatedSprite"
	animated_sprite.position = Vector2(0, 34)
	animated_sprite.scale = Vector2(1.55, 1.55)
	add_child(animated_sprite)
	if _load_clip("idle"):
		body = null
		head = null
	else:
		_build_fallback_body()
	name_label = Label.new()
	name_label.text = display_name
	name_label.position = Vector2(-92, 104)
	name_label.size = Vector2(184, 28)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", Color("f2f2f2"))
	name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	name_label.add_theme_constant_override("shadow_offset_x", 2)
	name_label.add_theme_constant_override("shadow_offset_y", 2)
	name_label.add_theme_font_size_override("font_size", 14)
	add_child(name_label)

func _build_fallback_body() -> void:
	body = ColorRect.new()
	body.color = primary_color
	body.size = Vector2(48, 86)
	body.position = Vector2(-24, -16)
	add_child(body)
	head = ColorRect.new()
	head.color = accent_color
	head.size = Vector2(36, 30)
	head.position = Vector2(-18, -52)
	add_child(head)

func _manifest_path(action: String) -> String:
	return "res://assets/sprites/%s/%s/manifest.json" % [fighter_id, action]

func _load_clip(action: String) -> bool:
	var path := _manifest_path(action)
	if not FileAccess.file_exists(path):
		return false
	var frames: SpriteFrames = AnimationLibrary.build_sprite_frames(path)
	if not frames.has_animation(action) or frames.get_frame_count(action) == 0:
		return false
	animated_sprite.sprite_frames = frames
	animated_sprite.animation = action
	animated_sprite.play()
	return true

func _clip_for_action(action_id: String) -> String:
	match action_id:
		"grip_de_ferro", "grip": return "grip"
		"baiana": return "stance"
		"encerramento_tecnico", "technical": return "idle"
		"defesa", "sprawl": return "defense"
		_: return action_id

func play_action(action_id: String) -> void:
	if animated_sprite != null and _load_clip(_clip_for_action(action_id)):
		if not _clip_for_action(action_id) in ["idle", "walk", "stance"]:
			_restore_idle_after_clip()
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	match action_id:
		"grip_de_ferro", "grip":
			tween.tween_property(self, "scale", Vector2(_base_scale.x * 1.06, _base_scale.y * 0.96), 0.08)
			tween.tween_property(self, "scale", _base_scale, 0.12)
		"baiana":
			tween.tween_property(self, "rotation_degrees", -10.0, 0.08)
			tween.tween_property(self, "position:x", position.x + 34.0, 0.12)
			tween.tween_property(self, "rotation_degrees", 0.0, 0.10)
		"corte_joelho":
			tween.tween_property(self, "position:y", position.y + 10.0, 0.08)
			tween.tween_property(self, "position:x", position.x + 18.0, 0.10)
			tween.tween_property(self, "position:y", position.y, 0.08)
		"sprawl":
			tween.tween_property(self, "scale", Vector2(_base_scale.x * 1.15, _base_scale.y * 0.75), 0.08)
			tween.tween_property(self, "scale", _base_scale, 0.14)
		"encerramento_tecnico", "technical":
			tween.tween_property(self, "modulate", Color(1.0, 0.85, 0.45), 0.08)
			tween.tween_property(self, "modulate", Color.WHITE, 0.18)
		_:
			tween.tween_property(self, "position:y", position.y - 3.0, 0.18)
			tween.tween_property(self, "position:y", position.y, 0.18)

func _restore_idle_after_clip() -> void:
	var clip := animated_sprite.animation
	var duration := 0.85
	if animated_sprite.sprite_frames != null:
		var fps := animated_sprite.sprite_frames.get_animation_speed(clip)
		var count := animated_sprite.sprite_frames.get_frame_count(clip)
		if fps > 0.0:
			duration = maxf(0.25, float(count) / fps)
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(animated_sprite):
		_load_clip("idle")
	position = _base_position
	rotation = 0.0
	scale = _base_scale
