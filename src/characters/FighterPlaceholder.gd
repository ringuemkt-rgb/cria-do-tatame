extends Node2D
class_name FighterPlaceholder

@export var fighter_id := "ruan_macacao"
@export var display_name := "Ruan Macacao"
@export var primary_color := Color(0.95, 0.95, 0.92)
@export var accent_color := Color(0.85, 0.65, 0.15)

var body: ColorRect
var head: ColorRect
var name_label: Label
var shadow: ColorRect

func _ready() -> void:
	_build()
	play_action("idle")

func _build() -> void:
	shadow = ColorRect.new()
	shadow.color = Color(0, 0, 0, 0.35)
	shadow.size = Vector2(92, 12)
	shadow.position = Vector2(-46, 76)
	add_child(shadow)
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
	name_label = Label.new()
	name_label.text = display_name
	name_label.position = Vector2(-70, 94)
	name_label.size = Vector2(140, 28)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(name_label)

func play_action(action_id: String) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	match action_id:
		"grip_de_ferro", "grip":
			tween.tween_property(self, "scale", Vector2(1.06, 0.96), 0.08)
			tween.tween_property(self, "scale", Vector2.ONE, 0.12)
		"baiana":
			tween.tween_property(self, "rotation_degrees", -10.0, 0.08)
			tween.tween_property(self, "position:x", position.x + 34.0, 0.12)
			tween.tween_property(self, "rotation_degrees", 0.0, 0.10)
		"corte_joelho":
			tween.tween_property(self, "position:y", position.y + 10.0, 0.08)
			tween.tween_property(self, "position:x", position.x + 18.0, 0.10)
			tween.tween_property(self, "position:y", position.y, 0.08)
		"sprawl":
			tween.tween_property(self, "scale", Vector2(1.15, 0.75), 0.08)
			tween.tween_property(self, "scale", Vector2.ONE, 0.14)
		"encerramento_tecnico", "technical":
			tween.tween_property(self, "modulate", Color(1.0, 0.85, 0.45), 0.08)
			tween.tween_property(self, "modulate", Color.WHITE, 0.18)
		_:
			tween.tween_property(self, "position:y", position.y - 3.0, 0.18)
			tween.tween_property(self, "position:y", position.y, 0.18)
