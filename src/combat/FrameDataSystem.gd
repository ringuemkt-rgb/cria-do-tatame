extends Node
class_name FrameDataSystem

# Traduz o resultado lógico do clash em dados de apresentação. A simulação
# continua independente de animação, hit-stop, câmera lenta e VFX.
func build_clash_frame_data(clash: Dictionary, technique: Dictionary) -> Dictionary:
	var outcome := str(clash.get("outcome", "unmodified"))
	var presentation := {
		"hit_stop_ms": 0,
		"time_scale": 1.0,
		"vfx": "none",
		"audio_cue": "none",
		"submission_start": float(clash.get("submission_advantage", 0.50)),
		"counter_window_ms": 0
	}
	match outcome:
		"critical_advantage":
			presentation["hit_stop_ms"] = 90
			presentation["time_scale"] = 0.72
			presentation["vfx"] = "deck_clash_gold"
			presentation["audio_cue"] = "deck_clash_dominant"
		"advantage":
			presentation["hit_stop_ms"] = 45
			presentation["time_scale"] = 0.88
			presentation["vfx"] = "deck_clash_advantage"
			presentation["audio_cue"] = "deck_clash_advantage"
		"contested":
			presentation["vfx"] = "deck_clash_even"
			presentation["audio_cue"] = "deck_clash_contested"
		"counter_window":
			presentation["counter_window_ms"] = 420
			presentation["vfx"] = "deck_clash_counter"
			presentation["audio_cue"] = "deck_clash_counter"
	if str(technique.get("family", technique.get("familia", ""))) != "finalizacao":
		presentation["submission_start"] = 0.50
	return presentation

func apply_level_clash(frame_data: Dictionary, clash: Dictionary, technique: Dictionary) -> Dictionary:
	var output := frame_data.duplicate(true)
	output["deck_clash"] = clash.duplicate(true)
	output["presentation"] = build_clash_frame_data(clash, technique)
	return output
