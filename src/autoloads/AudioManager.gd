extends Node

const CATALOG_PATH: String = "res://data/audio/audio_event_catalog_v01.json"
const DEFAULT_POOL_SIZE: int = 24

@export var enabled: bool = true
@export var sfx_bus: String = "Master"
@export var music_bus: String = "Master"
@export var ambience_bus: String = "Master"

var _events: Dictionary = {}
var _aliases: Dictionary = {}
var _last_played_ms: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer
var _current_music_id: String = ""
var _current_ambience_id: String = ""


func _ready() -> void:
	_load_catalog()
	_build_players()


func _load_catalog() -> void:
	_events.clear()
	_aliases.clear()
	if not FileAccess.file_exists(CATALOG_PATH):
		push_warning("[AudioManager] Catálogo ausente; usando tons de contingência.")
		return
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		push_warning("[AudioManager] Não foi possível abrir o catálogo de áudio.")
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("[AudioManager] Catálogo de áudio inválido.")
		return
	for event_value in parsed.get("events", []):
		if typeof(event_value) != TYPE_DICTIONARY:
			continue
		var event: Dictionary = event_value
		var event_id: String = str(event.get("id", ""))
		if event_id.is_empty():
			continue
		_events[event_id] = event
		for alias_value in event.get("aliases", []):
			var alias_id: String = str(alias_value)
			if not alias_id.is_empty():
				_aliases[alias_id] = event_id


func _build_players() -> void:
	var pool_size: int = DEFAULT_POOL_SIZE
	for index in range(pool_size):
		var player := AudioStreamPlayer.new()
		player.name = "SFX_%02d" % index
		player.bus = sfx_bus
		add_child(player)
		_sfx_players.append(player)
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "Music"
	_music_player.bus = music_bus
	add_child(_music_player)
	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.name = "Ambience"
	_ambience_player.bus = ambience_bus
	add_child(_ambience_player)


func play_sfx(event_id: String, volume_offset_db: float = 0.0) -> void:
	if not enabled:
		return
	var event := _event_for(event_id)
	if event.is_empty():
		_play_tone(_pitch_for(event_id), _duration_for(event_id))
		return
	var canonical_id: String = str(event.get("id", event_id))
	if not _cooldown_ready(canonical_id, int(event.get("cooldown_ms", 40))):
		return
	var stream := _load_event_stream(event)
	if stream == null:
		_play_tone(_pitch_for(event_id), _duration_for(event_id))
		return
	var player := _available_sfx_player()
	if player == null:
		return
	player.stop()
	player.stream = stream
	player.volume_db = float(event.get("volume_db", 0.0)) + volume_offset_db
	player.pitch_scale = 1.0
	player.play()
	_last_played_ms[canonical_id] = Time.get_ticks_msec()


func play_music_cue(cue_id: String) -> void:
	if not enabled:
		return
	var event := _event_for(cue_id)
	if not event.is_empty() and str(event.get("category", "")) == "music":
		_play_loop_event(event, _music_player, true)
		return
	stop_music()
	match cue_id:
		"vitoria":
			play_sfx("arena_positive")
			_play_tone(220.0, 0.14)
			_play_tone(330.0, 0.18)
		"derrota":
			play_sfx("arena_tension")
			_play_tone(98.0, 0.22)
		"terreiro":
			_play_tone(110.0, 0.18)
			_play_tone(146.0, 0.18)
		_:
			_play_tone(160.0, 0.12)


func play_ambience(cue_id: String) -> void:
	if not enabled:
		return
	var event := _event_for(cue_id)
	if event.is_empty() or str(event.get("category", "")) != "ambience":
		return
	_play_loop_event(event, _ambience_player, false)


func stop_music() -> void:
	if _music_player != null:
		_music_player.stop()
	_current_music_id = ""


func stop_ambience() -> void:
	if _ambience_player != null:
		_ambience_player.stop()
	_current_ambience_id = ""


func get_event_catalog_size() -> int:
	return _events.size()


func has_event(event_id: String) -> bool:
	return not _event_for(event_id).is_empty()


func _event_for(event_id: String) -> Dictionary:
	var canonical_id: String = str(_aliases.get(event_id, event_id))
	return _events.get(canonical_id, {})


func _cooldown_ready(event_id: String, cooldown_ms: int) -> bool:
	var previous: int = int(_last_played_ms.get(event_id, -1_000_000))
	return Time.get_ticks_msec() - previous >= cooldown_ms


func _available_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_players:
		if not player.playing:
			return player
	# O limite é intencional no mobile. Reaproveitar a voz mais antiga evita
	# alocar players durante o combate e impede crescimento de memória.
	return _sfx_players[0] if not _sfx_players.is_empty() else null


func _load_event_stream(event: Dictionary) -> AudioStream:
	var path: String = str(event.get("path", ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var resource: Resource = load(path)
	if not (resource is AudioStream):
		return null
	var stream := resource as AudioStream
	if stream is AudioStreamOggVorbis:
		var ogg := stream as AudioStreamOggVorbis
		ogg.loop = bool(event.get("loop", false))
		ogg.loop_offset = 0.0
	return stream


func _play_loop_event(event: Dictionary, player: AudioStreamPlayer, is_music: bool) -> void:
	if player == null:
		return
	var event_id: String = str(event.get("id", ""))
	var current_id: String = _current_music_id if is_music else _current_ambience_id
	if current_id == event_id and player.playing:
		return
	var stream := _load_event_stream(event)
	if stream == null:
		return
	player.stop()
	player.stream = stream
	player.volume_db = float(event.get("volume_db", 0.0))
	player.play()
	if is_music:
		_current_music_id = event_id
	else:
		_current_ambience_id = event_id


func _pitch_for(event_id: String) -> float:
	match event_id:
		"grip_de_ferro", "grip_connect": return 180.0
		"baiana", "impacto_pesado": return 120.0
		"corte_joelho", "passagem": return 210.0
		"sprawl", "defesa": return 150.0
		"encerramento_tecnico", "tap": return 260.0
		"botao", "botao_click": return 440.0
		"cria_live": return 520.0
		_: return 200.0


func _duration_for(event_id: String) -> float:
	match event_id:
		"baiana", "impacto_pesado": return 0.16
		"encerramento_tecnico", "tap": return 0.22
		"botao", "botao_click": return 0.05
		_: return 0.09


func _play_tone(freq: float, duration: float) -> void:
	var player := AudioStreamPlayer.new()
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 22_050.0
	stream.buffer_length = maxf(duration, 0.05)
	player.stream = stream
	player.bus = sfx_bus
	add_child(player)
	player.play()
	var playback: AudioStreamGeneratorPlayback = player.get_stream_playback()
	if playback == null:
		player.queue_free()
		return
	var frames: int = int(stream.mix_rate * duration)
	for index in range(frames):
		var t: float = float(index) / stream.mix_rate
		var envelope: float = 1.0 - (float(index) / maxf(1.0, float(frames)))
		var sample: float = sin(TAU * freq * t) * 0.12 * envelope
		playback.push_frame(Vector2(sample, sample))
	await get_tree().create_timer(duration + 0.05).timeout
	if is_instance_valid(player):
		player.queue_free()
