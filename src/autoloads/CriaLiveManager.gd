extends Node

var posts: Array = []
var pending_crises: Array = []
var faction_metrics: Dictionary = {}
var _last_combat_fingerprint: String = ""

func _ready() -> void:
	if SignalBus.has_signal("combat_finished") and not SignalBus.combat_finished.is_connected(_on_combat_finished):
		SignalBus.combat_finished.connect(_on_combat_finished)
	if SignalBus.has_signal("reputation_changed") and not SignalBus.reputation_changed.is_connected(_on_reputation_changed):
		SignalBus.reputation_changed.connect(_on_reputation_changed)

func create_post(text: String, tone: String, author := "cria_live", metadata: Dictionary = {}) -> Dictionary:
	var fingerprint := "%s|%s|%s|%s|%s" % [author, tone, text, WorldState.week, posts.size()]
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(hash(fingerprint))
	var base_metrics := {
		"reach": rng.randi_range(80, 620),
		"credibility": 50.0,
		"polarization": 10.0,
		"hype": 15.0,
		"rejection": 5.0,
		"community_support": 20.0,
		"sponsor_interest": 5.0,
		"authority_attention": 0.0
	}
	for key_value in metadata.get("metrics", {}).keys():
		var key := str(key_value)
		if base_metrics.has(key):
			base_metrics[key] = _merge_metric(base_metrics[key], metadata["metrics"][key_value])
	var post: Dictionary = {
		"id": "post_%d" % posts.size(),
		"author": author,
		"faction_id": str(metadata.get("faction_id", "")),
		"tone": tone,
		"text": text.left(420),
		"week": WorldState.week,
		"day": WorldState.days[WorldState.day_index],
		"likes": max(0, int(float(base_metrics["reach"]) * rng.randf_range(0.28, 0.72))),
		"comments": metadata.get("comments", []).slice(0, 12),
		"metrics": base_metrics,
		"source_event": str(metadata.get("source_event", "")),
		"resolved": bool(metadata.get("resolved", false))
	}
	posts.append(post)
	while posts.size() > 120:
		posts.pop_front()
	_update_faction_metrics(post)
	SignalBus.cria_live_post_created.emit(post)
	SignalBus.cria_live_post_generated.emit(post)
	if SignalBus.has_signal("cria_live_metrics_changed"):
		SignalBus.cria_live_metrics_changed.emit(post.get("faction_id", ""), post.get("metrics", {}))
	return post

func create_faction_post(faction_id: String, text: String, tone: String, metrics: Dictionary = {}) -> Dictionary:
	var normalized_metrics := {
		"reach": float(metrics.get("reach", 0.0)) * 60.0,
		"credibility": float(metrics.get("credibility", 0.0)) * 5.0,
		"polarization": float(metrics.get("polarization", 0.0)) * 5.0,
		"hype": float(metrics.get("hype", metrics.get("reach", 0.0))) * 4.0,
		"rejection": float(metrics.get("rejection", 0.0)) * 4.0,
		"community_support": float(metrics.get("community_support", 0.0)) * 4.0,
		"sponsor_interest": float(metrics.get("sponsor_interest", 0.0)) * 5.0,
		"authority_attention": float(metrics.get("authority_attention", 0.0)) * 5.0
	}
	return create_post(text, tone, faction_id, {
		"faction_id": faction_id,
		"metrics": normalized_metrics,
		"source_event": "faction_operation",
		"resolved": bool(metrics.get("resolved", false))
	})

func generate_post(context, data: Dictionary = {}) -> Dictionary:
	var text := _text_for_context(str(context), data)
	return create_post(text, str(context), "cria_live", {"source_event": str(context)})

