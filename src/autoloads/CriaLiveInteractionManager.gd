extends Node

const CriaLiveServiceScript = preload("res://src/social/CriaLiveService.gd")

var pending_crises: Array = []
var last_post: Dictionary = {}
var v1_state: Dictionary = {}
var _service

func _ready() -> void:
	_ensure_v1_service()
	if SignalBus.has_signal("week_completed") and not SignalBus.week_completed.is_connected(_on_week_completed):
		SignalBus.week_completed.connect(_on_week_completed)

func _ensure_v1_service() -> void:
	if _service == null:
		_service = CriaLiveServiceScript.new()
		_service.configure(DataRegistry.cria_live_v1, DataRegistry.sponsors)
	if v1_state.is_empty() and _service != null and _service.is_ready():
		v1_state = _service.new_state()
	_sync_profile_authorities()

func reset() -> void:
	pending_crises = []
	last_post = {}
	_ensure_v1_service()
	v1_state = _service.new_state() if _service != null and _service.is_ready() else {}

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

func publish_v1_post(request: Dictionary, extra_context: Dictionary = {}) -> Dictionary:
	_ensure_v1_service()
	if _service == null or not _service.is_ready():
		return {"ok": false, "error": "crialive_service_not_ready"}
	_sync_profile_authorities()
	var context := {
		"week": int(WorldState.week),
		"seed": _world_seed(),
		"infiltration_active": bool(WorldState.story_flags.get("infiltracao_ativa", false)),
		"trend_bonus": 1.0,
		"faction_align": 1.0
	}
	for key_value in extra_context.keys():
		context[str(key_value)] = extra_context[key_value]
	var result: Dictionary = _service.publish_post(v1_state, request, context)
	if not bool(result.get("ok", false)):
		return result
	v1_state = result.get("state", {}).duplicate(true)
	var ad_coin := int(result.get("ad_coin", 0))
	if ad_coin > 0:
		WorldState.money += ad_coin
		WorldState._sync_aliases()
	var honra_delta := float(result.get("honra_delta", 0.0))
	if honra_delta != 0.0:
		WorldState.modify_reputation("honra", honra_delta)
	var post: Dictionary = result.get("post", {})
	var hype_delta := float(post.get("hype_delta", 0.0))
	if hype_delta != 0.0:
		WorldState.modify_reputation("hype", hype_delta)
	_sync_profile_authorities()
	_record_social_events(result.get("events", []))
	_mirror_v1_post(post)
	if bool(post.get("viral", false)):
		SignalBus.crialive_viral.emit(post.duplicate(true))
	if bool(result.get("lay_low_recommended", false)):
		SignalBus.crialive_lay_low_recommended.emit(float(v1_state.get("profile", {}).get("coverage_risk", 0.0)))
	SignalBus.crialive_profile_changed.emit(v1_state.get("profile", {}).duplicate(true))
	SaveManager.save_game(1)
	return result

func ensure_v1_seed_content() -> Dictionary:
	_ensure_v1_service()
	var result: Dictionary = _service.ensure_slice_proposals(v1_state, int(WorldState.week))
	if bool(result.get("ok", false)):
		var before_ids := {}
		for proposal_value in v1_state.get("proposals", []):
			if typeof(proposal_value) == TYPE_DICTIONARY:
				before_ids[str(proposal_value.get("id", ""))] = true
		v1_state = result.get("state", {}).duplicate(true)
		for proposal_value in v1_state.get("proposals", []):
			if typeof(proposal_value) == TYPE_DICTIONARY and not before_ids.has(str(proposal_value.get("id", ""))):
				SignalBus.crialive_proposal_created.emit(proposal_value.duplicate(true))
	return result

func accept_v1_proposal(proposal_id: String) -> Dictionary:
	_ensure_v1_service()
	_sync_profile_authorities()
	var result: Dictionary = _service.accept_proposal(v1_state, proposal_id, int(WorldState.week))
	if not bool(result.get("ok", false)):
		return result
	v1_state = result.get("state", {}).duplicate(true)
	var proposal: Dictionary = result.get("proposal", {})
	WorldState.story_flags["crialive_proposal:%s" % proposal_id] = "accepted"
	_record_social_events(result.get("events", []))
	SignalBus.crialive_proposal_accepted.emit(proposal.duplicate(true))
	SaveManager.save_game(1)
	return result

