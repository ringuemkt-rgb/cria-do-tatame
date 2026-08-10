extends Node

signal cue_started(cue_id: String, kind: String, used_fallback: bool)

const CATALOG_PATH := "res://data/audio/audio_cues_v01.json"

var enabled: bool = true
var sfx_bus: String = "Master"
var music_bus: String = "Master"
var catalog: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _music_players: Array[AudioStreamPlayer] = []
var _sfx_cursor: int = 0
var _active_music_index: int = -1
var _music_generation: int = 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_load_catalog()
	_build_player_pool()
	apply_settings(DataRegistry.settings if has_node("/root/DataRegistry") else {})


func apply_settings(settings: Dictionary) -> void:
	var audio: Dictionary = settings.get("audio", {})
	enabled = bool(audio.get("enabled", true))
	var sfx_volume := clampf(float(audio.get("sfx_volume", 0.9)), 0.0, 1.0)
	var music_volume := clampf(float(audio.get("music_volume", 0.8)), 0.0, 1.0)
	for player in _sfx_players:
		player.set_meta("settings_gain_db", linear_to_db(maxf(sfx_volume, 0.001)))
	for player in _music_players:
		player.set_meta("settings_gain_db", linear_to_db(maxf(music_volume, 0.001)))
	if not enabled:
		stop_music(0.05)


func play_sfx(event_id: String, context: Dictionary = {}) -> void:
	if not enabled or event_id == "" or event_id == "none":
		return
	var cue := _resolve_cue(event_id, "sfx")
	if cue.is_empty():
		cue = _legacy_fallback(event_id)
	var asset_path := str(cue.get("asset", ""))
	if asset_path != "" and ResourceLoader.exists(asset_path):
		_play_stream(asset_path, cue, context)
		cue_started.emit(event_id, "sfx", false)
		return
	_play_fallback_tone(cue.get("fallback", {}), cue, context)
	cue_started.emit(event_id, "sfx", true)


func play_music_cue(cue_id: String) -> void:
	if not enabled or cue_id == "" or cue_id == "none":
		return
	var cue: Dictionary = catalog.get("music", {}).get(cue_id, {})
	var asset_path := str(cue.get("asset", ""))
	if asset_path != "" and ResourceLoader.exists(asset_path):
		_crossfade_music(asset_path, cue)
		cue_started.emit(cue_id, "music", false)
		return
	var motif: Array = cue.get("fallback_motif", [])
	if motif.is_empty():
		motif = [160.0]
	_play_motif(motif)
	cue_started.emit(cue_id, "music", true)


func stop_music(fade_seconds: float = 0.35) -> void:
	_music_generation += 1
	for player in _music_players:
		if not player.playing:
			continue
		var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(player, "volume_db", -80.0, maxf(fade_seconds, 0.01))
		tween.tween_callback(player.stop)
	_active_music_index = -1


func _load_catalog() -> void:
	catalog = {}
	if not FileAccess.file_exists(CATALOG_PATH):
		push_warning("[AudioManager] Catalogo ausente: %s" % CATALOG_PATH)
		return
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		push_warning("[AudioManager] Nao abriu catalogo de audio")
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		catalog = parsed


func _build_player_pool() -> void:
	var pool_size := maxi(1, int(catalog.get("budgets", {}).get("max_concurrent_sfx", 8)))
	for index in range(pool_size):
		var player := AudioStreamPlayer.new()
		player.name = "SFX%02d" % index
		player.bus = sfx_bus
		add_child(player)
		_sfx_players.append(player)
	for index in range(2):
		var music_player := AudioStreamPlayer.new()
		music_player.name = "Music%d" % index
		music_player.bus = music_bus
		add_child(music_player)
		_music_players.append(music_player)


func _resolve_cue(event_id: String, kind: String) -> Dictionary:
	var cues: Dictionary = catalog.get(kind, {})
	var cue: Dictionary = cues.get(event_id, {})
	var seen: Dictionary = {}
	while cue.has("alias"):
		var alias := str(cue.get("alias", ""))
		if alias == "" or seen.has(alias):
			return {}
		seen[alias] = true
		cue = cues.get(alias, {})
	return cue.duplicate(true)


func _play_stream(asset_path: String, cue: Dictionary, context: Dictionary) -> void:
	var player := _next_sfx_player()
	if player == null:
		return
	player.stop()
	player.stream = load(asset_path)
	player.bus = sfx_bus
	player.volume_db = float(cue.get("gain_db", -8.0)) + float(player.get_meta("settings_gain_db", 0.0)) + float(context.get("gain_db", 0.0))
	var variance := absf(float(cue.get("pitch_variance", 0.0)))
	player.pitch_scale = clampf(float(context.get("pitch_scale", 1.0)) + _rng.randf_range(-variance, variance), 0.65, 1.45)
	player.play()


