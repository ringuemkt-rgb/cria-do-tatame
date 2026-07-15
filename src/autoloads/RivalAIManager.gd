extends Node

signal choice_selected(rival_id: String, choice_id: String, reason: String)

var player_memory := []
var rival_memory := []
var memory_limit := 3

func reset_memory() -> void:
	player_memory = []
	rival_memory = []

func record_player_action(action_id: String, family := "") -> void:
	player_memory.append({"id": action_id, "family": family})
	while player_memory.size() > memory_limit:
		player_memory.pop_front()

func choose_action(rival_id: String, combat_state: String, context := {}) -> String:
	var profile := _profile(rival_id)
	if profile.is_empty():
		return "defense"
	var chosen := _context_response(profile, context)
	var reason := "context"
	if chosen == "":
		chosen = _directive_response(rival_id, profile, combat_state, context)
		reason = "world_director"
	if chosen == "":
		chosen = _state_response(profile, combat_state)
		reason = "state"
	if chosen == "":
		var actions: Array = profile.get("preferred_actions", [])
		chosen = str(actions.pick_random()) if not actions.is_empty() else "defense"
		reason = "default"
	rival_memory.append({"rival": rival_id, "id": chosen, "state": combat_state, "reason": reason})
	choice_selected.emit(rival_id, chosen, reason)
	return chosen

func _profile(rival_id: String) -> Dictionary:
	return DataRegistry.rival_ai_profiles.get("profiles", {}).get(rival_id, {})

func _context_response(profile: Dictionary, context: Dictionary) -> String:
	for rule in profile.get("anti_patterns", []):
		if rule.has("if_player_repeats_family") and _repeated_family(str(rule["if_player_repeats_family"])):
			return str(rule.get("response", ""))
		if rule.get("if_player_low_gas", false) and float(context.get("player_gas", 100.0)) <= 25.0:
			return str(rule.get("response", ""))
		if rule.get("if_player_low_moral", false) and float(context.get("player_moral", 100.0)) <= 25.0:
			return str(rule.get("response", ""))
		if rule.get("if_player_low_focus", false) and float(context.get("player_focus", 100.0)) <= 25.0:
			return str(rule.get("response", ""))
		if rule.get("if_random_burst", false) and randf() < 0.35:
			return str(rule.get("response", ""))
	return ""

func _directive_response(rival_id: String, profile: Dictionary, combat_state: String, context: Dictionary) -> String:
	if not has_node("/root/WorldDirectorManager"):
		return ""
	var directive: Dictionary = WorldDirectorManager.get_rival_directive(rival_id)
	if directive.is_empty():
		return ""
	var actions: Array = profile.get("preferred_actions", [])
	var preferred_action := str(directive.get("preferred_action", ""))
	var round_seconds := float(context.get("round_seconds", 0.0))
	var aggression := clamp(float(directive.get("aggression", 0.5)), 0.0, 1.0)
	var risk := clamp(float(directive.get("risk_tolerance", 0.5)), 0.0, 1.0)
	if preferred_action != "" and actions.has(preferred_action):
		if round_seconds <= 20.0 or _player_is_predictable():
			return preferred_action
	if combat_state in profile.get("preferred_states", []) and not actions.is_empty():
		var activation := clamp(0.15 + aggression * 0.35 + risk * 0.2, 0.0, 0.75)
		if randf() <= activation:
			var index := min(actions.size() - 1, int(floor(risk * actions.size())))
			return str(actions[index])
	return ""

func _player_is_predictable() -> bool:
	if player_memory.size() < memory_limit:
		return false
	var first_id := str(player_memory[0].get("id", ""))
	if first_id == "":
		return false
	for item in player_memory:
		if str(item.get("id", "")) != first_id:
			return false
	return true

func _repeated_family(family: String) -> bool:
	if player_memory.size() < memory_limit:
		return false
	for item in player_memory:
		if str(item.get("family", "")) != family:
			return false
	return true

func _state_response(profile: Dictionary, combat_state: String) -> String:
	var states: Array = profile.get("preferred_states", [])
	var actions: Array = profile.get("preferred_actions", [])
	if states.has(combat_state) and not actions.is_empty():
		return str(actions[0])
	return ""

func get_profile_label(rival_id: String) -> String:
	return str(_profile(rival_id).get("display_name", rival_id))
