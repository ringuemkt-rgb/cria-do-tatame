extends Node

## Eixo narrativo do informante. Não controla combate por frame e não reproduz
## procedimentos policiais reais. Trabalha apenas com escolhas, risco e evidência fictícia.

const STATUSES := ["nenhum", "abordado", "recrutado", "ativo", "queimado", "recusado"]
const MAX_EVIDENCE_HISTORY := 64

var status := "nenhum"
var trust_pf := 0
var trust_reis := 0
var exposure := 0
var evidence_count := 0
var evidence: Array = []
var assignments: Dictionary = {}

func _ready() -> void:
	_sync_world_flag()

func reset() -> void:
	status = "nenhum"
	trust_pf = 0
	trust_reis = 0
	exposure = 0
	evidence_count = 0
	evidence = []
	assignments = {}
	_sync_world_flag()

func approach(source: String, context: Dictionary = {}) -> Dictionary:
	if status != "nenhum":
		return {"ok": false, "error": "already_approached", "status": status}
	status = "abordado"
	trust_pf = 5 if source == "verena" else 0
	trust_reis = 5 if source == "reis" else 0
	assignments["approach"] = {"source": source, "context": context.duplicate(true), "week": WorldState.week}
	_sync_world_flag()
	_emit_state()
	return {"ok": true, "status": status}

func accept_recruitment(source: String) -> Dictionary:
	if status not in ["abordado", "recusado"]:
		return {"ok": false, "error": "invalid_status", "status": status}
	status = "recrutado"
	if source == "verena": trust_pf += 10
	if source == "reis": trust_reis += 10
	_sync_world_flag()
	_emit_state()
	return {"ok": true, "status": status}

func activate() -> Dictionary:
	if status != "recrutado":
		return {"ok": false, "error": "not_recruited"}
	status = "ativo"
	_sync_world_flag()
	_emit_state()
	return {"ok": true, "status": status}

func refuse() -> Dictionary:
	if status not in ["abordado", "recrutado"]:
		return {"ok": false, "error": "invalid_status"}
	status = "recusado"
	_sync_world_flag()
	_emit_state()
	return {"ok": true, "status": status}

func burn_identity(reason: String, faction_id: String = "") -> Dictionary:
	if status in ["nenhum", "recusado"]:
		return {"ok": false, "error": "informant_inactive"}
	status = "queimado"
	exposure = 100
	WorldState.modify_reputation("sombra", 5.0)
	if faction_id != "":
		FactionManager.apply_heat_delta(faction_id, 15.0, "informant_burned")
	assignments["burned"] = {"reason": reason.left(96), "faction_id": FactionManager.canonical_id(faction_id), "week": WorldState.week}
	_sync_world_flag()
	_emit_state()
	return {"ok": true, "status": status, "reason": reason}

func add_assignment(id: String, objective: String, constraints: Array = [], metadata: Dictionary = {}) -> Dictionary:
	if id == "" or status not in ["recrutado", "ativo"]:
		return {"ok": false, "error": "informant_not_available"}
	assignments[id] = {
		"id": id,
		"objective": objective.left(160),
		"constraints": constraints.duplicate(),
		"metadata": metadata.duplicate(true),
		"status": "active",
		"created_week": int(WorldState.week),
	}
	return {"ok": true, "assignment": assignments[id].duplicate(true)}

func complete_assignment(id: String, clean: bool, result: Dictionary = {}) -> Dictionary:
	if not assignments.has(id):
		return {"ok": false, "error": "assignment_missing"}
	var assignment: Dictionary = assignments[id]
	assignment["status"] = "completed"
	assignment["clean"] = clean
	assignment["result"] = result.duplicate(true)
	assignment["completed_week"] = int(WorldState.week)
	assignments[id] = assignment
	if clean:
		trust_pf = clampi(trust_pf + 6, 0, 100)
		trust_reis = clampi(trust_reis + 4, 0, 100)
		WorldState.modify_reputation("honra", 1.0)
	else:
		exposure = clampi(exposure + 12, 0, 100)
		WorldState.modify_reputation("sombra", 2.0)
	if exposure >= 100:
		burn_identity("exposure_limit")
	_emit_state()
	return {"ok": true, "assignment": assignment}

func add_evidence(id: String, value: int = 1, metadata: Dictionary = {}) -> Dictionary:
	if id == "" or value <= 0:
		return {"ok": false, "error": "invalid_evidence"}
	var record := {
		"id": id.left(64),
		"value": value,
		"week": int(WorldState.week),
		"day": str(WorldState.current_day),
		"metadata": metadata.duplicate(true),
	}
	evidence.append(record)
	while evidence.size() > MAX_EVIDENCE_HISTORY:
		evidence.pop_front()
	evidence_count += value
	WorldState.set_narrative_flag("provas_joaquim", maxi(int(WorldState.get_narrative_flag("provas_joaquim", 0)), evidence_count))
	if SignalBus.has_signal("informant_evidence_added"):
		SignalBus.informant_evidence_added.emit(record, evidence_count)
	return {"ok": true, "evidence_count": evidence_count, "record": record}

func adjust_exposure(delta: int, reason: String = "system") -> int:
	exposure = clampi(exposure + delta, 0, 100)
	if exposure >= 100 and status not in ["queimado", "nenhum", "recusado"]:
		burn_identity(reason)
	_emit_state()
	return exposure

func can_reach_martyr_ending() -> bool:
	return status == "ativo" and evidence_count >= 3 and WorldState.reputation.get("honra", 0.0) >= 8.0

func to_dict() -> Dictionary:
	return {
		"version": 1,
		"status": status,
		"trust_pf": trust_pf,
		"trust_reis": trust_reis,
		"exposure": exposure,
		"evidence_count": evidence_count,
		"evidence": evidence.duplicate(true),
		"assignments": assignments.duplicate(true),
	}

func load_from_dict(data: Dictionary) -> void:
	status = str(data.get("status", "nenhum"))
	if not STATUSES.has(status): status = "nenhum"
	trust_pf = clampi(int(data.get("trust_pf", 0)), 0, 100)
	trust_reis = clampi(int(data.get("trust_reis", 0)), 0, 100)
	exposure = clampi(int(data.get("exposure", 0)), 0, 100)
	evidence_count = maxi(0, int(data.get("evidence_count", 0)))
	evidence = data.get("evidence", []).duplicate(true)
	while evidence.size() > MAX_EVIDENCE_HISTORY:
		evidence.pop_front()
	assignments = data.get("assignments", {}).duplicate(true)
	_sync_world_flag()
	_emit_state()

func _sync_world_flag() -> void:
	if WorldState.has_method("set_narrative_flag"):
		WorldState.set_narrative_flag("informant_status", status)
	else:
		WorldState.story_flags["informant_status"] = status

func _emit_state() -> void:
	if SignalBus.has_signal("informant_status_changed"):
		SignalBus.informant_status_changed.emit(status, to_dict())
