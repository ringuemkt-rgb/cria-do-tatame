extends Node
class_name GameFeelManager

func apply_for_technique(technique_id: String, success: bool) -> void:
	if not success:
		return
	match technique_id:
		"baiana":
			_hitstop(0.06)
			_screen_shake(8.0, 0.10)
		"corte_joelho":
			_hitstop(0.04)
			_screen_shake(5.0, 0.08)
		"encerramento_tecnico":
			_hitstop(0.12)
			_screen_shake(12.0, 0.18)
		_:
			_hitstop(0.03)

func _hitstop(duration: float) -> void:
	Engine.time_scale = 0.08
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

func _screen_shake(amount: float, duration: float) -> void:
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
