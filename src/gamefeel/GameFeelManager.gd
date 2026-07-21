extends Node
class_name GameFeelManager

var _presentation_root: Control
var _hitstop_generation: int = 0
var _shake_tween: Tween

func setup(presentation_root: Control) -> void:
	_presentation_root = presentation_root

func apply_for_technique(technique_id: String, success: bool) -> void:
	if not success:
		return
	match technique_id:
		"baiana", "raspagem_tesoura", "raspagem_borboleta":
			_hitstop(0.06)
			_screen_shake(8.0, 0.10)
		"corte_joelho", "passagem", "control_start":
			_hitstop(0.04)
			_screen_shake(5.0, 0.08)
		"sprawl", "defesa", "defesa_perfeita":
			_hitstop(0.035)
			_screen_shake(4.0, 0.07)
		"encerramento_tecnico", "chave_braco", "estrangulamento_costas":
			_hitstop(0.12)
			_screen_shake(12.0, 0.18)
		_:
			_hitstop(0.025)

func _hitstop(duration: float) -> void:
	_hitstop_generation += 1
	var generation := _hitstop_generation
	Engine.time_scale = 0.08
	await get_tree().create_timer(duration, true, false, true).timeout
	if generation == _hitstop_generation:
		Engine.time_scale = 1.0

func _screen_shake(amount: float, duration: float) -> void:
	if _presentation_root != null and is_instance_valid(_presentation_root):
		if _shake_tween != null and _shake_tween.is_valid():
			_shake_tween.kill()
		_presentation_root.position = Vector2.ZERO
		var step: float = duration / 5.0
		_shake_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_shake_tween.tween_property(_presentation_root, "position", Vector2(amount, -amount * 0.45), step)
		_shake_tween.tween_property(_presentation_root, "position", Vector2(-amount * 0.75, amount * 0.35), step)
		_shake_tween.tween_property(_presentation_root, "position", Vector2(amount * 0.45, amount * 0.20), step)
		_shake_tween.tween_property(_presentation_root, "position", Vector2(-amount * 0.20, -amount * 0.10), step)
		_shake_tween.tween_property(_presentation_root, "position", Vector2.ZERO, step)
		return
	var viewport := get_viewport()
	if viewport == null:
		return
	var camera := viewport.get_camera_2d()
	if camera == null:
		return
	var original := camera.offset
	var elapsed := 0.0
	while elapsed < duration:
		camera.offset = original + Vector2(randf_range(-amount, amount), randf_range(-amount, amount))
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	camera.offset = original

func _exit_tree() -> void:
	_hitstop_generation += 1
	Engine.time_scale = 1.0
	if _presentation_root != null and is_instance_valid(_presentation_root):
		_presentation_root.position = Vector2.ZERO