func _text_for_context(context: String, data: Dictionary) -> String:
	match context:
		"vitoria":
			return "Macacão venceu. O tatame inteiro sentiu a pressão."
		"derrota":
			return "Hoje o chão ensinou. A resposta vem no treino."
		"treino":
			return "Treino pesado no Terreiro. Base sendo construída."
		"crise":
			return "Cria Live está pegando fogo. Todo mundo quer resposta."
		"sponsor":
			return "Novo apoio fechado. Disciplina também constrói oportunidade."
		"tregua":
			return "Rivais dividiram o mesmo espaço. A paz ainda está em observação."
		"guerra_aberta":
			return "O circuito regional mudou de tom. Academias e eventos estão escolhendo lados."
		_:
			return str(data.get("text", "Movimento registrado no Cria Live."))

func _on_combat_finished(result: Dictionary) -> void:
	var fingerprint := _combat_fingerprint(result)
	if fingerprint == _last_combat_fingerprint:
		return
	_last_combat_fingerprint = fingerprint
	if result.get("winner", "") == WorldState.player_id or result.get("winner", "") == "ruan_macacao":
		create_post(_text_for_context("vitoria", result), "vitoria", "cria_live", {
			"source_event": "combat_finished",
			"metrics": {"reach": 180, "hype": 12, "sponsor_interest": 4}
		})
	else:
		create_post(_text_for_context("derrota", result), "derrota", "cria_live", {
			"source_event": "combat_finished",
			"metrics": {"reach": 120, "credibility": 3, "community_support": 5}
		})

func _combat_fingerprint(result: Dictionary) -> String:
	return "%s|%s|%d|%d|%d" % [
		str(result.get("winner", "")),
		str(result.get("method", "")),
		WorldState.week,
		WorldState.day_index,
		WorldState.fights_won + WorldState.fights_lost
	]

func _on_reputation_changed(axis, _delta, new_value) -> void:
	if str(axis) == "sombra" and float(new_value) > 60.0:
		if not pending_crises.has("crise_investigacao"):
			pending_crises.append("crise_investigacao")
		generate_post("crise", {"axis": axis, "value": new_value})

func _update_faction_metrics(post: Dictionary) -> void:
	var faction_id := str(post.get("faction_id", ""))
	if faction_id == "":
		return
	var aggregate: Dictionary = faction_metrics.get(faction_id, {
		"posts": 0,
		"reach": 0.0,
		"credibility": 50.0,
		"polarization": 0.0,
		"hype": 0.0,
		"rejection": 0.0,
		"community_support": 0.0,
		"sponsor_interest": 0.0,
		"authority_attention": 0.0
	})
	aggregate["posts"] = int(aggregate.get("posts", 0)) + 1
	var metrics: Dictionary = post.get("metrics", {})
	aggregate["reach"] = float(aggregate.get("reach", 0.0)) + float(metrics.get("reach", 0.0))
	for key in ["credibility", "polarization", "hype", "rejection", "community_support", "sponsor_interest", "authority_attention"]:
		var current := float(aggregate.get(key, 0.0))
		var incoming := float(metrics.get(key, current))
		aggregate[key] = clamp(current * 0.75 + incoming * 0.25, 0.0, 100.0)
	faction_metrics[faction_id] = aggregate

func _merge_metric(base_value, incoming):
	if typeof(base_value) == TYPE_INT:
		return max(0, int(base_value) + int(incoming))
	return clamp(float(base_value) + float(incoming), 0.0, 100.0)

func get_feed() -> Array:
	return posts.duplicate(true)

func get_faction_metrics(faction_id: String) -> Dictionary:
	return faction_metrics.get(faction_id, {}).duplicate(true)

func has_pending_crisis() -> bool:
	return pending_crises.size() > 0

func to_dict() -> Dictionary:
	return {
		"posts": posts.duplicate(true),
		"pending_crises": pending_crises.duplicate(true),
		"faction_metrics": faction_metrics.duplicate(true),
		"last_combat_fingerprint": _last_combat_fingerprint
	}

func load_from_dict(data: Dictionary) -> void:
	posts = data.get("posts", []).duplicate(true)
	pending_crises = data.get("pending_crises", []).duplicate(true)
	faction_metrics = data.get("faction_metrics", {}).duplicate(true)
	_last_combat_fingerprint = str(data.get("last_combat_fingerprint", ""))
	while posts.size() > 120:
		posts.pop_front()
