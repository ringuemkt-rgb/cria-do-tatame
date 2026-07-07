extends Node

var pending_crises := []
var last_post := {}

func reset() -> void:
	pending_crises = []
	last_post = {}

func create_interactive_post(media_id: String, tone_id: String) -> Dictionary:
	var media := DataRegistry.cria_live_interactive.get("post_media", {}).get(media_id, {})
	var tone := DataRegistry.cria_live_interactive.get("caption_tones", {}).get(tone_id, {})
	if media.is_empty() or tone.is_empty():
		return {"ok": false, "message": "Postagem invalida."}
	_apply_effects(media.get("effects", {}))
	_apply_effects(tone.get("effects", {}))
	last_post = {"media_id": media_id, "tone_id": tone_id, "caption": tone.get("text", ""), "week": WorldState.week, "day": WorldState.days[WorldState.day_index]}
	CriaLiveManager.generate_post("post_interativo", last_post)
	_check_crises()
	SaveManager.save_game(1)
	return {"ok": true, "post": last_post, "pending_crises": pending_crises}

func respond_comment(response_id: String) -> Dictionary:
	var response := DataRegistry.cria_live_interactive.get("comment_responses", {}).get(response_id, {})
	if response.is_empty():
		return {"ok": false, "message": "Resposta invalida."}
	_apply_effects(response.get("effects", {}))
	CriaLiveManager.generate_post("resposta_comentario", {"response_id": response_id, "label": response.get("label", response_id)})
	_check_crises()
	SaveManager.save_game(1)
	return {"ok": true, "response": response, "pending_crises": pending_crises}

func _check_crises() -> void:
	pending_crises = []
	for rule in DataRegistry.cria_live_interactive.get("crisis_rules", []):
		if _condition_met(rule.get("condition", {})):
			pending_crises.append(rule)

func _condition_met(condition: Dictionary) -> bool:
	for key in condition.keys():
		if key.ends_with("_min"):
			var axis := key.replace("_min", "")
			var value := _value_for(axis)
			if value < float(condition[key]):
				return false
		elif key.ends_with("_max"):
			var axis := key.replace("_max", "")
			var value := _value_for(axis)
			if value > float(condition[key]):
				return false
	return true

func _value_for(axis: String) -> float:
	if axis == "ferida" and has_node("/root/TinkerBondManager"):
		return TinkerBondManager.ferida
	return WorldState.get_reputation(axis)

func _apply_effects(effects: Dictionary) -> void:
	for axis in ["honra", "hype", "sombra", "legado", "moral", "raiz"]:
		if effects.has(axis):
			WorldState.modify_reputation(axis, float(effects[axis]))
	if effects.has("tinker_event"):
		TinkerBondManager.apply_event(str(effects["tinker_event"]))

func to_dict() -> Dictionary:
	return {"pending_crises": pending_crises, "last_post": last_post}

func load_from_dict(data: Dictionary) -> void:
	pending_crises = data.get("pending_crises", [])
	last_post = data.get("last_post", {})
