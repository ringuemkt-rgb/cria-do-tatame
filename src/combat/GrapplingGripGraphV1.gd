class_name GrapplingGripGraphV1
extends RefCounted

var topology: Dictionary = {}
var grip_types: Dictionary = {}
var source_slots: Array = []

func _init(topology_data: Dictionary):
	topology = topology_data.duplicate(true)
	source_slots = topology.get("source_slots", []).duplicate(true)
	for raw_type in topology.get("grip_types", []):
		if typeof(raw_type) != TYPE_DICTIONARY:
			continue
		var grip_type: Dictionary = raw_type
		var grip_id := str(grip_type.get("id", ""))
		if grip_id != "":
			grip_types[grip_id] = grip_type.duplicate(true)

func is_ready() -> bool:
	return str(topology.get("version", "")) == "1.0.0" and not grip_types.is_empty() and not source_slots.is_empty()

func new_state(gi: bool) -> Dictionary:
	return {
		"version": "1.0.0",
		"mode": "gi" if gi else "nogi",
		"authority": "GAMEPLAY_INTERACTION_SHADOW_ONLY",
		"edges": [],
		"event_index": 0
	}

func apply_events(state: Dictionary, events: Array) -> Dictionary:
	var next := state.duplicate(true)
	var errors: Array = []
	for raw_event in events:
		if typeof(raw_event) != TYPE_DICTIONARY:
			errors.append("event_not_dictionary")
			continue
		var result := apply_event(next, raw_event)
		if not bool(result.get("ok", false)):
			for error in result.get("errors", []):
				errors.append(str(error))
			continue
		next = result.get("state", next)
	return {"ok": errors.is_empty(), "state": next, "errors": errors}

func apply_event(state: Dictionary, event: Dictionary) -> Dictionary:
	var check := validate_event(state, event)
	if not bool(check.get("ok", false)):
		return {"ok": false, "state": state.duplicate(true), "errors": check.get("errors", [])}

	var next := state.duplicate(true)
	var edges: Array = next.get("edges", []).duplicate(true)
	var kind := str(event.get("kind", ""))
	match kind:
		"establish":
			var actor := int(event.get("actor", 0))
			var source_hand := str(event.get("source_hand", ""))
			var filtered: Array = []
			for raw_edge in edges:
				if typeof(raw_edge) != TYPE_DICTIONARY:
					continue
				var edge: Dictionary = raw_edge
				if int(edge.get("actor", 0)) == actor and str(edge.get("source_hand", "")) == source_hand:
					continue
				filtered.append(edge.duplicate(true))
			edges = filtered
			var edge_id := str(event.get("edge_id", ""))
			if edge_id == "":
				edge_id = _edge_id(event)
			edges.append({
				"edge_id": edge_id,
				"actor": actor,
				"source_hand": source_hand,
				"target_player": int(event.get("target_player", 0)),
				"target_node": str(event.get("target_node", "")),
				"grip_type": str(event.get("grip_type", "")),
				"integrity": clampf(float(event.get("integrity", 1.0)), 0.0, 1.0),
				"established_tick": maxi(0, int(event.get("tick", 0))),
				"source": str(event.get("source", "EXPLICIT_GAMEPLAY_EVENT"))
			})
		"release":
			var release_id := str(event.get("edge_id", ""))
			var kept: Array = []
			for raw_edge in edges:
				if typeof(raw_edge) == TYPE_DICTIONARY and str(raw_edge.get("edge_id", "")) == release_id:
					continue
				kept.append(raw_edge.duplicate(true) if typeof(raw_edge) == TYPE_DICTIONARY else raw_edge)
			edges = kept
		"adjust_integrity":
			var adjust_id := str(event.get("edge_id", ""))
			var delta := float(event.get("integrity_delta", 0.0))
			var adjusted: Array = []
			for raw_edge in edges:
				if typeof(raw_edge) != TYPE_DICTIONARY:
					continue
				var edge: Dictionary = raw_edge.duplicate(true)
				if str(edge.get("edge_id", "")) == adjust_id:
					edge["integrity"] = clampf(float(edge.get("integrity", 1.0)) + delta, 0.0, 1.0)
					if float(edge["integrity"]) <= 0.0:
						continue
				adjusted.append(edge)
			edges = adjusted
		"clear_player":
			var clear_actor := int(event.get("actor", 0))
			var retained: Array = []
			for raw_edge in edges:
				if typeof(raw_edge) == TYPE_DICTIONARY and int(raw_edge.get("actor", 0)) == clear_actor:
					continue
				retained.append(raw_edge.duplicate(true) if typeof(raw_edge) == TYPE_DICTIONARY else raw_edge)
			edges = retained

	next["edges"] = edges
	next["event_index"] = int(next.get("event_index", 0)) + 1
	var state_check := validate_state(next)
	if not bool(state_check.get("ok", false)):
		return {"ok": false, "state": state.duplicate(true), "errors": state_check.get("errors", [])}
	return {"ok": true, "state": next, "errors": []}

