extends Node

# CRIA PROGRESSION OS v1
# Ledger auditavel + projecoes derivadas. Nao substitui dinheiro/reputacao:
# WorldState continua autoridade desses dominios; TrainingManager vira ponte de compatibilidade.

const STATE_VERSION := 1

var ledger: Array = []
var domains: Dictionary = {}
var mastery: Dictionary = {}
var respect: int = 0
var achievements: Array = []
var discoveries: Array = []
var counters: Dictionary = {}
var next_event_sequence: int = 1

var _event_ids: Dictionary = {}
var _config: Dictionary = {}
var _replaying: bool = false

func _ready() -> void:
	_refresh_config()
	_ensure_domain_keys()
	_connect_signals()

func _connect_signals() -> void:
	if not SignalBus.combat_finished.is_connected(_on_combat_finished):
		SignalBus.combat_finished.connect(_on_combat_finished)
	if not SignalBus.technique_resolved.is_connected(_on_technique_resolved):
		SignalBus.technique_resolved.connect(_on_technique_resolved)
	if not SignalBus.mission_completed.is_connected(_on_mission_completed):
		SignalBus.mission_completed.connect(_on_mission_completed)
	if SignalBus.has_signal("training_completed") and not SignalBus.training_completed.is_connected(_on_training_completed):
		SignalBus.training_completed.connect(_on_training_completed)
	if SignalBus.has_signal("world_travel_completed") and not SignalBus.world_travel_completed.is_connected(_on_world_travel_completed):
		SignalBus.world_travel_completed.connect(_on_world_travel_completed)

func _refresh_config() -> void:
	_config = {}
	if has_node("/root/DataRegistry"):
		var raw: Dictionary = DataRegistry.progression
		_config = raw.get("runtime_progression", {}).duplicate(true)
	if _config.is_empty():
		_config = _fallback_config()

func _fallback_config() -> Dictionary:
	return {
		"domains": ["combat", "training", "exploration", "story", "social"],
		"mastery_thresholds": [
			{"stage": "discovered", "points": 0.0},
			{"stage": "learned", "points": 100.0},
			{"stage": "practiced", "points": 250.0},
			{"stage": "mastered", "points": 500.0},
			{"stage": "signature", "points": 900.0}
		],
		"event_rules": {
			"combat_win": {"domain": "combat", "domain_xp": 100.0, "respect": 10},
			"combat_loss": {"domain": "combat", "domain_xp": 40.0, "respect": 2},
			"technique_attempt": {"domain": "combat", "domain_xp": 2.0, "respect": 0},
			"physical_training": {"domain": "training", "domain_xp": 35.0, "respect": 1},
			"technical_training": {"domain": "training", "domain_xp": 20.0, "respect": 1},
			"mission_complete": {"domain": "story", "domain_xp": 75.0, "respect": 10},
			"travel_first_visit": {"domain": "exploration", "domain_xp": 50.0, "respect": 3},
			"travel_repeat": {"domain": "exploration", "domain_xp": 5.0, "respect": 0}
		},
		"technical_finish_bonus": {"domain_xp": 25.0, "respect": 5},
		"technique_combat_mastery": {"success": 3.0, "failure": 0.5},
		"achievements": []
	}

func reset() -> void:
	ledger = []
	_event_ids = {}
	domains = {}
	mastery = {}
	respect = 0
	achievements = []
	discoveries = []
	counters = {}
	next_event_sequence = 1
	_refresh_config()
	_ensure_domain_keys()
	_emit_progression_changed()

func is_empty() -> bool:
	return ledger.is_empty() and mastery.is_empty() and achievements.is_empty() and discoveries.is_empty() and respect == 0 and counters.is_empty()

