extends Node

var pending_crises: Array = []
var last_post: Dictionary = {}

func reset() -> void:
	pending_crises = []
	last_post = {}

func create_interactive_post(media_id: String, tone_id: String) -> Dictionary:
	var media_catalog: Dictionary = DataRegistry.cria_live_interactive.get("post_media", {})
	var tone_catalog: Dictionary = DataRegistry.cria_live_interactive.get("caption_tones", {})
	var media: Dictionary = media_catalog.get(media_id, {})
	var tone: Dictionary = tone_catalog.get(tone_id, {})
	if media.is_empty() or tone.is_empty():
		return {"ok": false, "message": "Postagem invalida."}
	_apply_effects(media.get("effects", {}))
	_apply_effects(tone.get("effects", {}))
	last_post = {
		"media_id": media_id,
		"tone_id": tone_id,
		"caption": tone.get("text", ""),
		"week": WorldState.week,
		"day": WorldState.days[WorldState.day_index]
	}
	CriaLiveManager.generate_post("post_interativo", last_post)
	_check_crises()
	SaveManager.save_game(1)
	return {"ok": true, "post": last_post, "pending_crises": pending_crises}

func respond_comment(response_id: String) -> Dictionary:
	var response_catalog: Dictionary = DataRegistry.cria_live_interactive.get("comment_responses", {})
	var response: Dictionary = response_catalog.get(response_id, {})
	if response.is_empty():
		return {"ok": false, "message": "Resposta invalida."}
	_apply_effects(response.get("effects", {}))
	CriaLiveManager.generate_post("resposta_comentario", {"response_id": response_id, "label": response.get("label", response_id)})
	_check_crises()
	SaveManager.save_game(1)
	return {"ok": true, "response": response, "pending_crises": pending_crises}

func _check_crises() -> void:
	pending_crises = []
	for rule_value in DataRegistry.cria_live_interactive.get("crisis_rules", []):
		if typeof(rule_value) != TYPE_DICTIONARY:
			continue
		var rule: Dictionary = rule_value
		if _condition_met(rule.get("condition", {})):
			pending_crises.append(rule)

func _condition_met(condition: Dictionary) -> bool:
	for key_value in condition.keys():
		var key: String = str(key_value)
		if key.ends_with("_min"):
			var axis_min: String = key.replace("_min", "")
			var min_value: float = _value_for(axis_min)
			if min_value < float(condition[key]):
				return false
		elif key.ends_with("_max"):
			var axis_max: String = key.replace("_max", "")
			var max_value: float = _value_for(axis_max)
			if max_value > float(condition[key]):
				return false
	return true

func _value_for(axis: String) -> float:
	if axis == "ferida" and has_node("/root/TinkerBondManager"):
		return float(TinkerBondManager.ferida)
	return WorldState.get_reputation(axis)

func _apply_effects(effects: Dictionary) -> void:
	for axis_value in ["honra", "hype", "sombra", "legado", "moral", "raiz"]:
		var axis: String = str(axis_value)
		if effects.has(axis):
			WorldState.modify_reputation(axis, float(effects[axis]))
	if effects.has("tinker_event"):
		TinkerBondManager.apply_event(str(effects["tinker_event"]))

func to_dict() -> Dictionary:
	return {"pending_crises": pending_crises, "last_post": last_post}

func load_from_dict(data: Dictionary) -> void:
	pending_crises = data.get("pending_crises", [])
	last_post = data.get("last_post", {})