func sign_v1_sponsor(sponsor_id: String, duration_weeks: int = 4) -> Dictionary:
	_ensure_v1_service()
	_sync_profile_authorities()
	var result: Dictionary = _service.sign_sponsor(v1_state, sponsor_id, duration_weeks)
	if not bool(result.get("ok", false)):
		return result
	v1_state = result.get("state", {}).duplicate(true)
	if not WorldState.active_sponsors.has(sponsor_id):
		WorldState.active_sponsors.append(sponsor_id)
	WorldState._sync_aliases()
	_record_social_events(result.get("events", []))
	SignalBus.sponsor_contract_signed.emit(sponsor_id)
	SaveManager.save_game(1)
	return result

func get_v1_feed() -> Array:
	_ensure_v1_service()
	return _service.get_feed(v1_state, int(WorldState.week)) if _service != null and _service.is_ready() else []

func get_v1_state() -> Dictionary:
	_ensure_v1_service()
	_sync_profile_authorities()
	return v1_state.duplicate(true)

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

func _on_week_completed(completed_week: int) -> void:
	_ensure_v1_service()
	if _service == null or not _service.is_ready():
		return
	var result: Dictionary = _service.weekly_tick(v1_state, completed_week)
	if not bool(result.get("ok", false)):
		return
	v1_state = result.get("state", {}).duplicate(true)
	var payout := int(result.get("payout_coin", 0))
	if payout > 0:
		WorldState.money += payout
		WorldState._sync_aliases()
	_record_social_events(result.get("events", []))
	for event_value in result.get("events", []):
		if typeof(event_value) != TYPE_DICTIONARY:
			continue
		var event: Dictionary = event_value
		if str(event.get("type", "")) == "crialive_sponsor_payout":
			var event_context: Dictionary = event.get("context", {})
			SignalBus.crialive_sponsor_payout.emit(
				str(event_context.get("sponsor_id", "")),
				int(event_context.get("coin", 0)),
				int(event_context.get("week", completed_week))
			)
	_sync_profile_authorities()

func _record_social_events(events: Array) -> void:
	if not has_node("/root/ProgressionOS"):
		return
	for event_value in events:
		if typeof(event_value) != TYPE_DICTIONARY:
			continue
		var event: Dictionary = event_value
		var context: Dictionary = event.get("context", {}).duplicate(true)
		context["domain"] = "social"
		context["domain_xp"] = float(context.get("domain_xp", 0.0))
		ProgressionOS.record_event(
			str(event.get("type", "crialive_event")),
			"crialive_v1",
			float(event.get("amount", 0.0)),
			context
		)
		if str(event.get("type", "")) == "crialive_nemesis_exposure":
			SignalBus.crialive_nemesis_exposure.emit(
				str(context.get("technique_id", "")),
				int(context.get("count", 0))
			)

func _mirror_v1_post(post: Dictionary) -> void:
	if not has_node("/root/CriaLiveManager"):
		return
	var caption := str(post.get("caption", ""))
	if caption == "":
		caption = "Novo registro no CriaLive."
	CriaLiveManager.create_post(caption, str(post.get("tone", "humilde")), "ruan_macacao", {
		"source_event": "crialive_v1",
		"metrics": {
			"reach": int(post.get("likes", 0)),
			"hype": int(round(float(post.get("hype_delta", 0.0))))
		},
		"comments": []
	})

func _sync_profile_authorities() -> void:
	if v1_state.is_empty():
		return
	var profile: Dictionary = v1_state.get("profile", {}).duplicate(true)
	profile["hype"] = WorldState.get_reputation("hype")
	v1_state["profile"] = profile

func _world_seed() -> int:
	if has_node("/root/WorldDirectorManager"):
		var snapshot: Dictionary = WorldDirectorManager.to_dict()
		return int(snapshot.get("seed", 26072026))
	return 26072026

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
	return {
		"pending_crises": pending_crises,
		"last_post": last_post,
		"v1_state": v1_state.duplicate(true)
	}

func load_from_dict(data: Dictionary) -> void:
	pending_crises = data.get("pending_crises", [])
	last_post = data.get("last_post", {})
	_ensure_v1_service()
	v1_state = _service.normalize_state(data.get("v1_state", {})) if _service != null and _service.is_ready() else {}
	_sync_profile_authorities()