func record_event(
	event_type: String,
	source: String,
	amount: float = 0.0,
	context: Dictionary = {},
	event_id: String = ""
) -> Dictionary:
	var normalized_type: String = event_type.strip_edges()
	var normalized_source: String = source.strip_edges()
	if normalized_type == "" or normalized_source == "":
		return {"ok": false, "error": "invalid_event_identity"}

	var resolved_id: String = event_id.strip_edges()
	if resolved_id == "":
		resolved_id = "evt:%08d:%s:%s" % [next_event_sequence, normalized_source, normalized_type]
	if _event_ids.has(resolved_id):
		return {"ok": false, "duplicate": true, "event_id": resolved_id}

	var rule: Dictionary = _get_event_rule(normalized_type)
	var normalized_context: Dictionary = context.duplicate(true)
	if not normalized_context.has("domain"):
		normalized_context["domain"] = str(rule.get("domain", ""))
	if not normalized_context.has("domain_xp"):
		normalized_context["domain_xp"] = amount if amount != 0.0 else float(rule.get("domain_xp", 0.0))
	if not normalized_context.has("respect"):
		normalized_context["respect"] = int(rule.get("respect", 0))

	var event: Dictionary = {
		"id": resolved_id,
		"type": normalized_type,
		"source": normalized_source,
		"amount": float(normalized_context.get("domain_xp", 0.0)),
		"context": normalized_context,
		"week": int(WorldState.week) if has_node("/root/WorldState") else 0,
		"day": str(WorldState.current_day) if has_node("/root/WorldState") else "",
		"act": int(WorldState.act) if has_node("/root/WorldState") else 0,
		"recorded_at": Time.get_datetime_string_from_system()
	}
	ledger.append(event)
	_event_ids[resolved_id] = true
	next_event_sequence += 1
	_apply_event(event)

	if not bool(normalized_context.get("skip_achievement_eval", false)):
		_evaluate_achievements()
	if SignalBus.has_signal("progress_event_recorded"):
		SignalBus.progress_event_recorded.emit(event.duplicate(true))
	_emit_progression_changed()
	return {"ok": true, "event_id": resolved_id, "event": event.duplicate(true)}

func _get_event_rule(event_type: String) -> Dictionary:
	return _config.get("event_rules", {}).get(event_type, {})

func _apply_event(event: Dictionary) -> void:
	var event_type: String = str(event.get("type", "unknown"))
	var context: Dictionary = event.get("context", {})
	counters[event_type] = int(counters.get(event_type, 0)) + 1

	var domain: String = str(context.get("domain", ""))
	var domain_xp: float = float(context.get("domain_xp", event.get("amount", 0.0)))
	if domain != "":
		domains[domain] = maxf(0.0, float(domains.get(domain, 0.0)) + domain_xp)
		if not _replaying and SignalBus.has_signal("progression_domain_changed"):
			SignalBus.progression_domain_changed.emit(StringName(domain), float(domains[domain]))

	respect = maxi(0, respect + int(context.get("respect", 0)))

	var discovery_id: String = str(context.get("discovery_id", ""))
	if discovery_id != "" and not discoveries.has(discovery_id):
		discoveries.append(discovery_id)

	var achievement_id: String = str(context.get("achievement_id", ""))
	if achievement_id != "" and not achievements.has(achievement_id):
		achievements.append(achievement_id)
		if not _replaying and SignalBus.has_signal("achievement_unlocked"):
			SignalBus.achievement_unlocked.emit(StringName(achievement_id), context.get("reward", {}).duplicate(true))

	var skill_points_delta: int = int(context.get("skill_points_delta", 0))
	if skill_points_delta != 0 and not _replaying and has_node("/root/WorldState"):
		WorldState.skill_points = maxi(0, int(WorldState.skill_points) + skill_points_delta)
		WorldState._sync_aliases()

	var technique_id: String = str(context.get("technique_id", ""))
	if technique_id != "":
		_apply_mastery_delta(technique_id, float(context.get("mastery_xp", 0.0)), event)

