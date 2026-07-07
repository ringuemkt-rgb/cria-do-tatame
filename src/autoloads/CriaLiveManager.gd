extends Node

var posts: Array = []
var pending_crises: Array = []

func _ready() -> void:
	if SignalBus.has_signal("combat_finished"):
		SignalBus.combat_finished.connect(_on_combat_finished)
	if SignalBus.has_signal("combat_ended"):
		SignalBus.combat_ended.connect(_on_combat_finished)
	SignalBus.reputation_changed.connect(_on_reputation_changed)

func create_post(text: String, tone: String, author := "cria_live"):
	var post = {
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
			return "Novo apoio fechado. Disciplina tambem constrói oportunidade."
		_:
			return "Movimento registrado no Cria Live."

func _on_combat_finished(result: Dictionary) -> void:
	if result.get("winner", "") == WorldState.player_id or result.get("winner", "") == "ruan_macacao":
		generate_post("vitoria", result)
	else:
		generate_post("derrota", result)

func _on_reputation_changed(axis, delta, new_value) -> void:
	if str(axis) == "sombra" and float(new_value) > 60.0:
		pending_crises.append("crise_investigacao")
		generate_post("crise", {"axis": axis, "value": new_value})

func get_feed() -> Array:
	return posts

func has_pending_crisis() -> bool:
	return pending_crises.size() > 0
