extends Node

const P1_AUDIO_PATH := "res://data/audio/p1_audio_events_v1.json"

var enabled: bool = true
var sfx_bus: String = "Master"
var music_bus: String = "Master"
var event_data: Dictionary = {}
var _music_player: AudioStreamPlayer

func _ready() -> void:
	event_data = _load_json(P1_AUDIO_PATH)
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = music_bus
	add_child(_music_player)

func play_sfx(event_id: String) -> void:
	if not enabled:
		return
	if event_data.is_empty():
		event_data = _load_json(P1_AUDIO_PATH)
	var definition: Dictionary = event_data.get("sfx", {}).get(event_id, {})
	if _play_authored_stream(definition, sfx_bus, false):
		return
	var pitch := float(definition.get("fallback_hz", _legacy_pitch(event_id)))
	var duration := float(definition.get("fallback_ms", _legacy_duration_ms(event_id))) / 1000.0
	_play_tone(pitch, duration, sfx_bus, float(definition.get("gain_db", -8.0)))

func play_music_cue(cue_id: String) -> void:
	if not enabled:
		return
	if event_data.is_empty():
		event_data = _load_json(P1_AUDIO_PATH)
	var definition: Dictionary = event_data.get("music", {}).get(cue_id, {})
	if _play_authored_stream(definition, music_bus, true):
		return
	var sequence: Array = definition.get("fallback_sequence_hz", [])
	if sequence.is_empty():
		sequence = _legacy_music_sequence(cue_id)
	var duration := float(definition.get("fallback_note_ms", 150)) / 1000.0
	var gain := float(definition.get("gain_db", -12.0))
	for pitch in sequence:
		_play_tone(float(pitch), duration, music_bus, gain)

func _play_authored_stream(definition: Dictionary, bus: String, is_music: bool) -> bool:
	var path := str(definition.get("path", ""))
	if path == "" or not ResourceLoader.exists(path):
		return false
	var stream = load(path)
	if not stream is AudioStream:
		push_warning("[AudioManager] Recurso não é AudioStream: %s" % path)
		return false
	if is_music:
		_music_player.bus = bus
		_music_player.volume_db = float(definition.get("gain_db", -12.0))
		_music_player.stream = stream
		_music_player.play()
	else:
		var player := AudioStreamPlayer.new()
		player.bus = bus
		player.volume_db = float(definition.get("gain_db", -8.0))
		player.stream = stream
		add_child(player)
		player.finished.connect(player.queue_free, CONNECT_ONE_SHOT)
		player.play()
	return true

func _legacy_pitch(event_id: String) -> float:
	match event_id:
		"grip_de_ferro": return 180.0
		"baiana", "t001": return 120.0
		"corte_joelho", "t025": return 210.0
		"sprawl", "slice_sprawl": return 150.0
		"encerramento_tecnico", "t057": return 260.0
		"botao": return 440.0
		"cria_live": return 520.0
		_: return 200.0

func _legacy_duration_ms(event_id: String) -> float:
	match event_id:
		"baiana", "t001": return 160.0
		"encerramento_tecnico", "t057": return 220.0
		"botao": return 50.0
		_: return 90.0

func _legacy_music_sequence(cue_id: String) -> Array:
	match cue_id:
		"terreiro": return [110.0, 146.0]
		"vitoria": return [220.0, 330.0]
		"derrota": return [110.0, 98.0]
		_: return [160.0]

func _play_tone(freq: float, duration: float, bus: String, gain_db: float = -10.0) -> void:
	var player := AudioStreamPlayer.new()
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 22050.0
	stream.buffer_length = maxf(duration, 0.05)
	player.stream = stream
	player.bus = bus
	player.volume_db = gain_db
	add_child(player)
	player.play()
	var playback: AudioStreamGeneratorPlayback = player.get_stream_playback()
	if playback == null:
		player.queue_free()
		return
	var frames: int = int(stream.mix_rate * duration)
	for i in range(frames):
		var t: float = float(i) / stream.mix_rate
		var env: float = 1.0 - (float(i) / maxf(1.0, float(frames)))
		var sample: float = sin(TAU * freq * t) * 0.12 * env
		playback.push_frame(Vector2(sample, sample))
	await get_tree().create_timer(duration + 0.05).timeout
	if is_instance_valid(player):
		player.queue_free()

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}