func _apply_mastery_delta(technique_id: String, points: float, event: Dictionary) -> void:
	var context: Dictionary = event.get("context", {})
	var entry: Dictionary = mastery.get(technique_id, {
		"technique_id": technique_id,
		"points": 0.0,
		"stage": "discovered",
		"discovered": true,
		"attempts": 0,
		"successes": 0,
		"training_sessions": 0,
		"combat_successes": 0,
		"first_event_id": str(event.get("id", "")),
		"last_event_id": ""
	}).duplicate(true)

	var old_stage: String = str(entry.get("stage", "discovered"))
	entry["discovered"] = true
	entry["points"] = maxf(0.0, float(entry.get("points", 0.0)) + points)
	if bool(context.get("attempted", false)):
		entry["attempts"] = int(entry.get("attempts", 0)) + 1
	if bool(context.get("success", false)):
		entry["successes"] = int(entry.get("successes", 0)) + 1
	if bool(context.get("training", false)):
		entry["training_sessions"] = int(entry.get("training_sessions", 0)) + 1
	if str(event.get("source", "")) == "combat" and bool(context.get("success", false)):
		entry["combat_successes"] = int(entry.get("combat_successes", 0)) + 1
	entry["stage"] = _mastery_stage_for_points(float(entry["points"]))
	entry["last_event_id"] = str(event.get("id", ""))
	mastery[technique_id] = entry

	if not _replaying and _stage_index(str(entry["stage"])) >= _stage_index("learned") and has_node("/root/WorldState"):
		if not WorldState.techniques_learned.has(technique_id):
			WorldState.techniques_learned.append(technique_id)
			WorldState._sync_aliases()

	if not _replaying and SignalBus.has_signal("technique_mastery_changed"):
		SignalBus.technique_mastery_changed.emit(StringName(technique_id), entry.duplicate(true))
	if not _replaying and old_stage != str(entry["stage"]) and SignalBus.has_signal("codex_entry_changed"):
		SignalBus.codex_entry_changed.emit(StringName(technique_id), entry.duplicate(true))

func _mastery_stage_for_points(points: float) -> String:
	var resolved: String = "discovered"
	for threshold_value in _get_mastery_thresholds():
		var threshold: Dictionary = threshold_value
		if points >= float(threshold.get("points", 0.0)):
			resolved = str(threshold.get("stage", resolved))
	return resolved

func _get_mastery_thresholds() -> Array:
	var thresholds: Array = _config.get("mastery_thresholds", [])
	if thresholds.is_empty():
		thresholds = _fallback_config().get("mastery_thresholds", [])
	return thresholds

func _stage_index(stage: String) -> int:
	var thresholds: Array = _get_mastery_thresholds()
	for index in range(thresholds.size()):
		if str(thresholds[index].get("stage", "")) == stage:
			return index
	return 0

func get_mastery_threshold(stage: String) -> float:
	for threshold_value in _get_mastery_thresholds():
		var threshold: Dictionary = threshold_value
		if str(threshold.get("stage", "")) == stage:
			return float(threshold.get("points", 0.0))
	return 0.0

func get_mastery_level(technique_id: String) -> int:
	if not mastery.has(technique_id):
		return 1
	return clampi(_stage_index(str(mastery[technique_id].get("stage", "discovered"))) + 1, 1, _get_mastery_thresholds().size())

func get_mastery_stage(technique_id: String) -> String:
	if not mastery.has(technique_id):
		return "unknown"
	return str(mastery[technique_id].get("stage", "discovered"))

func get_mastery_points(technique_id: String) -> float:
	return float(mastery.get(technique_id, {}).get("points", 0.0))

func get_mastery_points_map() -> Dictionary:
	var output: Dictionary = {}
	for technique_id_value in mastery.keys():
		var technique_id: String = str(technique_id_value)
		output[technique_id] = float(mastery[technique_id].get("points", 0.0))
	return output

func get_codex_entry(technique_id: String) -> Dictionary:
	return mastery.get(technique_id, {}).duplicate(true)

func get_codex_entries() -> Array:
	var output: Array = []
	for technique_id_value in mastery.keys():
		output.append(mastery[str(technique_id_value)].duplicate(true))
	output.sort_custom(_sort_codex_entries)
	return output

