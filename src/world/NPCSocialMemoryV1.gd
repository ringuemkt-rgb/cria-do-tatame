class_name NPCSocialMemoryV1
extends RefCounted

var contract: Dictionary = {}

func _init(contract_data: Dictionary) -> void:
	contract = contract_data.duplicate(true)

func new_state() -> Dictionary:
	return {
		"schema_version": str(contract.get("version", "1.0.0")),
		"sequence": 0,
		"npcs": {},
		"event_log": [],
		"event_ids": {}
	}

func normalize_state(raw_state: Dictionary) -> Dictionary:
	var state := raw_state.duplicate(true) if not raw_state.is_empty() else new_state()
	state["schema_version"] = str(contract.get("version", "1.0.0"))
	if not state.has("sequence"):
		state["sequence"] = 0
	if not state.has("npcs") or not (state["npcs"] is Dictionary):
		state["npcs"] = {}
	if not state.has("event_log") or not (state["event_log"] is Array):
		state["event_log"] = []
	if not state.has("event_ids") or not (state["event_ids"] is Dictionary):
		state["event_ids"] = {}
	return state

func ingest_event(raw_state: Dictionary, event: Dictionary, fallback_tick: int = 0) -> Dictionary:
	var state := normalize_state(raw_state)
	var error := _validate_event(event)
	if error != "":
		return {"ok": false, "error": error, "state": state}

	var event_id := str(event.get("event_id", ""))
	var event_ids: Dictionary = state.get("event_ids", {})
	if event_ids.has(event_id):
		return {
			"ok": true,
			"duplicate": true,
			"event_id": event_id,
			"state": state,
			"affected_npcs": []
		}

	state["sequence"] = int(state.get("sequence", 0)) + 1
	var tick := int(event.get("tick", fallback_tick))
	var event_type := str(event.get("type", ""))
	var affected_npcs: Array = []

	match event_type:
		"FACT_OBSERVED":
			var fact: Dictionary = event.get("fact", {})
			for npc_id_value in event.get("witnesses", []):
				var npc_id := str(npc_id_value)
				if npc_id == "":
					continue
				state = _apply_fact(state, npc_id, fact, event, "observed", tick)
				affected_npcs.append(npc_id)
		"FACT_REVEALED":
			var revealed_fact: Dictionary = event.get("fact", {})
			for npc_id_value in event.get("recipients", []):
				var npc_id := str(npc_id_value)
				if npc_id == "":
					continue
				state = _apply_fact(state, npc_id, revealed_fact, event, "revealed", tick)
				affected_npcs.append(npc_id)
		"CLAIM_HEARD":
			var claim: Dictionary = event.get("claim", {})
			for npc_id_value in event.get("recipients", []):
				var npc_id := str(npc_id_value)
				if npc_id == "":
					continue
				state = _apply_claim(state, npc_id, claim, event, tick)
				affected_npcs.append(npc_id)
		"RELATIONSHIP_DELTA":
			var npc_id := str(event.get("npc_id", ""))
			var target_id := str(event.get("target_id", ""))
			state = _apply_relationship_delta(state, npc_id, target_id, event.get("deltas", {}), event, tick)
			affected_npcs.append(npc_id)

	affected_npcs = _unique_strings(affected_npcs)
	var event_log: Array = state.get("event_log", []).duplicate(true)
	event_log.append({
		"event_id": event_id,
		"type": event_type,
		"tick": tick,
		"sequence": int(state.get("sequence", 0)),
		"affected_npcs": affected_npcs.duplicate()
	})
	var limit := _limit("event_log", 96)
	while event_log.size() > limit:
		var removed: Dictionary = event_log.pop_front()
		event_ids.erase(str(removed.get("event_id", "")))
	state["event_log"] = event_log
	event_ids[event_id] = int(state.get("sequence", 0))
	state["event_ids"] = event_ids

	return {
		"ok": true,
		"duplicate": false,
		"event_id": event_id,
		"state": state,
		"affected_npcs": affected_npcs
	}

func knows_fact(raw_state: Dictionary, npc_id: String, fact_id: String) -> bool:
	var state := normalize_state(raw_state)
	var npc: Dictionary = state.get("npcs", {}).get(npc_id, {})
	return npc.get("known_facts", {}).has(fact_id)

