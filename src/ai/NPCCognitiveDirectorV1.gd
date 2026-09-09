class_name NPCCognitiveDirectorV1
extends RefCounted

const FULL_RUNTIME := "L3_FULL_RUNTIME"
const ACTIVE_REGION := "L2_ACTIVE_REGION"

var plan_cache: Dictionary = {}

func should_request_slow_plan(npc_state: Dictionary, salient_event: bool, current_tick: int) -> bool:
	var tier := str(npc_state.get("simulation_tier", "L0_DORMANT"))
	if tier != FULL_RUNTIME and tier != ACTIVE_REGION:
		return false
	if salient_event:
		return true
	var npc_id := str(npc_state.get("id", npc_state.get("npc_id", "")))
	if npc_id == "":
		return false
	if not plan_cache.has(npc_id):
		return true
	return int(plan_cache[npc_id].get("valid_until_tick", -1)) < current_tick

func filter_context(profile: Dictionary, npc_state: Dictionary, visible_facts: Array, allowed_actions: Array, current_tick: int) -> Dictionary:
	var permitted_scopes: Array = profile.get("knowledge_scopes", []).duplicate(true)
	if "PUBLIC" not in permitted_scopes:
		permitted_scopes.append("PUBLIC")
	var facts: Array = []
	for raw_fact in visible_facts:
		if typeof(raw_fact) != TYPE_DICTIONARY:
			continue
		var fact: Dictionary = raw_fact
		var scope := str(fact.get("scope", "UNKNOWN"))
		if scope != "UNKNOWN" and scope in permitted_scopes:
			facts.append(fact.duplicate(true))
	return {
		"npc_id": str(profile.get("id", "")),
		"archetype": str(profile.get("archetype", "")),
		"node": str(npc_state.get("node", "")),
		"activity": str(npc_state.get("activity", "idle")),
		"simulation_tier": str(npc_state.get("simulation_tier", "L0_DORMANT")),
		"current_goal": str(npc_state.get("current_goal", "")),
		"relationships": npc_state.get("relationships", {}).duplicate(true),
		"memory": _bounded_memories(npc_state.get("memory", []), 12),
		"facts": facts,
		"allowed_actions": _sanitize_allowed_actions(allowed_actions),
		"current_tick": current_tick,
	}

func accept_plan_candidate(plan: Dictionary, npc_id: String, current_tick: int, allowed_actions: Array) -> bool:
	if str(plan.get("version", "")) != "1.0.0":
		return false
	if str(plan.get("npc_id", "")) != npc_id:
		return false
	if str(plan.get("goal_id", "")).strip_edges() == "":
		return false
	if int(plan.get("valid_until_tick", -1)) <= current_tick:
		return false
	var candidates = plan.get("candidate_actions", [])
	if typeof(candidates) != TYPE_ARRAY or candidates.is_empty() or candidates.size() > 5:
		return false
	var allowed := _allowed_action_index(allowed_actions)
	if allowed.is_empty():
		return false
	var seen: Dictionary = {}
	for raw_candidate in candidates:
		if typeof(raw_candidate) != TYPE_DICTIONARY:
			return false
		var candidate: Dictionary = raw_candidate
		var action_id := str(candidate.get("action_id", ""))
		var category := str(candidate.get("category", ""))
		if action_id == "" or not allowed.has(action_id) or seen.has(action_id):
			return false
		seen[action_id] = true
		var allowed_row: Dictionary = allowed[action_id]
		var allowed_category := str(allowed_row.get("category", ""))
		if allowed_category != "" and category != allowed_category:
			return false
		var weight := float(candidate.get("weight", -1.0))
		if weight < 0.0 or weight > 1.0:
			return false
	var tags = plan.get("strategy_tags", [])
	if typeof(tags) != TYPE_ARRAY or tags.size() > 8:
		return false
	var memory_candidate = plan.get("memory_summary_candidate", null)
	if memory_candidate != null and str(memory_candidate).length() > 600:
		return false
	plan_cache[npc_id] = plan.duplicate(true)
	return true

func current_plan(npc_id: String, current_tick: int) -> Dictionary:
	if not plan_cache.has(npc_id):
		return {}
	var plan: Dictionary = plan_cache[npc_id]
	if int(plan.get("valid_until_tick", -1)) <= current_tick:
		plan_cache.erase(npc_id)
		return {}
	return plan.duplicate(true)

func discard_plan(npc_id: String) -> void:
	plan_cache.erase(npc_id)

func _bounded_memories(raw, limit: int) -> Array:
	if typeof(raw) != TYPE_ARRAY:
		return []
	var values: Array = raw.duplicate(true)
	if values.size() <= limit:
		return values
	return values.slice(values.size() - limit, values.size())

func _allowed_action_index(allowed_actions: Array) -> Dictionary:
	var out: Dictionary = {}
	for raw_action in allowed_actions:
		if typeof(raw_action) == TYPE_STRING:
			out[str(raw_action)] = {"id": str(raw_action), "category": ""}
		elif typeof(raw_action) == TYPE_DICTIONARY:
			var row: Dictionary = raw_action
			var action_id := str(row.get("id", row.get("action_id", "")))
			if action_id != "":
				out[action_id] = row.duplicate(true)
	return out

func _sanitize_allowed_actions(allowed_actions: Array) -> Array:
	var index := _allowed_action_index(allowed_actions)
	var ids: Array = index.keys()
	ids.sort()
	var out: Array = []
	for raw_id in ids:
		var action_id := str(raw_id)
		var row: Dictionary = index[action_id]
		out.append({
			"id": action_id,
			"category": str(row.get("category", "")),
			"from_state": str(row.get("from_state", "")),
			"to_state": str(row.get("to_state", "")),
			"requires_target": bool(row.get("requires_target", false))
		})
	return out
