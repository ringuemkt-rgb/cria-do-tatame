extends Node
const Bridge = preload("res://src/audio/combat_audio_bridge.gd")
var audio := Bridge.new()
func _ready() -> void: add_child(audio)
func play(event: String, context: Dictionary = {}) -> void:
	var heavy := event in ["takedown_land", "submission_finish", "tap"]
	audio.play_impact(heavy)
	if context.has("node"): Juice.punch(context["node"])
func on_read_level(_a: bool, _level: int, _dir: int) -> void: pass
func on_window_closed() -> void: InputBuffer.clear()
func register_camera() -> void: pass
func register_telegraphs() -> void: pass
