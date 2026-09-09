class_name NPCEcologyEngineV1
extends RefCounted

var contract: Dictionary = {}
var world_map: Dictionary = {}
var nodes: Dictionary = {}
var validation_errors: Array = []

func _init(contract_data: Dictionary, world_data: Dictionary):
	contract = contract_data.duplicate(true)
	world_map = world_data.duplicate(true)
	for raw_node in world_map.get("nodes", []):
		if typeof(raw_node) != TYPE_DICTIONARY:
			continue
		var node: Dictionary = raw_node
		var node_id := str(node.get("id", ""))
		if node_id == "":
			validation_errors.append("world_node_without_id")
		elif nodes.has(node_id):
			validation_errors.append("duplicate_world_node:%s" % node_id)
		else:
			nodes[node_id] = node.duplicate(true)
	if nodes.is_empty():
		validation_errors.append("world_nodes_missing")

func is_ready() -> bool:
	return validation_errors.is_empty()

func validate_profiles(profiles: Array) -> Array:
	var errors: Array = []
	var seen: Dictionary = {}
	var required_fields: Array = contract.get("npc_required_fields", [])
	for index in range(profiles.size()):
		var raw_profile = profiles[index]
		if typeof(raw_profile) != TYPE_DICTIONARY:
			errors.append("profile_not_dictionary:%d" % index)
			continue
		var profile: Dictionary = raw_profile
		for field in required_fields:
			if not profile.has(str(field)):
				errors.append("profile_missing_field:%s:%s" % [str(profile.get("id", index)), str(field)])
		var npc_id := str(profile.get("id", ""))
		if npc_id == "":
			errors.append("profile_missing_id:%d" % index)
		elif seen.has(npc_id):
			errors.append("duplicate_profile:%s" % npc_id)
		else:
			seen[npc_id] = true
		var home_node := str(profile.get("home_node", ""))
		if home_node != "" and not nodes.has(home_node):
			errors.append("unknown_home_node:%s:%s" % [npc_id, home_node])
		errors.append_array(_validate_schedule(profile))
	return errors

func new_state(profiles: Array, seed: int, start_day: int = 0, start_minute: int = 360) -> Dictionary:
	var errors: Array = validate_profiles(profiles)
	if not errors.is_empty():
		return {"ok": false, "errors": errors}
	var npc_states: Dictionary = {}
	for raw_profile in profiles:
		var profile: Dictionary = raw_profile
		var npc_id := str(profile.get("id"))
		npc_states[npc_id] = {
			"node": str(profile.get("home_node", "")),
			"activity": "idle",
			"simulation_tier": "L0_DORMANT",
			"current_goal": "",
			"memory": [],
			"relationships": profile.get("relationships", {}).duplicate(true)
		}
	return {
		"ok": true,
		"seed": seed,
		"tick": 0,
		"day": maxi(0, start_day),
		"minute": clampi(start_minute, 0, 1439),
		"npc_states": npc_states,
		"event_overrides": {}
	}

func step(state: Dictionary, profiles: Array, elapsed_minutes: int, full_runtime_nodes: Array = [], active_region_nodes: Array = []) -> Dictionary:
	if not bool(state.get("ok", false)):
		return state.duplicate(true)
	if elapsed_minutes <= 0:
		return state.duplicate(true)
	var next: Dictionary = state.duplicate(true)
	var total_minutes := int(next.get("minute", 0)) + elapsed_minutes
	next["day"] = int(next.get("day", 0)) + int(total_minutes / 1440)
	next["minute"] = total_minutes % 1440
	next["tick"] = int(next.get("tick", 0)) + 1
	var states: Dictionary = next.get("npc_states", {}).duplicate(true)
	for raw_profile in profiles:
		if typeof(raw_profile) != TYPE_DICTIONARY:
			continue
		var profile: Dictionary = raw_profile
		var npc_id := str(profile.get("id", ""))
		if npc_id == "" or not states.has(npc_id):
			continue
		var npc_state: Dictionary = states[npc_id].duplicate(true)
		var resolved: Dictionary = resolve_schedule(profile, int(next.get("minute", 0)))
		var override: Dictionary = _resolve_override(next, npc_id)
		if not override.is_empty():
			resolved = override
		var target_node := str(resolved.get("node", profile.get("home_node", "")))
		if nodes.has(target_node):
			npc_state["node"] = target_node
		npc_state["activity"] = str(resolved.get("activity", "idle"))
		npc_state["simulation_tier"] = _tier_for_node(str(npc_state.get("node", "")), full_runtime_nodes, active_region_nodes)
		npc_state["current_goal"] = _select_goal(profile, next, npc_id)
		states[npc_id] = npc_state
	next["npc_states"] = states
	return next

func resolve_schedule(profile: Dictionary, minute: int) -> Dictionary:
	var fallback := {"node": str(profile.get("home_node", "")), "activity": "idle"}
	var schedule = profile.get("schedule", [])
	if typeof(schedule) != TYPE_ARRAY:
		return fallback
	for raw_entry in schedule:
		if typeof(raw_entry) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = raw_entry
		var start := int(entry.get("start_minute", -1))
		var finish := int(entry.get("end_minute", -1))
		if start <= minute and minute < finish:
			return {"node": str(entry.get("node", fallback["node"])), "activity": str(entry.get("activity", "idle"))}
	return fallback