func get_npc_context(raw_state: Dictionary, npc_id: String, episode_limit: int = 8) -> Dictionary:
	var state := normalize_state(raw_state)
	var npc: Dictionary = state.get("npcs", {}).get(npc_id, _empty_npc_state()).duplicate(true)
	var episodes: Array = npc.get("episodes", []).duplicate(true)
	var keep := clampi(episode_limit, 0, episodes.size())
	if keep == 0:
		episodes = []
	elif episodes.size() > keep:
		episodes = episodes.slice(episodes.size() - keep, episodes.size())
	return {
		"npc_id": npc_id,
		"known_facts": npc.get("known_facts", {}).duplicate(true),
		"beliefs": npc.get("beliefs", {}).duplicate(true),
		"relationships": npc.get("relationships", {}).duplicate(true),
		"contradictions": npc.get("contradictions", []).duplicate(true),
		"recent_episodes": episodes,
		"memory_sequence": int(state.get("sequence", 0))
	}

func choose_action(raw_state: Dictionary, npc_id: String, candidates: Array) -> Dictionary:
	var state := normalize_state(raw_state)
	var npc: Dictionary = state.get("npcs", {}).get(npc_id, _empty_npc_state())
	var ordered: Array = candidates.duplicate(true)
	ordered.sort_custom(func(a, b): return str(a.get("id", "")) < str(b.get("id", "")))
	var scores: Array = []
	var best_id := ""
	var best_score := -INF
	for candidate_value in ordered:
		if not (candidate_value is Dictionary):
			continue
		var candidate: Dictionary = candidate_value
		var candidate_id := str(candidate.get("id", ""))
		if candidate_id == "":
			continue
		var score := float(candidate.get("base_utility", 0.0))
		var target_id := str(candidate.get("target_id", ""))
		var relationship: Dictionary = npc.get("relationships", {}).get(target_id, {})
		for tag_value in candidate.get("tags", []):
			var tag := str(tag_value)
			var weights: Dictionary = contract.get("deterministic_action_tags", {}).get(tag, {})
			for axis_value in weights.keys():
				var axis := str(axis_value)
				score += float(weights[axis]) * float(relationship.get(axis, 0.0))
		score += _deterministic_jitter(npc_id, candidate_id, int(state.get("sequence", 0)))
		scores.append({"id": candidate_id, "score": score})
		if score > best_score:
			best_score = score
			best_id = candidate_id
	return {
		"ok": best_id != "",
		"action": best_id,
		"score": best_score if best_id != "" else 0.0,
		"scores": scores,
		"sequence": int(state.get("sequence", 0))
	}

func _validate_event(event: Dictionary) -> String:
	var event_type := str(event.get("type", ""))
	if not contract.get("event_types", []).has(event_type):
		return "unknown_event_type:%s" % event_type
	var required_by_type: Dictionary = contract.get("event_required_fields", {})
	for field_value in required_by_type.get(event_type, []):
		var field := str(field_value)
		if not event.has(field):
			return "missing_event_field:%s:%s" % [event_type, field]
	if str(event.get("event_id", "")) == "":
		return "empty_event_id"
	if event_type in ["FACT_OBSERVED", "FACT_REVEALED"]:
		return _validate_fact(event.get("fact", {}))
	if event_type == "CLAIM_HEARD":
		return _validate_claim(event.get("claim", {}))
	if event_type == "RELATIONSHIP_DELTA":
		if str(event.get("npc_id", "")) == "" or str(event.get("target_id", "")) == "":
			return "relationship_missing_actor"
		if not (event.get("deltas", {}) is Dictionary):
			return "relationship_deltas_not_dictionary"
	return ""

func _validate_fact(fact_value) -> String:
	if not (fact_value is Dictionary):
		return "fact_not_dictionary"
	var fact: Dictionary = fact_value
	for field_value in contract.get("fact_required_fields", []):
		var field := str(field_value)
		if not fact.has(field):
			return "fact_missing_field:%s" % field
	if str(fact.get("id", "")) == "":
		return "fact_empty_id"
	var scope := str(fact.get("scope", "UNKNOWN"))
	if not contract.get("knowledge_scopes", []).has(scope) or scope == "UNKNOWN":
		return "fact_scope_not_learnable:%s" % scope
	return ""

