class_name GrapplingMicroStateV1
extends RefCounted

static func from_runtime(base_runtime_state: Dictionary, grip_state: Dictionary, grip_graph, motion_request: Dictionary = {}, physical_state: Dictionary = {}, previous_clip_id: String = "") -> Dictionary:
	var combat: Dictionary = base_runtime_state.get("combat", {}).duplicate(true)
	var mode := "gi" if bool(combat.get("gi", false)) else "nogi"
	var top_player := int(combat.get("top", 0))
	var phase := str(physical_state.get("interaction", {}).get("current_phase", "UNKNOWN"))
	if phase == "" or phase == "idle":
		phase = "UNKNOWN"
	var technique_id := str(motion_request.get("technique_id", ""))
	var attack_type := str(motion_request.get("technique_type", ""))
	var position_id := str(combat.get("pos", "standing_neutral"))

	return {
		"version": "1.0.0",
		"authority": "NON_AUTHORITATIVE_PRESENTATION_MICROSTATE",
		"position_id": position_id,
		"top_player": top_player,
		"mode": mode,
		"phase": phase,
		"technique_id": technique_id,
		"attack_type": attack_type,
		"previous_clip_id": previous_clip_id,
		"players": {
			"p1": _player_projection(1, combat, grip_state, grip_graph, top_player),
			"p2": _player_projection(2, combat, grip_state, grip_graph, top_player)
		},
		"reviewed_interaction": _reviewed_interaction_projection(physical_state),
		"outcome_authority": "BJJGraphReducerV2"
	}

static func role_for_player(microstate: Dictionary, player: int) -> String:
	var top_player := int(microstate.get("top_player", 0))
	if top_player == 0:
		return "neutral"
	return "top" if top_player == player else "bottom"

static func gas_bucket(gas: float) -> String:
	if gas >= 67.0:
		return "fresh"
	if gas >= 34.0:
		return "working"
	return "fatigued"

static func motion_query(microstate: Dictionary, player: int, reaction_id: String = "") -> Dictionary:
	var players: Dictionary = microstate.get("players", {})
	var self_key := "p%d" % player
	var opponent_key := "p%d" % (2 if player == 1 else 1)
	var self_data: Dictionary = players.get(self_key, {})
	var opponent_data: Dictionary = players.get(opponent_key, {})
	return {
		"technique_id": str(microstate.get("technique_id", "")),
		"attack_type": str(microstate.get("attack_type", "")),
		"position_id": str(microstate.get("position_id", "")),
		"top_role": role_for_player(microstate, player),
		"mode": str(microstate.get("mode", "")),
		"phase": str(microstate.get("phase", "UNKNOWN")),
		"reaction_id": reaction_id,
		"gas_bucket": str(self_data.get("gas_bucket", "working")),
		"self_grip_signature": self_data.get("grip_signature", []).duplicate(true),
		"opponent_grip_signature": opponent_data.get("grip_signature", []).duplicate(true),
		"previous_clip_id": str(microstate.get("previous_clip_id", ""))
	}

static func validate(value: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	if str(value.get("authority", "")) != "NON_AUTHORITATIVE_PRESENTATION_MICROSTATE":
		errors.append("invalid_authority")
	if str(value.get("position_id", "")) == "":
		errors.append("position_missing")
	if str(value.get("mode", "")) not in ["gi", "nogi"]:
		errors.append("invalid_mode")
	if int(value.get("top_player", -1)) not in [0, 1, 2]:
		errors.append("invalid_top_player")
	var players = value.get("players", {})
	if typeof(players) != TYPE_DICTIONARY:
		errors.append("players_missing")
	else:
		for key in ["p1", "p2"]:
			if typeof(players.get(key, null)) != TYPE_DICTIONARY:
				errors.append("player_missing:%s" % key)
	return {"ok": errors.is_empty(), "errors": errors}

static func _player_projection(player: int, combat: Dictionary, grip_state: Dictionary, grip_graph, top_player: int) -> Dictionary:
	var fighter: Dictionary = combat.get("p%d" % player, {})
	var gas := clampf(float(fighter.get("gas", 0.0)), 0.0, 100.0)
	var role := "neutral"
	if top_player != 0:
		role = "top" if top_player == player else "bottom"
	return {
		"role": role,
		"gas": gas,
		"gas_bucket": gas_bucket(gas),
		"score": maxi(0, int(fighter.get("score", 0))),
		"grip_slots_used": grip_graph.grip_count(grip_state, player) if grip_graph != null else 0,
		"grip_signature": grip_graph.signature_for_player(grip_state, player) if grip_graph != null else [],
		"balance": "UNKNOWN",
		"pressure": "UNKNOWN",
		"mobility": "UNKNOWN"
	}

static func _reviewed_interaction_projection(physical_state: Dictionary) -> Dictionary:
	var interaction = physical_state.get("interaction", {})
	if typeof(interaction) != TYPE_DICTIONARY:
		return {
			"status": "UNOBSERVED",
			"connection_signature": [],
			"contact_continuity": "UNKNOWN"
		}
	if str(interaction.get("observation_status", "UNOBSERVED")) != "EXPERT_APPROVED":
		return {
			"status": "UNOBSERVED",
			"connection_signature": [],
			"contact_continuity": "UNKNOWN"
		}
	var signature: Array[String] = []
	for raw_edge in interaction.get("connection_graph", []):
		if typeof(raw_edge) != TYPE_DICTIONARY:
			continue
		var token := "%s:%s>%s" % [
			str(raw_edge.get("type", "")),
			str(raw_edge.get("source", "")),
			str(raw_edge.get("target", ""))
		]
		if token not in signature:
			signature.append(token)
	signature.sort()
	return {
		"status": "EXPERT_APPROVED",
		"connection_signature": signature,
		"contact_continuity": interaction.get("contact_continuity", "UNKNOWN")
	}