func can_access_fact(profile: Dictionary, fact_scope: String) -> bool:
	if fact_scope == "PUBLIC":
		return true
	if fact_scope == "UNKNOWN":
		return false
	var scopes = profile.get("knowledge_scopes", [])
	return typeof(scopes) == TYPE_ARRAY and fact_scope in scopes

func remember(state: Dictionary, npc_id: String, memory: Dictionary, max_working_memories: int = 12) -> Dictionary:
	var next: Dictionary = state.duplicate(true)
	var states: Dictionary = next.get("npc_states", {}).duplicate(true)
	if not states.has(npc_id):
		return next
	var npc_state: Dictionary = states[npc_id].duplicate(true)
	var memories: Array = npc_state.get("memory", []).duplicate(true)
	var memory_type := str(memory.get("class", "WORKING"))
	if memory_type == "UNKNOWN":
		return next
	var item: Dictionary = memory.duplicate(true)
	item["recorded_tick"] = int(next.get("tick", 0))
	memories.append(item)
	if memory_type == "WORKING":
		var working_indexes: Array = []
		for i in range(memories.size()):
			if str(memories[i].get("class", "")) == "WORKING":
				working_indexes.append(i)
		while working_indexes.size() > max_working_memories:
			var remove_index := int(working_indexes.pop_front())
			memories.remove_at(remove_index)
			for j in range(working_indexes.size()):
				if int(working_indexes[j]) > remove_index:
					working_indexes[j] = int(working_indexes[j]) - 1
	npc_state["memory"] = memories
	states[npc_id] = npc_state
	next["npc_states"] = states
	return next

func set_event_override(state: Dictionary, npc_id: String, node_id: String, activity: String, expires_tick: int) -> Dictionary:
	var next: Dictionary = state.duplicate(true)
	if not nodes.has(node_id):
		return next
	var overrides: Dictionary = next.get("event_overrides", {}).duplicate(true)
	overrides[npc_id] = {"node": node_id, "activity": activity, "expires_tick": expires_tick}
	next["event_overrides"] = overrides
	return next

func _validate_schedule(profile: Dictionary) -> Array:
	var errors: Array = []
	var npc_id := str(profile.get("id", ""))
	var schedule = profile.get("schedule", [])
	if typeof(schedule) != TYPE_ARRAY:
		return ["schedule_not_array:%s" % npc_id]
	var entries: Array = schedule.duplicate(true)
	entries.sort_custom(func(a, b): return int(a.get("start_minute", 0)) < int(b.get("start_minute", 0)))
	var last_end := -1
	for raw_entry in entries:
		if typeof(raw_entry) != TYPE_DICTIONARY:
			errors.append("schedule_entry_not_dictionary:%s" % npc_id)
			continue
		var entry: Dictionary = raw_entry
		for field in contract.get("schedule_entry_required_fields", []):
			if not entry.has(str(field)):
				errors.append("schedule_missing_field:%s:%s" % [npc_id, str(field)])
		var start := int(entry.get("start_minute", -1))
		var finish := int(entry.get("end_minute", -1))
		if start < 0 or finish > 1440 or finish <= start:
			errors.append("schedule_invalid_window:%s:%d:%d" % [npc_id, start, finish])
		if last_end > start:
			errors.append("schedule_overlap:%s:%d" % [npc_id, start])
		last_end = maxi(last_end, finish)
		var node_id := str(entry.get("node", ""))
		if node_id != "" and not nodes.has(node_id):
			errors.append("schedule_unknown_node:%s:%s" % [npc_id, node_id])
	return errors

func _tier_for_node(node_id: String, full_runtime_nodes: Array, active_region_nodes: Array) -> String:
	if node_id in full_runtime_nodes:
		return "L3_FULL_RUNTIME"
	if node_id in active_region_nodes:
		return "L2_ACTIVE_REGION"
	if node_id != "":
		return "L1_STATISTICAL"
	return "L0_DORMANT"

func _resolve_override(state: Dictionary, npc_id: String) -> Dictionary:
	var overrides: Dictionary = state.get("event_overrides", {})
	if not overrides.has(npc_id):
		return {}
	var override: Dictionary = overrides[npc_id]
	if int(override.get("expires_tick", -1)) < int(state.get("tick", 0)):
		return {}
	return override.duplicate(true)

func _select_goal(profile: Dictionary, state: Dictionary, npc_id: String) -> String:
	var goals = profile.get("goals", [])
	if typeof(goals) != TYPE_ARRAY or goals.is_empty():
		return ""
	var best_id := ""
	var best_score := -INF
	for raw_goal in goals:
		if typeof(raw_goal) != TYPE_DICTIONARY:
			continue
		var goal: Dictionary = raw_goal
		var score := float(goal.get("utility", 0.0)) + _deterministic_jitter(int(state.get("seed", 0)), npc_id, str(goal.get("id", "")), int(state.get("day", 0)))
		if score > best_score:
			best_score = score
			best_id = str(goal.get("id", ""))
	return best_id

func _deterministic_jitter(seed: int, npc_id: String, goal_id: String, day: int) -> float:
	var salt := seed + day * 131 + _string_salt(npc_id) * 17 + _string_salt(goal_id) * 31
	var value: int = absi(salt % 1000)
	return float(value) / 100000.0

func _string_salt(value: String) -> int:
	var out := 0
	for i in range(value.length()):
		out = int((out * 33 + value.unicode_at(i)) % 2147483647)
	return out
