extends Node

const ShadowAdapterScript = preload("res://src/combat/CombatManagerBJJShadowAdapterV1.gd")
const DEFAULT_SHADOW_RULESET := "ibjjf_v6"
const DEFAULT_SHADOW_SEED := 260909
const MAX_COMPARISONS := 128

var adapter
var pending_observation: Dictionary = {}
var comparisons: Array[Dictionary] = []
var session_meta: Dictionary = {}

func _ready() -> void:
	adapter = ShadowAdapterScript.new()
	_connect_signals()
	_initialize_shadow(DEFAULT_SHADOW_SEED)

func _connect_signals() -> void:
	if not SignalBus.combat_started.is_connected(_on_combat_started):
		SignalBus.combat_started.connect(_on_combat_started)
	if not SignalBus.technique_started.is_connected(_on_technique_started):
		SignalBus.technique_started.connect(_on_technique_started)
	if not SignalBus.technique_resolved.is_connected(_on_technique_resolved):
		SignalBus.technique_resolved.connect(_on_technique_resolved)
	if not SignalBus.combat_finished.is_connected(_on_combat_finished):
		SignalBus.combat_finished.connect(_on_combat_finished)

func _initialize_shadow(seed: int) -> void:
	if adapter == null:
		return
	var status: Dictionary = adapter.initialize(seed, DEFAULT_SHADOW_RULESET, true, "touch")
	session_meta["ready"] = bool(status.get("ok", false))
	session_meta["ruleset"] = DEFAULT_SHADOW_RULESET
	session_meta["seed"] = seed
	session_meta["authoritative"] = false
	session_meta["errors"] = status.get("errors", []).duplicate()

func _on_combat_started(arena_id, player_id, opponent_id) -> void:
	comparisons.clear()
	pending_observation = {}
	var seed := _stable_seed(str(arena_id), str(player_id), str(opponent_id))
	if adapter == null:
		adapter = ShadowAdapterScript.new()
	var status: Dictionary = adapter.reset(seed, DEFAULT_SHADOW_RULESET, true, "touch")
	session_meta = {
		"ready": bool(status.get("ok", false)),
		"ruleset": DEFAULT_SHADOW_RULESET,
		"seed": seed,
		"arena_id": str(arena_id),
		"player_id": str(player_id),
		"opponent_id": str(opponent_id),
		"authoritative": false,
		"errors": status.get("errors", []).duplicate()
	}

func _on_technique_started(technique_id, actor_id) -> void:
	pending_observation = {}
	if adapter == null or not adapter.is_ready():
		return
	var combat_manager := get_node_or_null("/root/CombatManager")
	if combat_manager == null or not bool(combat_manager.get("is_running")):
		return
	var actor := str(actor_id)
	var player_number := 1 if actor == str(combat_manager.get("player_id")) else 2
	var actor_state := str(combat_manager.call("get_actor_state_name", actor))
	pending_observation = adapter.observe_legacy_action(
		str(technique_id),
		player_number,
		actor_state
	)
	pending_observation["runtime_actor_id"] = actor
	pending_observation["legacy_state_before"] = actor_state

func _on_technique_resolved(result) -> void:
	if typeof(result) != TYPE_DICTIONARY:
		pending_observation = {}
		return
	var legacy: Dictionary = result
	var comparison := _compare_result(legacy, pending_observation)
	comparisons.append(comparison)
	if comparisons.size() > MAX_COMPARISONS:
		comparisons.pop_front()
	pending_observation = {}

func _on_combat_finished(_result) -> void:
	pending_observation = {}
	session_meta["comparisons"] = comparisons.size()
	session_meta["summary"] = summary()

func _compare_result(legacy: Dictionary, shadow: Dictionary) -> Dictionary:
	var legacy_action := str(legacy.get("technique_id", legacy.get("action_id", "")))
	var out := {
		"authoritative": false,
		"legacy_action_id": legacy_action,
		"legacy_success": bool(legacy.get("success", false)),
		"legacy_state_from": str(legacy.get("actor_state_from", legacy.get("state_from", ""))),
		"legacy_state_to": str(legacy.get("actor_state_to", legacy.get("state_to", ""))),
		"shadow": shadow.duplicate(true),
		"classification": "UNMAPPED"
	}
	if shadow.is_empty():
		out["classification"] = "NO_SHADOW_OBSERVATION"
		return out
	if not bool(shadow.get("observed", false)):
		out["classification"] = str(shadow.get("reason", "UNMAPPED")).to_upper()
		return out
	var event: Dictionary = shadow.get("last_event", {})
	var shadow_event := str(event.get("ev", ""))
	var shadow_success := shadow_event in ["hit", "counter", "score"]
	out["shadow_event"] = shadow_event
	out["shadow_success"] = shadow_success
	out["outcome_match"] = shadow_success == bool(legacy.get("success", false))
	out["known_semantic_delta"] = str(shadow.get("known_delta", ""))
	if not bool(out["outcome_match"]):
		out["classification"] = "OUTCOME_DIVERGENCE"
	elif str(shadow.get("known_delta", "")) != "":
		out["classification"] = "KNOWN_SEMANTIC_DELTA"
	else:
		out["classification"] = "MATCH"
	return out

func summary() -> Dictionary:
	var counts := {}
	for comparison in comparisons:
		var key := str(comparison.get("classification", "UNKNOWN"))
		counts[key] = int(counts.get(key, 0)) + 1
	return {
		"authoritative": false,
		"ruleset": str(session_meta.get("ruleset", DEFAULT_SHADOW_RULESET)),
		"comparisons": comparisons.size(),
		"classifications": counts
	}

func get_last_comparison() -> Dictionary:
	return comparisons[-1].duplicate(true) if not comparisons.is_empty() else {}

func get_comparisons() -> Array:
	return comparisons.duplicate(true)

func get_shadow_snapshot() -> Dictionary:
	return adapter.snapshot() if adapter != null and adapter.is_ready() else {}

func get_session_meta() -> Dictionary:
	return session_meta.duplicate(true)

func _stable_seed(arena: String, player: String, opponent: String) -> int:
	var text := "%s|%s|%s" % [arena, player, opponent]
	var value := 2166136261
	for byte in text.to_utf8_buffer():
		value = int((value ^ int(byte)) * 16777619) & 0x7fffffff
	return max(1, value)