func _sort_codex_entries(a: Dictionary, b: Dictionary) -> bool:
	return str(a.get("technique_id", "")) < str(b.get("technique_id", ""))

func get_domain_xp(domain_id: String) -> float:
	return float(domains.get(domain_id, 0.0))

func get_total_xp() -> float:
	var total: float = 0.0
	for value in domains.values():
		total += float(value)
	return total

func get_snapshot() -> Dictionary:
	return {
		"state_version": STATE_VERSION,
		"event_count": ledger.size(),
		"domains": domains.duplicate(true),
		"total_xp": get_total_xp(),
		"respect": respect,
		"mastery": mastery.duplicate(true),
		"achievements": achievements.duplicate(),
		"discoveries": discoveries.duplicate(),
		"counters": counters.duplicate(true)
	}

func to_dict() -> Dictionary:
	return {
		"state_version": STATE_VERSION,
		"ledger": ledger.duplicate(true),
		"domains": domains.duplicate(true),
		"mastery": mastery.duplicate(true),
		"respect": respect,
		"achievements": achievements.duplicate(),
		"discoveries": discoveries.duplicate(),
		"counters": counters.duplicate(true),
		"next_event_sequence": next_event_sequence
	}

func load_from_dict(data: Dictionary) -> void:
	_refresh_config()
	ledger = data.get("ledger", []).duplicate(true)
	domains = data.get("domains", {}).duplicate(true)
	mastery = data.get("mastery", {}).duplicate(true)
	respect = int(data.get("respect", 0))
	achievements = data.get("achievements", []).duplicate()
	discoveries = data.get("discoveries", []).duplicate()
	counters = data.get("counters", {}).duplicate(true)
	next_event_sequence = maxi(1, int(data.get("next_event_sequence", ledger.size() + 1)))
	_event_ids = {}
	for event_value in ledger:
		if typeof(event_value) != TYPE_DICTIONARY:
			continue
		var event: Dictionary = event_value
		var event_id: String = str(event.get("id", ""))
		if event_id != "":
			_event_ids[event_id] = true
	var projections_missing: bool = counters.is_empty() and not ledger.is_empty()
	_ensure_domain_keys()
	if projections_missing:
		rebuild_projections_from_ledger()
	_sync_world_state_techniques()
	_emit_progression_changed()

func rebuild_projections_from_ledger() -> void:
	var saved_ledger: Array = ledger.duplicate(true)
	_clear_projections_only()
	_replaying = true
	for event_value in saved_ledger:
		if typeof(event_value) == TYPE_DICTIONARY:
			_apply_event(event_value)
	_replaying = false
	ledger = saved_ledger
	_ensure_domain_keys()
	_sync_world_state_techniques()
	_emit_progression_changed()

func _clear_projections_only() -> void:
	domains = {}
	mastery = {}
	respect = 0
	achievements = []
	discoveries = []
	counters = {}
	_ensure_domain_keys()

func _ensure_domain_keys() -> void:
	for domain_value in _config.get("domains", []):
		var domain: String = str(domain_value)
		if domain != "" and not domains.has(domain):
			domains[domain] = 0.0

func _sync_world_state_techniques() -> void:
	if not has_node("/root/WorldState"):
		return
	for technique_id_value in mastery.keys():
		var technique_id: String = str(technique_id_value)
		var entry: Dictionary = mastery[technique_id]
		if _stage_index(str(entry.get("stage", "discovered"))) >= _stage_index("learned"):
			if not WorldState.techniques_learned.has(technique_id):
				WorldState.techniques_learned.append(technique_id)
	WorldState._sync_aliases()

func import_legacy_training_mastery(legacy_mastery: Dictionary) -> void:
	for technique_id_value in legacy_mastery.keys():
		var technique_id: String = str(technique_id_value)
		var target: float = maxf(0.0, float(legacy_mastery[technique_id_value]))
		var current: float = get_mastery_points(technique_id)
		if target <= current:
			continue
		record_event(
			"legacy_mastery_import",
			"save_migration",
			0.0,
			{
				"domain": "",
				"domain_xp": 0.0,
				"respect": 0,
				"technique_id": technique_id,
				"mastery_xp": target - current,
				"training": true,
				"skip_achievement_eval": true
			},
			"migration:v6:mastery:%s" % technique_id
		)