func _validate_claim(claim_value) -> String:
	if not (claim_value is Dictionary):
		return "claim_not_dictionary"
	var claim: Dictionary = claim_value
	for field_value in contract.get("claim_required_fields", []):
		var field := str(field_value)
		if not claim.has(field):
			return "claim_missing_field:%s" % field
	if str(claim.get("id", "")) == "":
		return "claim_empty_id"
	var confidence := float(claim.get("confidence", -1.0))
	if confidence < 0.0 or confidence > 1.0:
		return "claim_confidence_out_of_range"
	return ""

func _apply_fact(state: Dictionary, npc_id: String, fact: Dictionary, event: Dictionary, mode: String, tick: int) -> Dictionary:
	var next := state.duplicate(true)
	var npcs: Dictionary = next.get("npcs", {}).duplicate(true)
	var npc := _npc_state(npcs, npc_id)
	var known_facts: Dictionary = npc.get("known_facts", {}).duplicate(true)
	var known_order: Array = npc.get("known_fact_order", []).duplicate(true)
	var fact_id := str(fact.get("id", ""))
	var record: Dictionary = known_facts.get(fact_id, {
		"fact": fact.duplicate(true),
		"known_since_tick": tick,
		"provenance": []
	}).duplicate(true)
	record["fact"] = fact.duplicate(true)
	record["provenance"] = _append_provenance(record.get("provenance", []), event, mode, tick)
	known_facts[fact_id] = record
	if not known_order.has(fact_id):
		known_order.append(fact_id)
	_trim_map_order(known_facts, known_order, _limit("known_facts_per_npc", 64))
	npc["known_facts"] = known_facts
	npc["known_fact_order"] = known_order

	var belief_key := _proposition_key(fact)
	var beliefs: Dictionary = npc.get("beliefs", {}).duplicate(true)
	if beliefs.has(belief_key):
		var belief: Dictionary = beliefs[belief_key].duplicate(true)
		if _same_value(belief.get("value"), fact.get("value")):
			belief["status"] = "confirmed_by_fact"
			belief["confidence"] = 1.0
			belief["resolved_by_fact_id"] = fact_id
		else:
			npc = _record_contradiction(npc, {
				"kind": "belief_vs_fact",
				"key": belief_key,
				"belief_value": belief.get("value"),
				"fact_value": fact.get("value"),
				"fact_id": fact_id,
				"event_id": str(event.get("event_id", "")),
				"tick": tick
			})
			var claim_source := str(belief.get("last_source_actor_id", ""))
			if claim_source != "":
				var policy: Dictionary = contract.get("contradiction_policy", {})
				npc = _adjust_relationship(npc, claim_source, {
					"suspicion": float(policy.get("contradicted_claim_suspicion_delta", 12.0)),
					"trust": float(policy.get("contradicted_claim_trust_delta", -8.0))
				})
			belief["status"] = "contradicted_by_fact"
			belief["confidence"] = minf(float(belief.get("confidence", 0.0)), 0.2)
			belief["resolved_by_fact_id"] = fact_id
		beliefs[belief_key] = belief
		npc["beliefs"] = beliefs

	npc = _append_episode(npc, {
		"type": "fact_%s" % mode,
		"fact_id": fact_id,
		"event_id": str(event.get("event_id", "")),
		"tick": tick,
		"source_actor_id": str(event.get("source_actor_id", ""))
	})
	npcs[npc_id] = npc
	next["npcs"] = npcs
	return next

