extends Node
var buffer: Array[int] = []
const ACTION_TO_DIR := {"ui_left": 0, "ui_right": 1, "ui_up": 2, "ui_down": 3}
func _process(_delta: float) -> void:
	for action in ACTION_TO_DIR:
		if Input.is_action_just_pressed(action):
			buffer.append(ACTION_TO_DIR[action])
			if buffer.size() > 6: buffer.pop_front()
func consume_direction() -> int: return -1 if buffer.is_empty() else buffer.pop_front()
func peek_direction() -> int: return -1 if buffer.is_empty() else buffer[0]
func clear() -> void: buffer.clear()