func import_legacy_learned_techniques(techniques: Array) -> void:
	var learned_threshold: float = get_mastery_threshold("learned")
	for technique_id_value in techniques:
		var technique_id: String = str(technique_id_value)
		if technique_id == "" or get_mastery_points(technique_id) >= learned_threshold:
			continue
		record_event(
			"legacy_learned_import",
			"save_migration",
			0.0,
			{
				"domain": "",
				"domain_xp": 0.0,
				"respect": 0,
				"technique_id": technique_id,
				"mastery_xp": learned_threshold - get_mastery_points(technique_id),
				"skip_achievement_eval": true
			},
			"migration:v6:learned:%s" % technique_id
		)

func _on_training_completed(training_type, activity_id, result) -> void:
	if typeof(result) != TYPE_DICTIONARY or not bool(result.get("ok", false)):
		return
	var resolved_type: String = str(training_type)
	var resolved_id: String = str(activity_id)
	if resolved_type == "technical":
		var mastery_xp: float = float(result.get("mastery_xp", result.get("xp", 0.0)))
		record_event(
			"technical_training",
			"training",
			float(result.get("progression_xp", maxf(10.0, mastery_xp * 0.5))),
			{
				"technique_id": resolved_id,
				"mastery_xp": mastery_xp,
				"attempted": true,
				"success": true,
				"training": true
			}
		)
	else:
		record_event(
			"physical_training",
			"training",
			float(result.get("progression_xp", 35.0)),
			{"training_id": resolved_id}
		)

func _on_technique_resolved(result) -> void:
	if typeof(result) != TYPE_DICTIONARY:
		return
	var actor_id: String = str(result.get("actor_id", ""))
	if not has_node("/root/WorldState") or actor_id != str(WorldState.player_id):
		return
	var technique_id: String = str(result.get("technique_id", result.get("action_id", "")))
	if technique_id == "":
		return
	if has_node("/root/DataRegistry") and DataRegistry.get_technique(technique_id).is_empty():
		return
	var success: bool = bool(result.get("success", false))
	var mastery_rule: Dictionary = _config.get("technique_combat_mastery", {})
	var mastery_xp: float = float(mastery_rule.get("success" if success else "failure", 3.0 if success else 0.5))
	record_event(
		"technique_attempt",
		"combat",
		2.0 if success else 0.5,
		{
			"technique_id": technique_id,
			"mastery_xp": mastery_xp,
			"attempted": true,
			"success": success
		}
	)

func _on_combat_finished(result) -> void:
	if typeof(result) != TYPE_DICTIONARY or not has_node("/root/WorldState"):
		return
	var won: bool = str(result.get("winner", "")) == str(WorldState.player_id)
	var event_type: String = "combat_win" if won else "combat_loss"
	var rule: Dictionary = _get_event_rule(event_type)
	var xp: float = float(rule.get("domain_xp", 100.0 if won else 40.0))
	var respect_delta: int = int(rule.get("respect", 10 if won else 2))
	if won and bool(result.get("technical", false)):
		var bonus: Dictionary = _config.get("technical_finish_bonus", {})
		xp += float(bonus.get("domain_xp", 25.0))
		respect_delta += int(bonus.get("respect", 5))
	var fight_number: int = int(WorldState.fights_won) + int(WorldState.fights_lost)
	var arena: String = ""
	if has_node("/root/CombatManager"):
		arena = str(CombatManager.arena_id)
	record_event(
		event_type,
		"combat",
		xp,
		{
			"respect": respect_delta,
			"winner": str(result.get("winner", "")),
			"method": str(result.get("method", "")),
			"technical": bool(result.get("technical", false)),
			"arena_id": arena,
			"discovery_id": "arena:%s" % arena if arena != "" else ""
		},
		"combat:%04d:%s:%s" % [fight_number, str(result.get("winner", "")), str(result.get("method", ""))]
	)

