# Combat audio bridge: presentation requests flow through the sole AudioManager mixer.
class_name CombatAudioBridge
extends Node

func play_impact(heavy: bool) -> void:
	if AudioManager and AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("tatame_impact_heavy" if heavy else "tatame_impact_light")

func play_grip() -> void:
	if AudioManager and AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("gi_rustle")

func set_breathing(exhaustion_ratio: float) -> void:
	if AudioManager and AudioManager.has_method("set_layer_volume"):
		AudioManager.set_layer_volume("breath_heavy", clampf(exhaustion_ratio, 0.0, 1.0))
		AudioManager.set_layer_volume("breath_normal", clampf(1.0 - exhaustion_ratio, 0.0, 1.0))
