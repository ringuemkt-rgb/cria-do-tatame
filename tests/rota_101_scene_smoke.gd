extends SceneTree

const RotaScene = preload("res://scenes/world/Rota101Travel.tscn")

var failures: Array[String] = []
var checks := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene = RotaScene.instantiate()
	_check(scene != null, "ROTA 101 scene instantiates")
	if scene == null:
		_finish()
		return

	_check(scene.get_script() != null, "ROTA 101 scene has controller script")
	_check(scene.get_node_or_null("HUD") != null, "scene has HUD")
	_check(scene.get_node_or_null("HUD/Top/Route") != null, "scene has route label")
	_check(scene.get_node_or_null("HUD/Top/Speed") != null, "scene has speed label")
	_check(scene.get_node_or_null("HUD/Top/Condition") != null, "scene has condition label")
	_check(scene.get_node_or_null("HUD/Top/Progress") != null, "scene has route progress bar")
	_check(scene.get_node_or_null("HUD/Controls/Left") != null, "scene has left touch control")
	_check(scene.get_node_or_null("HUD/Controls/Right") != null, "scene has right touch control")
	_check(scene.get_node_or_null("HUD/Controls/Accelerate") != null, "scene has accelerate control")
	_check(scene.get_node_or_null("HUD/Controls/Brake") != null, "scene has brake control")
	_check(scene.get_node_or_null("HUD/Controls/Horn") != null, "scene has horn control")
	_check(scene.get_node_or_null("HUD/Controls/Pause") != null, "scene has pause control")
	_check(scene.get_node_or_null("HUD/Accessibility/AutoAccelerate") != null, "scene exposes auto accelerate")
	_check(scene.get_node_or_null("HUD/Accessibility/LaneAssist") != null, "scene exposes lane assist")
	_check(scene.get_node_or_null("HUD/Accessibility/ReducedShake") != null, "scene exposes reduced shake")
	_check(scene.get_node_or_null("HUD/ResultPanel") != null, "scene has terminal result panel")

	# Runtime travel mutation is already covered by the deterministic simulation and
	# two-phase travel smokes. This gate intentionally validates the packed scene
	# without entering an unbounded render/process loop in headless CI.
	scene.free()
	_finish()

func _finish() -> void:
	print("ROTA_101_SCENE_SMOKE checks=%d failures=%d" % [checks, failures.size()])
	for failure in failures:
		push_error(failure)
	quit(0 if failures.is_empty() else 1)

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