func _on_mission_completed(mission_id) -> void:
	var resolved_id: String = str(mission_id)
	if resolved_id == "":
		return
	record_event(
		"mission_complete",
		"story",
		0.0,
		{"mission_id": resolved_id, "discovery_id": "mission:%s" % resolved_id},
		"mission:%s:complete" % resolved_id
	)

func _on_world_travel_completed(hub_id, first_visit, travel_entry) -> void:
	var resolved_hub: String = str(hub_id)
	if resolved_hub == "":
		return
	var is_first: bool = bool(first_visit)
	var event_type: String = "travel_first_visit" if is_first else "travel_repeat"
	var stable_id: String = "travel:first:%s" % resolved_hub if is_first else ""
	var travel_context: Dictionary = travel_entry.duplicate(true) if typeof(travel_entry) == TYPE_DICTIONARY else {}
	record_event(
		event_type,
		"exploration",
		0.0,
		{
			"hub_id": resolved_hub,
			"first_visit": is_first,
			"travel": travel_context,
			"discovery_id": "hub:%s" % resolved_hub
		},
		stable_id
	)

func _evaluate_achievements() -> void:
	for achievement_value in _config.get("achievements", []):
		if typeof(achievement_value) != TYPE_DICTIONARY:
			continue
		var achievement: Dictionary = achievement_value
		var achievement_id: String = str(achievement.get("id", ""))
		if achievement_id == "" or achievements.has(achievement_id):
			continue
		var metric: String = str(achievement.get("metric", ""))
		var op: String = str(achievement.get("op", ">="))
		var target: float = float(achievement.get("value", 0.0))
		if not _compare(_metric_value(metric), op, target):
			continue
		var reward: Dictionary = achievement.get("reward", {}).duplicate(true)
		record_event(
			"achievement_unlocked",
			"progression",
			0.0,
			{
				"domain": "",
				"domain_xp": 0.0,
				"respect": int(reward.get("respect", 0)),
				"skill_points_delta": int(reward.get("skill_points", 0)),
				"achievement_id": achievement_id,
				"reward": reward,
				"skip_achievement_eval": true
			},
			"achievement:%s" % achievement_id
		)

func _metric_value(metric: String) -> float:
	if metric.begins_with("domain."):
		return get_domain_xp(metric.trim_prefix("domain."))
	match metric:
		"respect":
			return float(respect)
		"fights_won":
			return float(WorldState.fights_won) if has_node("/root/WorldState") else 0.0
		"learned_techniques":
			return float(WorldState.techniques_learned.size()) if has_node("/root/WorldState") else 0.0
		"completed_missions":
			return float(WorldState.completed_missions.size()) if has_node("/root/WorldState") else 0.0
		"visited_hubs":
			return float(WorldMapManager.visited_hubs.size()) if has_node("/root/WorldMapManager") else 0.0
		"mastered_techniques":
			return float(_count_stage_at_least("mastered"))
		"signature_techniques":
			return float(_count_stage_at_least("signature"))
	return float(counters.get(metric, 0))

func _count_stage_at_least(stage: String) -> int:
	var target: int = _stage_index(stage)
	var total: int = 0
	for entry_value in mastery.values():
		if typeof(entry_value) == TYPE_DICTIONARY and _stage_index(str(entry_value.get("stage", "discovered"))) >= target:
			total += 1
	return total

func _compare(value: float, op: String, target: float) -> bool:
	match op:
		">=":
			return value >= target
		">":
			return value > target
		"<=":
			return value <= target
		"<":
			return value < target
		"==":
			return is_equal_approx(value, target)
	return false

func _emit_progression_changed() -> void:
	if not _replaying and SignalBus.has_signal("progression_changed"):
		SignalBus.progression_changed.emit(get_snapshot())