func validate_event(state: Dictionary, event: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var mode := str(state.get("mode", ""))
	if mode not in ["gi", "nogi"]:
		errors.append("invalid_mode")
	var kind := str(event.get("kind", ""))
	if kind not in ["establish", "release", "adjust_integrity", "clear_player"]:
		errors.append("invalid_event_kind:%s" % kind)
		return {"ok": false, "errors": errors}

	if kind == "establish":
		var actor := int(event.get("actor", 0))
		var target_player := int(event.get("target_player", 0))
		var source_hand := str(event.get("source_hand", ""))
		var target_node := str(event.get("target_node", ""))
		var grip_id := str(event.get("grip_type", ""))
		if actor not in [1, 2]:
			errors.append("invalid_actor")
		if target_player not in [1, 2] or target_player == actor:
			errors.append("invalid_target_player")
		if source_hand not in source_slots:
			errors.append("invalid_source_hand:%s" % source_hand)
		if not grip_types.has(grip_id):
			errors.append("unknown_grip_type:%s" % grip_id)
		else:
			var spec: Dictionary = grip_types[grip_id]
			if mode not in spec.get("modes", []):
				errors.append("grip_not_allowed_in_mode:%s:%s" % [grip_id, mode])
			if target_node not in spec.get("targets", []):
				errors.append("target_not_allowed_for_grip:%s:%s" % [grip_id, target_node])
		var integrity := float(event.get("integrity", 1.0))
		if integrity < 0.0 or integrity > 1.0:
			errors.append("integrity_out_of_range")
	elif kind in ["release", "adjust_integrity"]:
		if str(event.get("edge_id", "")) == "":
			errors.append("edge_id_required")
		if kind == "adjust_integrity" and not event.has("integrity_delta"):
			errors.append("integrity_delta_required")
	elif kind == "clear_player":
		if int(event.get("actor", 0)) not in [1, 2]:
			errors.append("invalid_actor")

	return {"ok": errors.is_empty(), "errors": errors}

func validate_state(state: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var mode := str(state.get("mode", ""))
	if mode not in ["gi", "nogi"]:
		errors.append("invalid_mode")
	var occupied := {}
	var per_player := {1: 0, 2: 0}
	for raw_edge in state.get("edges", []):
		if typeof(raw_edge) != TYPE_DICTIONARY:
			errors.append("edge_not_dictionary")
			continue
		var edge: Dictionary = raw_edge
		var actor := int(edge.get("actor", 0))
		var source_hand := str(edge.get("source_hand", ""))
		var key := "%d:%s" % [actor, source_hand]
		if occupied.has(key):
			errors.append("hand_has_multiple_grips:%s" % key)
		occupied[key] = true
		if per_player.has(actor):
			per_player[actor] = int(per_player[actor]) + 1
		var event := {
			"kind": "establish",
			"actor": actor,
			"source_hand": source_hand,
			"target_player": int(edge.get("target_player", 0)),
			"target_node": str(edge.get("target_node", "")),
			"grip_type": str(edge.get("grip_type", "")),
			"integrity": float(edge.get("integrity", 1.0))
		}
		var edge_check := validate_event(state, event)
		for error in edge_check.get("errors", []):
			errors.append("edge:%s" % str(error))
	for player in [1, 2]:
		if int(per_player[player]) > 2:
			errors.append("too_many_active_grips:p%d" % player)
	return {"ok": errors.is_empty(), "errors": errors}

func signature_for_player(state: Dictionary, player: int) -> Array:
	var signature: Array[String] = []
	for raw_edge in state.get("edges", []):
		if typeof(raw_edge) != TYPE_DICTIONARY:
			continue
		if int(raw_edge.get("actor", 0)) != player:
			continue
		var grip_id := str(raw_edge.get("grip_type", ""))
		if grip_id != "" and grip_id not in signature:
			signature.append(grip_id)
	signature.sort()
	return signature

func grip_count(state: Dictionary, player: int) -> int:
	var count := 0
	for raw_edge in state.get("edges", []):
		if typeof(raw_edge) == TYPE_DICTIONARY and int(raw_edge.get("actor", 0)) == player:
			count += 1
	return count

func _edge_id(event: Dictionary) -> String:
	return "g%d_%s_to_p%d_%s_%s" % [
		int(event.get("actor", 0)),
		str(event.get("source_hand", "")),
		int(event.get("target_player", 0)),
		str(event.get("target_node", "")),
		str(event.get("grip_type", ""))
	]
