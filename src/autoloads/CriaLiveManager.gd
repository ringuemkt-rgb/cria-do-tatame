extends Node

var posts: Array = []
var pending_crises: Array = []
var _last_combat_fingerprint: String = ""

func _ready() -> void:
	# O CombatManager preserva dois sinais por compatibilidade, mas o Cria Live
	# consome apenas o contrato canonico para evitar duas postagens por luta.
	if SignalBus.has_signal("combat_finished") and not SignalBus.combat_finished.is_connected(_on_combat_finished):
		SignalBus.combat_finished.connect(_on_combat_finished)
	if SignalBus.has_signal("reputation_changed") and not SignalBus.reputation_changed.is_connected(_on_reputation_changed):
		SignalBus.reputation_changed.connect(_on_reputation_changed)

func create_post(text: String, tone: String, author := "cria_live") -> Dictionary:
	var post: Dictionary = {
		"id": "post_%d" % posts.size(),
		"author": author,
		"tone": tone,
		"text": text,
		"week": WorldState.week,
		"day": WorldState.days[WorldState.day_index],
		"likes": randi_range(50, 500),
		"comments": []
	}
	posts.append(post)
	SignalBus.cria_live_post_created.emit(post)
	SignalBus.cria_live_post_generated.emit(post)
	return post

func generate_post(context, data: Dictionary = {}) -> Dictionary:
	var text := _text_for_context(str(context), data)
	return create_post(text, str(context), "cria_live")

func _text_for_context(context: String, data: Dictionary) -> String:
	match context:
		"vitoria":
			return "Macacao venceu. O tatame inteiro sentiu a pressao."
		"derrota":
			return "Hoje o chao ensinou. A resposta vem no treino."
		"treino":
			return "Treino pesado no Terreiro. Base sendo construida."
		"crise":
			return "Cria Live esta pegando fogo. Todo mundo quer resposta."
		"sponsor":
			return "Novo apoio fechado. Disciplina tambem constroi oportunidade."
		_:
			return "Movimento registrado no Cria Live."

func _on_combat_finished(result: Dictionary) -> void:
	var fingerprint := _combat_fingerprint(result)
	if fingerprint == _last_combat_fingerprint:
		return
	_last_combat_fingerprint = fingerprint
	if result.get("winner", "") == WorldState.player_id or result.get("winner", "") == "ruan_macacao":
		generate_post("vitoria", result)
	else:
		generate_post("derrota", result)

func _combat_fingerprint(result: Dictionary) -> String:
	return "%s|%s|%d|%d|%d" % [
		str(result.get("winner", "")),
		str(result.get("method", "")),
		WorldState.week,
		WorldState.day_index,
		WorldState.fights_won + WorldState.fights_lost
	]

func _on_reputation_changed(axis, delta, new_value) -> void:
	if str(axis) == "sombra" and float(new_value) > 60.0:
		pending_crises.append("crise_investigacao")
		generate_post("crise", {"axis": axis, "value": new_value})

func get_feed() -> Array:
	return posts

func has_pending_crisis() -> bool:
	return pending_crises.size() > 0