func _apply_claim(state: Dictionary, npc_id: String, claim: Dictionary, event: Dictionary, tick: int) -> Dictionary:
	var next := state.duplicate(true)
	var npcs: Dictionary = next.get("npcs", {}).duplicate(true)
	var npc := _npc_state(npcs, npc_id)
	var key := _proposition_key(claim)
	var incoming_confidence := clampf(float(claim.get("confidence", 0.0)), 0.0, 1.0)
	var source_actor_id := str(event.get("source_actor_id", ""))
	var known_fact := _known_fact_for_key(npc, key)
	var beliefs: Dictionary = npc.get("beliefs", {}).duplicate(true)
	var order: Array = npc.get("belief_order", []).duplicate(true)
	var belief: Dictionary = beliefs.get(key, {
		"subject_id": str(claim.get("subject_id", "")),
		"predicate": str(claim.get("predicate", "")),
		"value": claim.get("value"),
		"confidence": incoming_confidence,
		"status": "unverified",
		"provenance": [],
		"alternatives": []
	}).duplicate(true)

	if not known_fact.is_empty():
		var fact_value = known_fact.get("fact", {}).get("value")
		if _same_value(fact_value, claim.get("value")):
			belief["value"] = claim.get("value")
			belief["confidence"] = 1.0
			belief["status"] = "confirmed_by_known_fact"
		else:
			belief["value"] = claim.get("value")
			belief["confidence"] = incoming_confidence
			belief["status"] = "rejected_by_known_fact"
			npc = _record_contradiction(npc, {
				"kind": "claim_vs_known_fact",
				"key": key,
				"claim_value": claim.get("value"),
				"fact_value": fact_value,
				"claim_id": str(claim.get("id", "")),
				"event_id": str(event.get("event_id", "")),
				"tick": tick
			})
			if source_actor_id != "":
				var policy: Dictionary = contract.get("contradiction_policy", {})
				npc = _adjust_relationship(npc, source_actor_id, {
					"suspicion": float(policy.get("contradicted_claim_suspicion_delta", 12.0)),
					"trust": float(policy.get("contradicted_claim_trust_delta", -8.0))
				})
	else:
		var had_existing := beliefs.has(key)
		if had_existing and not _same_value(belief.get("value"), claim.get("value")):
			npc = _record_contradiction(npc, {
				"kind": "belief_vs_claim",
				"key": key,
				"existing_value": belief.get("value"),
				"incoming_value": claim.get("value"),
				"claim_id": str(claim.get("id", "")),
				"event_id": str(event.get("event_id", "")),
				"tick": tick
			})
			var alternatives: Array = belief.get("alternatives", []).duplicate(true)
			if incoming_confidence > float(belief.get("confidence", 0.0)):
				alternatives.append({
					"value": belief.get("value"),
					"confidence": belief.get("confidence", 0.0),
					"source_actor_id": belief.get("last_source_actor_id", "")
				})
				belief["value"] = claim.get("value")
				belief["confidence"] = incoming_confidence
			else:
				alternatives.append({
					"value": claim.get("value"),
					"confidence": incoming_confidence,
					"source_actor_id": source_actor_id
				})
			belief["alternatives"] = alternatives
			belief["status"] = "contested"
		elif had_existing:
			var old_confidence := clampf(float(belief.get("confidence", 0.0)), 0.0, 1.0)
			belief["confidence"] = 1.0 - ((1.0 - old_confidence) * (1.0 - incoming_confidence))
			belief["status"] = "reinforced"
		else:
			belief["value"] = claim.get("value")
			belief["confidence"] = incoming_confidence
			belief["status"] = "unverified"

	belief["last_source_actor_id"] = source_actor_id
	belief["last_updated_tick"] = tick
	belief["provenance"] = _append_provenance(belief.get("provenance", []), event, "claim", tick)
	beliefs[key] = belief
	if not order.has(key):
		order.append(key)
	_trim_map_order(beliefs, order, _limit("beliefs_per_npc", 32))
	npc["beliefs"] = beliefs
	npc["belief_order"] = order
	npc = _append_episode(npc, {
		"type": "claim_heard",
		"claim_id": str(claim.get("id", "")),
		"event_id": str(event.get("event_id", "")),
		"tick": tick,
		"source_actor_id": source_actor_id
	})
	npcs[npc_id] = npc
	next["npcs"] = npcs
	return next

func _apply_relationship_delta(state: Dictionary, npc_id: String, target_id: String, deltas_value, event: Dictionary, tick: int) -> Dictionary:
	var next := state.duplicate(true)
	var npcs: Dictionary = next.get("npcs", {}).duplicate(true)
	var npc := _npc_state(npcs, npc_id)
	var deltas: Dictionary = deltas_value if deltas_value is Dictionary else {}
	npc = _adjust_relationship(npc, target_id, deltas)
	npc = _append_episode(npc, {
		"type": "relationship_delta",
		"target_id": target_id,
		"event_id": str(event.get("event_id", "")),
		"tick": tick,
		"deltas": deltas.duplicate(true)
	})
	npcs[npc_id] = npc
	next["npcs"] = npcs
	return next