func _play_fallback_tone(fallback: Dictionary, cue: Dictionary, context: Dictionary) -> void:
	var frequency := float(fallback.get("frequency", 200.0))
	var duration := maxf(0.03, float(fallback.get("duration", 0.09)))
	var wave := str(fallback.get("wave", "sine"))
	var player := _next_sfx_player()
	if player == null:
		return
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = float(catalog.get("budgets", {}).get("generator_mix_rate", 22050))
	stream.buffer_length = duration + 0.02
	player.stop()
	player.stream = stream
	player.bus = sfx_bus
	player.volume_db = float(cue.get("gain_db", -10.0)) + float(player.get_meta("settings_gain_db", 0.0)) + float(context.get("gain_db", 0.0))
	player.pitch_scale = clampf(float(context.get("pitch_scale", 1.0)), 0.65, 1.45)
	player.play()
	var playback: AudioStreamGeneratorPlayback = player.get_stream_playback()
	if playback == null:
		return
	var frames := int(stream.mix_rate * duration)
	for frame in range(frames):
		var t := float(frame) / stream.mix_rate
		var phase := TAU * frequency * t
		var sample := _wave_sample(wave, phase)
		var envelope := pow(1.0 - float(frame) / maxf(1.0, float(frames)), 1.6)
		var value := sample * 0.13 * envelope
		playback.push_frame(Vector2(value, value))


func _play_motif(frequencies: Array) -> void:
	for index in range(frequencies.size()):
		var cue := {"gain_db": -11.0, "fallback": {"frequency": float(frequencies[index]), "duration": 0.11, "wave": "triangle"}}
		_play_fallback_tone(cue["fallback"], cue, {"pitch_scale": 1.0})
		if index < frequencies.size() - 1:
			await get_tree().create_timer(0.08, true, false, true).timeout


func _crossfade_music(asset_path: String, cue: Dictionary) -> void:
	if _music_players.size() < 2:
		return
	_music_generation += 1
	var generation := _music_generation
	var next_index := 0 if _active_music_index != 0 else 1
	var next_player := _music_players[next_index]
	next_player.stop()
	next_player.stream = load(asset_path)
	next_player.bus = music_bus
	next_player.volume_db = -80.0
	next_player.play()
	var settings_gain := float(next_player.get_meta("settings_gain_db", 0.0))
	var target_db := float(cue.get("gain_db", -8.0)) + settings_gain
	var seconds := float(catalog.get("budgets", {}).get("music_crossfade_seconds", 0.8))
	var tween := create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(next_player, "volume_db", target_db, seconds)
	if _active_music_index >= 0:
		var old_player := _music_players[_active_music_index]
		tween.tween_property(old_player, "volume_db", -80.0, seconds)
		tween.finished.connect(_finish_music_crossfade.bind(old_player, generation), CONNECT_ONE_SHOT)
	_active_music_index = next_index


func _finish_music_crossfade(old_player: AudioStreamPlayer, generation: int) -> void:
	if generation != _music_generation or not is_instance_valid(old_player):
		return
	if _active_music_index >= 0 and old_player == _music_players[_active_music_index]:
		return
	old_player.stop()


func _next_sfx_player() -> AudioStreamPlayer:
	if _sfx_players.is_empty():
		return null
	for player in _sfx_players:
		if not player.playing:
			return player
	var player := _sfx_players[_sfx_cursor % _sfx_players.size()]
	_sfx_cursor = (_sfx_cursor + 1) % _sfx_players.size()
	return player


func _wave_sample(wave: String, phase: float) -> float:
	match wave:
		"square": return 1.0 if sin(phase) >= 0.0 else -1.0
		"triangle": return asin(sin(phase)) * (2.0 / PI)
		_: return sin(phase)


func _legacy_fallback(event_id: String) -> Dictionary:
	var pitch := 200.0
	var duration := 0.09
	match event_id:
		"crowd_roar":
			pitch = 116.0
			duration = 0.38
		"baiana": pitch = 120.0
		"encerramento_tecnico":
			pitch = 260.0
			duration = 0.22
		"cria_live": pitch = 520.0
	return {"gain_db": -10.0, "fallback": {"frequency": pitch, "duration": duration, "wave": "sine"}}
