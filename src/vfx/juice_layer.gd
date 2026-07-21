extends Node
signal shake_offset_updated(offset: Vector2)
signal combat_time_scale_changed(scale: float)
var trauma := 0.0
var combat_time_scale := 1.0
func hitstop(_ms: int) -> void: pass
func should_freeze_combat() -> bool: return false
func add_trauma(x: float) -> void: trauma = clampf(trauma + x, 0.0, 1.0)
func flash(_color: Color, _dur: float, _alpha: float) -> void: pass
func punch(node: Node) -> void:
	if node: node.create_tween().tween_property(node, "scale", node.scale * 1.06, 0.05).set_trans(Tween.TRANS_BACK)
func slow_mo(scale: float, _dur: float) -> void: combat_time_scale_changed.emit(scale)
func _process(delta: float) -> void:
	trauma = maxf(0.0, trauma - delta * 2.0)
	shake_offset_updated.emit(Vector2(randf_range(-1,1), randf_range(-1,1)) * trauma * trauma * 12.0)
