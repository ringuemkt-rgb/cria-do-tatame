extends Node

signal memory_event_applied(event_id: String, affected_npcs: Array)
signal memory_event_rejected(event_id: String, reason: String)

const CONTRACT_PATH := "res://data/world/npc_social_memory_contract_v1.json"
const NPCSocialMemoryV1 := preload("res://src/world/NPCSocialMemoryV1.gd")

var contract: Dictionary = {}
var state: Dictionary = {}
var _engine: NPCSocialMemoryV1

func _ready() -> void:
	contract = _load_json(CONTRACT_PATH)
	_engine = NPCSocialMemoryV1.new(contract)
	reset()

func reset() -> void:
	if _engine == null:
		contract = _load_json(CONTRACT_PATH)
		_engine = NPCSocialMemoryV1.new(contract)
	state = _engine.new_state()

func record_event(event: Dictionary, producer: String = "deterministic_runtime") -> Dictionary:
	if _engine == null:
		reset()
	if _producer_is_forbidden(producer):
		var rejected := {
			"ok": false,
			"error": "producer_forbidden",
			"event_id": str(event.get("event_id", ""))
		}
		memory_event_rejected.emit(str(event.get("event_id", "")), "producer_forbidden")
		return rejected

	var result := _engine.ingest_event(state, event, _current_tick())
	if not bool(result.get("ok", false)):
		memory_event_rejected.emit(str(event.get("event_id", "")), str(result.get("error", "invalid_event")))
		return _public_result(result)
	state = result.get("state", state).duplicate(true)
	if not bool(result.get("duplicate", false)):
		memory_event_applied.emit(
			str(result.get("event_id", "")),
			result.get("affected_npcs", []).duplicate()
		)
	return _public_result(result)

func observe_fact(
	fact: Dictionary,
	witnesses: Array,
	event_id: String,
	source_actor_id: String = "world"
) -> Dictionary:
	return record_event({
		"type": "FACT_OBSERVED",
		"event_id": event_id,
		"fact": fact.duplicate(true),
		"witnesses": witnesses.duplicate(),
		"source_actor_id": source_actor_id
	})

func reveal_fact(
	fact: Dictionary,
	recipients: Array,
	event_id: String,
	source_actor_id: String
) -> Dictionary:
	return record_event({
		"type": "FACT_REVEALED",
		"event_id": event_id,
		"fact": fact.duplicate(true),
		"recipients": recipients.duplicate(),
		"source_actor_id": source_actor_id
	})

func hear_claim(
	claim: Dictionary,
	recipients: Array,
	event_id: String,
	source_actor_id: String
) -> Dictionary:
	return record_event({
		"type": "CLAIM_HEARD",
		"event_id": event_id,
		"claim": claim.duplicate(true),
		"recipients": recipients.duplicate(),
		"source_actor_id": source_actor_id
	})

func adjust_relationship(
	npc_id: String,
	target_id: String,
	deltas: Dictionary,
	event_id: String
) -> Dictionary:
	return record_event({
		"type": "RELATIONSHIP_DELTA",
		"event_id": event_id,
		"npc_id": npc_id,
		"target_id": target_id,
		"deltas": deltas.duplicate(true)
	})

func knows_fact(npc_id: String, fact_id: String) -> bool:
	if _engine == null:
		return false
	return _engine.knows_fact(state, npc_id, fact_id)

func get_context(npc_id: String, episode_limit: int = 8) -> Dictionary:
	if _engine == null:
		return {}
	return _engine.get_npc_context(state, npc_id, episode_limit)

func choose_action(npc_id: String, candidates: Array) -> Dictionary:
	if _engine == null:
		return {"ok": false, "action": "", "error": "memory_engine_unavailable"}
	return _engine.choose_action(state, npc_id, candidates)

func get_debug_snapshot() -> Dictionary:
	var npcs: Dictionary = state.get("npcs", {})
	var summary: Dictionary = {}
	var npc_ids: Array = npcs.keys()
	npc_ids.sort()
	for npc_id_value in npc_ids:
		var npc_id := str(npc_id_value)
		var npc: Dictionary = npcs[npc_id]
		summary[npc_id] = {
			"known_fact_count": npc.get("known_facts", {}).size(),
			"belief_count": npc.get("beliefs", {}).size(),
			"relationship_count": npc.get("relationships", {}).size(),
			"contradiction_count": npc.get("contradictions", []).size(),
			"episode_count": npc.get("episodes", []).size()
		}
	return {
		"schema_version": str(state.get("schema_version", "")),
		"sequence": int(state.get("sequence", 0)),
		"event_count": state.get("event_log", []).size(),
		"npcs": summary
	}

func to_dict() -> Dictionary:
	return state.duplicate(true)

func load_from_dict(data: Dictionary) -> void:
	if _engine == null:
		contract = _load_json(CONTRACT_PATH)
		_engine = NPCSocialMemoryV1.new(contract)
	state = _engine.normalize_state(data)

func _public_result(result: Dictionary) -> Dictionary:
	var output := result.duplicate(true)
	output.erase("state")
	return output

func _producer_is_forbidden(producer: String) -> bool:
	var normalized := producer.strip_edges().to_lower()
	for forbidden_value in contract.get("forbidden_writers", []):
		if normalized == str(forbidden_value).strip_edges().to_lower():
			return true
	return false

func _current_tick() -> int:
	if has_node("/root/WorldDirectorManager"):
		var snapshot: Dictionary = WorldDirectorManager.get_snapshot()
		return int(snapshot.get("tick", 0))
	return 0

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("[NPCMemoryManager] Contrato ausente: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[NPCMemoryManager] Falha ao abrir contrato: %s" % path)
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {}