func _npc_state(npcs: Dictionary, npc_id: String) -> Dictionary:
	return npcs.get(npc_id, _empty_npc_state()).duplicate(true)

func _empty_npc_state() -> Dictionary:
	return {
		"known_facts": {},
		"known_fact_order": [],
		"beliefs": {},
		"belief_order": [],
		"relationships": {},
		"episodes": [],
		"contradictions": []
	}

func _known_fact_for_key(npc: Dictionary, proposition_key: String) -> Dictionary:
	for fact_id_value in npc.get("known_fact_order", []):
		var fact_id := str(fact_id_value)
		var record: Dictionary = npc.get("known_facts", {}).get(fact_id, {})
		if _proposition_key(record.get("fact", {})) == proposition_key:
			return record
	return {}

func _adjust_relationship(npc: Dictionary, target_id: String, deltas: Dictionary) -> Dictionary:
	if target_id == "":
		return npc
	var next := npc.duplicate(true)
	var relationships: Dictionary = next.get("relationships", {}).duplicate(true)
	var relation: Dictionary = relationships.get(target_id, {}).duplicate(true)
	var axes: Array = contract.get("relationship_axes", [])
	var range: Dictionary = contract.get("relationship_range", {})
	var minimum := float(range.get("min", -100.0))
	var maximum := float(range.get("max", 100.0))
	for axis_value in deltas.keys():
		var axis := str(axis_value)
		if not axes.has(axis):
			continue
		relation[axis] = clampf(float(relation.get(axis, 0.0)) + float(deltas[axis]), minimum, maximum)
	relationships[target_id] = relation
	next["relationships"] = relationships
	return next

func _record_contradiction(npc: Dictionary, contradiction: Dictionary) -> Dictionary:
	var next := npc.duplicate(true)
	var contradictions: Array = next.get("contradictions", []).duplicate(true)
	contradictions.append(contradiction.duplicate(true))
	while contradictions.size() > _limit("contradictions_per_npc", 24):
		contradictions.pop_front()
	next["contradictions"] = contradictions
	return next

func _append_episode(npc: Dictionary, episode: Dictionary) -> Dictionary:
	var next := npc.duplicate(true)
	var episodes: Array = next.get("episodes", []).duplicate(true)
	episodes.append(episode.duplicate(true))
	while episodes.size() > _limit("episodes_per_npc", 48):
		episodes.pop_front()
	next["episodes"] = episodes
	return next

func _append_provenance(raw_provenance, event: Dictionary, mode: String, tick: int) -> Array:
	var provenance: Array = raw_provenance.duplicate(true) if raw_provenance is Array else []
	provenance.append({
		"event_id": str(event.get("event_id", "")),
		"mode": mode,
		"source_actor_id": str(event.get("source_actor_id", "")),
		"tick": tick
	})
	var limit := _limit("provenance_per_record", 8)
	while provenance.size() > limit:
		provenance.pop_front()
	return provenance

func _trim_map_order(values: Dictionary, order: Array, limit: int) -> void:
	while order.size() > limit:
		var removed_key := str(order.pop_front())
		values.erase(removed_key)

func _proposition_key(value) -> String:
	if not (value is Dictionary):
		return ""
	return "%s|%s" % [str(value.get("subject_id", "")), str(value.get("predicate", ""))]

func _same_value(a, b) -> bool:
	return JSON.stringify(a) == JSON.stringify(b)

func _limit(key: String, fallback: int) -> int:
	return maxi(1, int(contract.get("limits", {}).get(key, fallback)))

func _unique_strings(values: Array) -> Array:
	var seen: Dictionary = {}
	var output: Array = []
	for value in values:
		var text := str(value)
		if text == "" or seen.has(text):
			continue
		seen[text] = true
		output.append(text)
	return output

func _deterministic_jitter(npc_id: String, candidate_id: String, sequence: int) -> float:
	var salt := _string_salt("%s|%s|%d" % [npc_id, candidate_id, sequence])
	return float(absi(salt % 1000)) / 100000.0

func _string_salt(value: String) -> int:
	var out := 0
	for index in range(value.length()):
		out = int((out * 33 + value.unicode_at(index)) % 2147483647)
	return out
