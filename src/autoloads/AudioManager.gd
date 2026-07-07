extends Node

var enabled := true
var sfx_bus := "Master"
var music_bus := "Master"

func play_sfx(event_id: String) -> void:
	if not enabled:
		return
	var pitch := _pitch_for(event_id)
	var duration := _duration_for(event_id)
	_play_tone(pitch, duration)

func play_music_cue(cue_id: String) -> void:
	if not enabled:
		return
	match cue_id:
		"terreiro":
			_play_tone(110.0, 0.18)
			_play_tone(146.0, 0.18)
		"vitoria":
			_play_tone(220.0, 0.14)
			_play_tone(330.0, 0.18)
		"derrota":
			_play_tone(98.0, 0.22)
		_:
			_play_tone(160.0, 0.12)

func _pitch_for(event_id: String) -> float:
	match event_id:
		"grip_de_ferro": return 180.0
		"baiana": return 120.0
		"corte_joelho": return 210.0
		"sprawl": return 150.0
		"encerramento_tecnico": return 260.0
		"botao": return 440.0
		"cria_live": return 520.0
		_: return 200.0

func _duration_for(event_id: String) -> float:
	match event_id:
		"baiana": return 0.16
		"encerramento_tecnico": return 0.22
		"botao": return 0.05
		_: return 0.09

func _play_tone(freq: float, duration: float) -> void:
	var player := AudioStreamPlayer.new()
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 22050
	stream.buffer_length = max(duration, 0.05)
	player.stream = stream
	player.bus = sfx_bus
	add_child(player)
	player.play()
	var playback: AudioStreamGeneratorPlayback = player.get_stream_playback()
	var frames := int(stream.mix_rate * duration)
	for i in range(frames):
		var t := float(i) / stream.mix_rate
		var env := 1.0 - (float(i) / max(1.0, float(frames)))
		var sample := sin(TAU * freq * t) * 0.12 * env
		playback.push_frame(Vector2(sample, sample))
	await get_tree().create_timer(duration + 0.05).timeout
	player.queue_free()
