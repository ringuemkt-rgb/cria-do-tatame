extends Node

signal faction_week_completed(snapshot: Dictionary)
signal operation_started(operation: Dictionary)
signal operation_resolved(operation: Dictionary)
signal conflict_changed(conflict: Dictionary)
signal territory_changed(territory_id: String, territory: Dictionary)
signal leadership_changed(faction_id: String, old_leader: String, new_leader: String)
signal regional_pressure_changed(level: int, axes: Dictionary)
signal player_debt_changed(debt: Dictionary)

const FACTION_CONFIG_PATH := "res://data/factions/faction_director_v02.json"
const OPERATIONS_PATH := "res://data/factions/faction_operations_v02.json"
const TERRITORIES_PATH := "res://data/world/faction_territories_v02.json"

var config: Dictionary = {}
var operations_data: Dictionary = {}
var territories_data: Dictionary = {}
var state: Dictionary = {}

var _power_dimensions: Array = [
	"territorio",
	"caixa",
	"influencia",
	"medo",
	"inteligencia",
	"coesao",
	"forca_marcial"
]
var _conflict_stages: Array = [
	"desconfianca",
	"vigilancia",
	"provocacao",
	"disputa_indireta",
	"retaliacao",
	"guerra_aberta",
	"tregua",
	"reorganizacao"
]
var _pressure_axes: Array = [
	"atencao_publica",
	"vigilancia_faccoes",
	"desconfianca_comunitaria",
	"interesse_autoridades",
	"exposicao_digital"
]

func _ready() -> void:
	_load_definitions()
	reset_director()
	if SignalBus.has_signal("week_completed") and not SignalBus.week_completed.is_connected(_on_week_completed):
		SignalBus.week_completed.connect(_on_week_completed)
	if SignalBus.has_signal("day_advanced") and not SignalBus.day_advanced.is_connected(_on_day_advanced):
		SignalBus.day_advanced.connect(_on_day_advanced)
	if SignalBus.has_signal("combat_finished") and not SignalBus.combat_finished.is_connected(_on_combat_finished):
		SignalBus.combat_finished.connect(_on_combat_finished)

func _load_definitions() -> void:
	config = _load_json(FACTION_CONFIG_PATH)
	operations_data = _load_json(OPERATIONS_PATH)
	territories_data = _load_json(TERRITORIES_PATH)
	_power_dimensions = config.get("power_dimensions", _power_dimensions)
	_conflict_stages = config.get("conflict_stages", _conflict_stages)
	_pressure_axes = config.get("pressure_axes", _pressure_axes)

func reset_director() -> void:
	state = {
		"version": 2,
		"week": int(WorldState.week),
		"factions": {},
		"territories": {},
		"conflicts": {},
		"active_operations": [],
		"operation_history": [],
		"memories": [],
		"debts": [],
		"pressure": {},
		"pressure_level": 0,
		"champions": {},
		"pending_hooks": [],
		"player_action_counter": 0
	}
	_initialize_factions()
	_initialize_territories()
	_initialize_conflicts()
	_initialize_pressure()
	_initialize_champions()
	_update_all_power_tiers()

func _initialize_factions() -> void:
	var faction_states: Dictionary = {}
	var definitions: Dictionary = config.get("factions", {})
	var faction_ids: Array = definitions.keys()
	faction_ids.sort()
	for faction_id_value in faction_ids:
		var faction_id := str(faction_id_value)
		var definition: Dictionary = definitions[faction_id]
		var power: Dictionary = {}
		for dimension_value in _power_dimensions:
			var dimension := str(dimension_value)
			power[dimension] = clamp(float(definition.get("initial_power", {}).get(dimension, 0.0)), 0.0, 100.0)
		faction_states[faction_id] = {
			"id": faction_id,
			"name": str(definition.get("name", faction_id)),
			"leader": str(definition.get("leader", "")),
			"leader_status": "active",
			"hierarchy": definition.get("hierarchy", {}).duplicate(true),
			"succession_candidates": definition.get("succession_candidates", []).duplicate(true),
			"power": power,
			"power_tier": "presenca_local",
			"desire": str(definition.get("desire", "")),
			"fear": str(definition.get("fear", "")),
			"taboo": str(definition.get("taboo", "")),
			"public_face": str(definition.get("public_face", "")),
			"hidden_face": str(definition.get("hidden_face", "")),
			"combat_doctrine": definition.get("combat_doctrine", {}).duplicate(true),
			"operation_weights": definition.get("operation_weights", {}).duplicate(true),
			"preferred_debts": definition.get("preferred_debts", []).duplicate(true),
			"current_operation": "",
			"crisis": 0.0,
			"victories": 0,
			"defeats": 0,
			"player_relation": FactionManager.get_relation(faction_id) if has_node("/root/FactionManager") else 0.0,
			"player_heat": FactionManager.get_heat(faction_id) if has_node("/root/FactionManager") else 0.0
		}
	state["factions"] = faction_states

func _initialize_territories() -> void:
	var territory_states: Dictionary = {}
	var definitions: Dictionary = territories_data.get("territories", {})
	var territory_ids: Array = definitions.keys()
	territory_ids.sort()
	for territory_id_value in territory_ids:
		var territory_id := str(territory_id_value)
		var territory: Dictionary = definitions[territory_id].duplicate(true)
		var owner := str(territory.get("owner", "neutral"))
		var influence: Dictionary = {}
		if owner != "neutral":
			influence[owner] = float(territory.get("control", 50.0))
		for challenger_value in territory.get("challengers", []):
			var challenger := str(challenger_value)
			if not influence.has(challenger):
				influence[challenger] = 12.0
		territory["influence_by_faction"] = influence
		territory["last_changed_week"] = int(WorldState.week)
		territory_states[territory_id] = territory
	state["territories"] = territory_states

func _initialize_conflicts() -> void:
	var conflicts: Dictionary = {}
	for rivalry_value in territories_data.get("initial_rivalries", []):
		if typeof(rivalry_value) != TYPE_DICTIONARY:
			continue
		var rivalry: Dictionary = rivalry_value
		var a := str(rivalry.get("a", ""))
		var b := str(rivalry.get("b", ""))
		if a == "" or b == "" or a == b:
			continue
		var key := _conflict_key(a, b)
		conflicts[key] = {
			"id": key,
			"a": min(a, b),
			"b": max(a, b),
			"stage": str(rivalry.get("stage", "desconfianca")),
			"intensity": clamp(float(rivalry.get("intensity", 0.0)), 0.0, 100.0),
			"history": []
		}
	state["conflicts"] = conflicts

func _initialize_pressure() -> void:
	var pressure: Dictionary = {}
	for axis_value in _pressure_axes:
		pressure[str(axis_value)] = 0.0
	state["pressure"] = pressure
	state["pressure_level"] = 0

func _initialize_champions() -> void:
	var champions: Dictionary = {}
	for faction_id_value in state.get("factions", {}).keys():
		var faction_id := str(faction_id_value)
		var faction: Dictionary = state["factions"][faction_id]
		var hierarchy: Dictionary = faction.get("hierarchy", {})
		var fighter_id := str(hierarchy.get("combat_master", faction.get("leader", "")))
		var martial_power := float(faction.get("power", {}).get("forca_marcial", 40.0))
		champions[faction_id] = {
			"fighter_id": fighter_id,
			"level": max(1.0, martial_power / 10.0),
			"adaptation": 0.0,
			"morale": 70.0,
			"injury_risk": 0.0,
			"specialization": str(faction.get("combat_doctrine", {}).get("id", "adaptativo")),
			"weeks_trained": 0
		}
	state["champions"] = champions

func _on_week_completed(_week_number) -> void:
	advance_faction_week(int(WorldState.week))

func _on_day_advanced(_day_name, _week_number) -> void:
	_decay_regional_pressure()
	_sync_legacy_relations()

func _on_combat_finished(result) -> void:
	if typeof(result) != TYPE_DICTIONARY:
		return
	var opponent_id := str(result.get("opponent_id", result.get("rival_id", "")))
	var winner_id := str(result.get("winner", result.get("winner_id", "")))
	for faction_id_value in state.get("champions", {}).keys():
		var faction_id := str(faction_id_value)
		var champion: Dictionary = state["champions"][faction_id]
		if str(champion.get("fighter_id", "")) != opponent_id:
			continue
		var faction: Dictionary = state["factions"].get(faction_id, {})
		if winner_id == WorldState.player_id or winner_id == "ruan_macacao":
			faction["defeats"] = int(faction.get("defeats", 0)) + 1
			champion["morale"] = clamp(float(champion.get("morale", 70.0)) - 8.0, 0.0, 100.0)
			champion["adaptation"] = clamp(float(champion.get("adaptation", 0.0)) + 4.0, 0.0, 100.0)
			adjust_power(faction_id, "coesao", -2.0, "champion_defeat")
		else:
			faction["victories"] = int(faction.get("victories", 0)) + 1
			champion["morale"] = clamp(float(champion.get("morale", 70.0)) + 5.0, 0.0, 100.0)
			adjust_power(faction_id, "influencia", 2.0, "champion_victory")
		state["factions"][faction_id] = faction
		state["champions"][faction_id] = champion
		record_memory(faction_id, "combat_result", {
			"opponent_id": opponent_id,
			"winner_id": winner_id,
			"method": str(result.get("method", result.get("finish", "")))
		})

func advance_faction_week(week_number: int = -1) -> Dictionary:
	var resolved_week := week_number if week_number > 0 else int(WorldState.week)
	state["week"] = resolved_week
	_resolve_or_advance_operations()
	var faction_ids: Array = state.get("factions", {}).keys()
	faction_ids.sort()
	for faction_id_value in faction_ids:
		var faction_id := str(faction_id_value)
		if not _has_active_operation(faction_id):
			var operation := _select_operation(faction_id)
			if not operation.is_empty():
				_start_operation(operation)
	_develop_champions()
	_check_all_successions()
	_update_all_power_tiers()
	_recalculate_pressure_level()
	_sync_legacy_relations()
	var snapshot := get_snapshot()
	faction_week_completed.emit(snapshot)
	if SignalBus.has_signal("faction_week_completed"):
		SignalBus.faction_week_completed.emit(snapshot)
	return snapshot

func _select_operation(faction_id: String) -> Dictionary:
	var faction: Dictionary = state.get("factions", {}).get(faction_id, {})
	if faction.is_empty() or str(faction.get("power_tier", "")) == "colapso":
		return {}
	var weights: Dictionary = faction.get("operation_weights", {})
	var candidates: Array = []
	for template_value in operations_data.get("operations", []):
		if typeof(template_value) != TYPE_DICTIONARY:
			continue
		var template: Dictionary = template_value
		var category := str(template.get("category", ""))
		var base_weight := float(weights.get(category, 0.0))
		if base_weight <= 0.0 or not _meets_minimum_power(faction, template.get("minimum_power", {})):
			continue
		var target := _resolve_operation_target(faction_id, template)
		if target.is_empty() and str(template.get("target_type", "self")) != "self":
			continue
		var score := base_weight * _operation_urgency(faction, category)
		score *= _rng_for("operation|%s|%s" % [faction_id, category]).randf_range(0.8, 1.2)
		candidates.append({"template": template, "target": target, "score": score})
	if candidates.is_empty():
		return {}
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.get("score", 0.0)) > float(b.get("score", 0.0)))
	var selected: Dictionary = candidates[0]
	var operation: Dictionary = selected.get("template", {}).duplicate(true)
	operation["actor_faction"] = faction_id
	operation["target_faction"] = str(selected.get("target", {}).get("target_faction", ""))
	operation["territory_id"] = str(selected.get("target", {}).get("territory_id", ""))
	return operation

func _resolve_operation_target(faction_id: String, template: Dictionary) -> Dictionary:
	var target_type := str(template.get("target_type", "self"))
	match target_type:
		"self":
			return {"target_faction": faction_id}
		"rival_faction", "hostile_faction":
			var rival := _select_rival_faction(faction_id, target_type == "hostile_faction")
			return {"target_faction": rival} if rival != "" else {}
		"owned_territory":
			var owned := _territories_owned_by(faction_id)
			return {"territory_id": str(owned[0])} if not owned.is_empty() else {}
		"neutral_territory":
			var neutral := _territories_by_condition(func(item: Dictionary) -> bool: return str(item.get("owner", "neutral")) == "neutral" or item.get("challengers", []).has(faction_id))
			return {"territory_id": str(neutral[0])} if not neutral.is_empty() else {}
		"contested_territory":
			var contested := _territories_by_condition(func(item: Dictionary) -> bool: return str(item.get("owner", "neutral")) != faction_id and item.get("challengers", []).has(faction_id))
			return {"territory_id": str(contested[0])} if not contested.is_empty() else {}
		"event_territory":
			var event_territories := _territories_by_condition(func(item: Dictionary) -> bool: return "evento" in item.get("event_tags", []) or "torneio" in item.get("event_tags", []) or "midia" in item.get("event_tags", []))
			return {"territory_id": str(event_territories[0])} if not event_territories.is_empty() else {}
	return {}

func _start_operation(operation: Dictionary) -> void:
	var runtime := {
		"runtime_id": "%s_%s_w%s" % [str(operation.get("actor_faction", "faction")), str(operation.get("id", "operation")), int(state.get("week", 1))],
		"id": str(operation.get("id", "")),
		"category": str(operation.get("category", "")),
		"actor_faction": str(operation.get("actor_faction", "")),
		"target_faction": str(operation.get("target_faction", "")),
		"territory_id": str(operation.get("territory_id", "")),
		"weeks_remaining": max(1, int(operation.get("duration_weeks", 1))),
		"started_week": int(state.get("week", 1)),
		"template": operation.duplicate(true),
		"status": "active"
	}
	var active: Array = state.get("active_operations", [])
	active.append(runtime)
	state["active_operations"] = active
	var faction_id := str(runtime.get("actor_faction", ""))
	var faction: Dictionary = state["factions"].get(faction_id, {})
	faction["current_operation"] = str(runtime.get("id", ""))
	state["factions"][faction_id] = faction
	record_memory(faction_id, "operation_started", runtime)
	operation_started.emit(runtime)
	if SignalBus.has_signal("faction_operation_started"):
		SignalBus.faction_operation_started.emit(runtime)
	_publish_operation_post(runtime, false)

func _resolve_or_advance_operations() -> void:
	var remaining: Array = []
	for operation_value in state.get("active_operations", []):
		var operation: Dictionary = operation_value.duplicate(true)
		operation["weeks_remaining"] = int(operation.get("weeks_remaining", 1)) - 1
		if int(operation.get("weeks_remaining", 0)) <= 0:
			_resolve_operation(operation)
		else:
			remaining.append(operation)
	state["active_operations"] = remaining

func _resolve_operation(operation: Dictionary) -> void:
	var template: Dictionary = operation.get("template", {})
	var actor := str(operation.get("actor_faction", ""))
	var target := str(operation.get("target_faction", ""))
	var territory_id := str(operation.get("territory_id", ""))
	_apply_power_effects(actor, template.get("self_effects", {}), str(operation.get("id", "")))
	if target != "" and target != actor:
		_apply_power_effects(target, template.get("target_effects", {}), "targeted_by_%s" % actor)
		_adjust_conflict(actor, target, float(template.get("conflict_delta", 0.0)), str(operation.get("id", "")))
	if territory_id != "":
		_apply_territory_effects(territory_id, actor, template.get("territory_effects", {}), str(operation.get("category", "")))
	_apply_pressure_effects(template.get("pressure_effects", {}))
	_apply_champion_effects(actor, template.get("champion_effects", {}))
	var completed := operation.duplicate(true)
	completed["status"] = "resolved"
	completed["resolved_week"] = int(state.get("week", 1))
	var history: Array = state.get("operation_history", [])
	history.append(completed)
	while history.size() > 48:
		history.pop_front()
	state["operation_history"] = history
	var faction: Dictionary = state["factions"].get(actor, {})
	faction["current_operation"] = ""
	state["factions"][actor] = faction
	record_memory(actor, "operation_resolved", completed)
	operation_resolved.emit(completed)
	if SignalBus.has_signal("faction_operation_resolved"):
		SignalBus.faction_operation_resolved.emit(completed)
	_publish_operation_post(completed, true)

func _apply_power_effects(faction_id: String, effects: Dictionary, reason: String) -> void:
	for dimension_value in effects.keys():
		adjust_power(faction_id, str(dimension_value), float(effects[dimension_value]), reason)

func adjust_power(faction_id: String, dimension: String, delta: float, reason := "system") -> float:
	if not state.get("factions", {}).has(faction_id) or not _power_dimensions.has(dimension):
		return 0.0
	var faction: Dictionary = state["factions"][faction_id]
	var power: Dictionary = faction.get("power", {})
	var old_value := float(power.get(dimension, 0.0))
	var new_value := clamp(old_value + delta, 0.0, 100.0)
	power[dimension] = new_value
	faction["power"] = power
	if dimension == "coesao" and new_value < 35.0:
		faction["crisis"] = clamp(float(faction.get("crisis", 0.0)) + abs(delta) + 4.0, 0.0, 100.0)
	state["factions"][faction_id] = faction
	if SignalBus.has_signal("faction_power_changed"):
		SignalBus.faction_power_changed.emit(faction_id, dimension, delta, new_value, reason)
	return new_value

func _apply_territory_effects(territory_id: String, actor: String, effects: Dictionary, category: String) -> void:
	if not state.get("territories", {}).has(territory_id):
		return
	var territory: Dictionary = state["territories"][territory_id]
	for key_value in effects.keys():
		var key := str(key_value)
		var delta := float(effects[key_value])
		match key:
			"controle": territory["control"] = clamp(float(territory.get("control", 50.0)) + delta, 0.0, 100.0)
			"apoio_popular": territory["apoio_popular"] = clamp(float(territory.get("apoio_popular", 50.0)) + delta, 0.0, 100.0)
			"seguranca": territory["seguranca"] = clamp(float(territory.get("seguranca", 50.0)) + delta, 0.0, 100.0)
			"renda": territory["renda"] = clamp(float(territory.get("renda", 50.0)) + delta, 0.0, 100.0)
			"influencia_desafiante":
				var influence: Dictionary = territory.get("influence_by_faction", {})
				influence[actor] = clamp(float(influence.get(actor, 0.0)) + delta, 0.0, 100.0)
				territory["influence_by_faction"] = influence
	if category == "expandir_territorio":
		_try_transfer_territory(territory_id, actor, territory)
	territory["last_changed_week"] = int(state.get("week", 1))
	state["territories"][territory_id] = territory
	territory_changed.emit(territory_id, territory)
	if SignalBus.has_signal("faction_territory_changed"):
		SignalBus.faction_territory_changed.emit(territory_id, territory)

func _try_transfer_territory(territory_id: String, actor: String, territory: Dictionary) -> void:
	var old_owner := str(territory.get("owner", "neutral"))
	if old_owner == actor:
		return
	var influence: Dictionary = territory.get("influence_by_faction", {})
	var actor_influence := float(influence.get(actor, 0.0))
	var owner_influence := float(influence.get(old_owner, territory.get("control", 50.0)))
	if actor_influence < 60.0 or actor_influence < owner_influence + 8.0:
		return
	territory["owner"] = actor
	territory["control"] = clamp(actor_influence, 45.0, 82.0)
	influence[actor] = float(territory["control"])
	if old_owner != "neutral":
		influence[old_owner] = clamp(owner_influence - 15.0, 0.0, 100.0)
		adjust_power(old_owner, "territorio", -5.0, "territory_lost")
		_adjust_conflict(actor, old_owner, 12.0, "territory_transfer")
	adjust_power(actor, "territorio", 6.0, "territory_gained")
	territory["influence_by_faction"] = influence
	record_memory(actor, "territory_gained", {"territory_id": territory_id, "old_owner": old_owner})

func _apply_pressure_effects(effects: Dictionary) -> void:
	var pressure: Dictionary = state.get("pressure", {})
	for axis_value in effects.keys():
		var axis := str(axis_value)
		if _pressure_axes.has(axis):
			pressure[axis] = clamp(float(pressure.get(axis, 0.0)) + float(effects[axis_value]), 0.0, 100.0)
	state["pressure"] = pressure
	_recalculate_pressure_level()

func _decay_regional_pressure() -> void:
	var pressure: Dictionary = state.get("pressure", {})
	for axis_value in _pressure_axes:
		var axis := str(axis_value)
		var decay := 0.8 if axis != "desconfianca_comunitaria" else 0.45
		pressure[axis] = max(0.0, float(pressure.get(axis, 0.0)) - decay)
	state["pressure"] = pressure
	_recalculate_pressure_level()

func _recalculate_pressure_level() -> void:
	var pressure: Dictionary = state.get("pressure", {})
	var peak := 0.0
	var total := 0.0
	for axis_value in _pressure_axes:
		var value := float(pressure.get(str(axis_value), 0.0))
		peak = max(peak, value)
		total += value
	var average := total / max(1.0, float(_pressure_axes.size()))
	var score := peak * 0.7 + average * 0.3
	var level := 0
	if score >= 80.0:
		level = 5
	elif score >= 60.0:
		level = 4
	elif score >= 40.0:
		level = 3
	elif score >= 25.0:
		level = 2
	elif score >= 10.0:
		level = 1
	var changed := level != int(state.get("pressure_level", 0))
	state["pressure_level"] = level
	if changed:
		regional_pressure_changed.emit(level, pressure)
		if SignalBus.has_signal("regional_pressure_changed"):
			SignalBus.regional_pressure_changed.emit(level, pressure)

func _adjust_conflict(a: String, b: String, delta: float, reason: String) -> void:
	if a == "" or b == "" or a == b:
		return
	var key := _conflict_key(a, b)
	var conflicts: Dictionary = state.get("conflicts", {})
	var conflict: Dictionary = conflicts.get(key, {
		"id": key,
		"a": min(a, b),
		"b": max(a, b),
		"stage": "desconfianca",
		"intensity": 0.0,
		"history": []
	})
	var old_stage := str(conflict.get("stage", "desconfianca"))
	var intensity := clamp(float(conflict.get("intensity", 0.0)) + delta, 0.0, 100.0)
	conflict["intensity"] = intensity
	conflict["stage"] = _stage_for_intensity(intensity, old_stage, delta)
	var history: Array = conflict.get("history", [])
	history.append({"week": int(state.get("week", 1)), "delta": delta, "reason": reason, "stage": conflict["stage"]})
	while history.size() > 12:
		history.pop_front()
	conflict["history"] = history
	conflicts[key] = conflict
	state["conflicts"] = conflicts
	conflict_changed.emit(conflict)
	if SignalBus.has_signal("faction_conflict_changed"):
		SignalBus.faction_conflict_changed.emit(conflict)

func _stage_for_intensity(intensity: float, old_stage: String, delta: float) -> String:
	if delta < 0.0 and old_stage == "guerra_aberta" and intensity < 75.0:
		return "tregua"
	if old_stage == "tregua" and intensity < 25.0:
		return "reorganizacao"
	if intensity >= 75.0:
		return "guerra_aberta"
	if intensity >= 60.0:
		return "retaliacao"
	if intensity >= 45.0:
		return "disputa_indireta"
	if intensity >= 30.0:
		return "provocacao"
	if intensity >= 15.0:
		return "vigilancia"
	return "desconfianca"

func _develop_champions() -> void:
	for faction_id_value in state.get("champions", {}).keys():
		var faction_id := str(faction_id_value)
		var champion: Dictionary = state["champions"][faction_id]
		var faction: Dictionary = state["factions"].get(faction_id, {})
		var martial_power := float(faction.get("power", {}).get("forca_marcial", 40.0))
		champion["weeks_trained"] = int(champion.get("weeks_trained", 0)) + 1
		champion["level"] = clamp(float(champion.get("level", 1.0)) + martial_power / 500.0, 1.0, 15.0)
		champion["adaptation"] = clamp(float(champion.get("adaptation", 0.0)) + float(faction.get("defeats", 0)) * 0.25, 0.0, 100.0)
		champion["morale"] = clamp(float(champion.get("morale", 70.0)) + (float(faction.get("power", {}).get("coesao", 50.0)) - 50.0) / 50.0, 0.0, 100.0)
		state["champions"][faction_id] = champion

func _apply_champion_effects(faction_id: String, effects: Dictionary) -> void:
	if not state.get("champions", {}).has(faction_id):
		return
	var champion: Dictionary = state["champions"][faction_id]
	for key_value in effects.keys():
		var key := str(key_value)
		champion[key] = clamp(float(champion.get(key, 0.0)) + float(effects[key_value]), 0.0, 100.0)
	state["champions"][faction_id] = champion

func _check_all_successions() -> void:
	for faction_id_value in state.get("factions", {}).keys():
		_check_succession(str(faction_id_value))

func _check_succession(faction_id: String) -> void:
	var faction: Dictionary = state["factions"].get(faction_id, {})
	var cohesion := float(faction.get("power", {}).get("coesao", 50.0))
	var crisis := float(faction.get("crisis", 0.0))
	var leader_status := str(faction.get("leader_status", "active"))
	if cohesion >= 30.0 and crisis < 70.0 and leader_status == "active":
		return
	var candidates: Array = faction.get("succession_candidates", [])
	if candidates.is_empty():
		return
	var selected: Dictionary = {}
	var best_score := -1.0
	for candidate_value in candidates:
		if typeof(candidate_value) != TYPE_DICTIONARY:
			continue
		var candidate: Dictionary = candidate_value
		var ambition := float(candidate.get("ambition", 0.5))
		var loyalty := float(candidate.get("loyalty", 0.5))
		var score := ambition * 0.7 + loyalty * 0.3 + _rng_for("succession|%s|%s" % [faction_id, candidate.get("id", "")]).randf_range(0.0, 0.15)
		if score > best_score:
			best_score = score
			selected = candidate
	if selected.is_empty():
		return
	var old_leader := str(faction.get("leader", ""))
	var new_leader := str(selected.get("id", ""))
	if new_leader == "" or new_leader == old_leader:
		return
	faction["leader"] = new_leader
	faction["leader_status"] = "active"
	faction["crisis"] = max(0.0, crisis - 35.0)
	var power: Dictionary = faction.get("power", {})
	power["coesao"] = clamp(float(power.get("coesao", 30.0)) + 15.0, 0.0, 100.0)
	faction["power"] = power
	state["factions"][faction_id] = faction
	record_memory(faction_id, "leadership_changed", {"old_leader": old_leader, "new_leader": new_leader, "style": selected.get("leadership_style", "")})
	leadership_changed.emit(faction_id, old_leader, new_leader)
	if SignalBus.has_signal("faction_leadership_changed"):
		SignalBus.faction_leadership_changed.emit(faction_id, old_leader, new_leader)

func register_player_action(faction_id: String, action_id: String, relation_delta := 0.0, heat_delta := 0.0, context: Dictionary = {}) -> Dictionary:
	state["player_action_counter"] = int(state.get("player_action_counter", 0)) + 1
	var memory := {
		"id": "player_action_%s" % int(state["player_action_counter"]),
		"type": "player_action",
		"faction_id": faction_id,
		"action_id": action_id.left(64),
		"week": int(WorldState.week),
		"day": str(WorldState.current_day),
		"territory_id": str(context.get("territory_id", WorldState.current_hub)),
		"witnesses": context.get("witnesses", []).slice(0, 8),
		"impact": context.get("impact", {}).duplicate(true)
	}
	if has_node("/root/FactionManager"):
		FactionManager.apply_relation_delta(faction_id, float(relation_delta), action_id)
		FactionManager.apply_heat_delta(faction_id, float(heat_delta), action_id)
	for dimension_value in context.get("power_effects", {}).keys():
		adjust_power(faction_id, str(dimension_value), float(context["power_effects"][dimension_value]), action_id)
	_apply_pressure_effects(context.get("pressure_effects", {}))
	_append_memory(memory)
	if SignalBus.has_signal("faction_memory_recorded"):
		SignalBus.faction_memory_recorded.emit(memory)
	return memory

func add_debt(faction_id: String, debt_type: String, value: float, creditor_id: String, due_week := -1, note := "") -> Dictionary:
	var debt := {
		"id": "debt_%s_%s" % [faction_id, state.get("debts", []).size()],
		"faction_id": faction_id,
		"type": debt_type.left(32),
		"value": max(0.0, value),
		"creditor_id": creditor_id.left(64),
		"created_week": int(WorldState.week),
		"due_week": due_week,
		"note": note.left(160),
		"status": "active"
	}
	var debts: Array = state.get("debts", [])
	debts.append(debt)
	state["debts"] = debts
	player_debt_changed.emit(debt)
	if SignalBus.has_signal("faction_debt_changed"):
		SignalBus.faction_debt_changed.emit(debt)
	return debt

func settle_debt(debt_id: String, outcome := "paid") -> bool:
	var debts: Array = state.get("debts", [])
	for index in range(debts.size()):
		if str(debts[index].get("id", "")) != debt_id:
			continue
		debts[index]["status"] = outcome.left(32)
		debts[index]["settled_week"] = int(WorldState.week)
		state["debts"] = debts
		player_debt_changed.emit(debts[index])
		return true
	return false

func violate_taboo(faction_id: String, context: Dictionary = {}) -> void:
	adjust_power(faction_id, "coesao", -8.0, "taboo_violated")
	adjust_power(faction_id, "influencia", -5.0, "taboo_violated")
	var faction: Dictionary = state["factions"].get(faction_id, {})
	faction["crisis"] = clamp(float(faction.get("crisis", 0.0)) + 18.0, 0.0, 100.0)
	state["factions"][faction_id] = faction
	record_memory(faction_id, "taboo_violated", context)
	_apply_pressure_effects({"atencao_publica": 6, "desconfianca_comunitaria": 8, "exposicao_digital": 5})

func apply_external_pressure(pressure_by_faction: Dictionary) -> void:
	for faction_id_value in pressure_by_faction.keys():
		var faction_id := str(faction_id_value)
		if not state.get("factions", {}).has(faction_id):
			continue
		var delta := clamp(float(pressure_by_faction[faction_id_value]), -3.0, 3.0)
		if has_node("/root/FactionManager"):
			FactionManager.apply_heat_delta(faction_id, max(0.0, delta), "world_ai")
		adjust_power(faction_id, "medo", delta * 0.5, "world_ai")

func record_memory(faction_id: String, memory_type: String, payload: Dictionary = {}) -> Dictionary:
	var memory := {
		"id": "memory_%s" % state.get("memories", []).size(),
		"type": memory_type,
		"faction_id": faction_id,
		"week": int(state.get("week", WorldState.week)),
		"day": str(WorldState.current_day),
		"payload": payload.duplicate(true)
	}
	_append_memory(memory)
	return memory

func _append_memory(memory: Dictionary) -> void:
	var memories: Array = state.get("memories", [])
	memories.append(memory)
	while memories.size() > 96:
		memories.pop_front()
	state["memories"] = memories

func _publish_operation_post(operation: Dictionary, resolved: bool) -> void:
	if not has_node("/root/CriaLiveManager") or not CriaLiveManager.has_method("create_faction_post"):
		return
	var template: Dictionary = operation.get("template", {})
	var text_key := "hidden_message" if str(operation.get("actor_faction", "")) == "fantasma" else "public_message"
	var text := str(template.get(text_key, "Movimento de facção registrado."))
	var metrics: Dictionary = template.get("cria_live", {}).duplicate(true)
	metrics["resolved"] = resolved
	CriaLiveManager.create_faction_post(str(operation.get("actor_faction", "")), text, str(template.get("category", "faction")), metrics)

func _sync_legacy_relations() -> void:
	if not has_node("/root/FactionManager"):
		return
	for faction_id_value in state.get("factions", {}).keys():
		var faction_id := str(faction_id_value)
		var faction: Dictionary = state["factions"][faction_id]
		faction["player_relation"] = FactionManager.get_relation(faction_id)
		faction["player_heat"] = FactionManager.get_heat(faction_id)
		state["factions"][faction_id] = faction

func _update_all_power_tiers() -> void:
	for faction_id_value in state.get("factions", {}).keys():
		var faction_id := str(faction_id_value)
		var faction: Dictionary = state["factions"][faction_id]
		var average := _average_power(faction.get("power", {}))
		faction["power_score"] = average
		faction["power_tier"] = _tier_for_power(average)
		state["factions"][faction_id] = faction

func _average_power(power: Dictionary) -> float:
	var total := 0.0
	for dimension_value in _power_dimensions:
		total += float(power.get(str(dimension_value), 0.0))
	return total / max(1.0, float(_power_dimensions.size()))

func _tier_for_power(value: float) -> String:
	for tier_value in config.get("power_tiers", []):
		if value >= float(tier_value.get("min", 0.0)) and value <= float(tier_value.get("max", 100.0)):
			return str(tier_value.get("id", "presenca_local"))
	return "hegemonia" if value > 80.0 else "colapso"

func _meets_minimum_power(faction: Dictionary, requirements: Dictionary) -> bool:
	var power: Dictionary = faction.get("power", {})
	for dimension_value in requirements.keys():
		if float(power.get(str(dimension_value), 0.0)) < float(requirements[dimension_value]):
			return false
	return true

func _operation_urgency(faction: Dictionary, category: String) -> float:
	var power: Dictionary = faction.get("power", {})
	var urgency := 1.0
	if float(power.get("coesao", 50.0)) < 35.0 and category in ["proteger_comunidade", "negociar_tregua", "encobrir_crise"]:
		urgency += 0.7
	if float(power.get("caixa", 50.0)) < 30.0 and category in ["controlar_evento", "campanha_publica"]:
		urgency += 0.35
	if float(power.get("inteligencia", 50.0)) > 75.0 and category in ["investigar", "infiltrar"]:
		urgency += 0.4
	if float(faction.get("crisis", 0.0)) > 60.0 and category == "encobrir_crise":
		urgency += 1.0
	return urgency

func _select_rival_faction(faction_id: String, hostile_only: bool) -> String:
	var candidates: Array = []
	for other_id_value in state.get("factions", {}).keys():
		var other_id := str(other_id_value)
		if other_id == faction_id:
			continue
		var conflict := get_conflict(faction_id, other_id)
		var intensity := float(conflict.get("intensity", 0.0))
		if hostile_only and intensity < 45.0:
			continue
		candidates.append({"id": other_id, "score": intensity + _rng_for("rival|%s|%s" % [faction_id, other_id]).randf_range(0.0, 10.0)})
	if candidates.is_empty():
		return ""
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.get("score", 0.0)) > float(b.get("score", 0.0)))
	return str(candidates[0].get("id", ""))

func _territories_owned_by(faction_id: String) -> Array:
	return _territories_by_condition(func(item: Dictionary) -> bool: return str(item.get("owner", "neutral")) == faction_id)

func _territories_by_condition(predicate: Callable) -> Array:
	var matches: Array = []
	var territories: Dictionary = state.get("territories", {})
	var ids: Array = territories.keys()
	ids.sort()
	for territory_id_value in ids:
		var territory_id := str(territory_id_value)
		if predicate.call(territories[territory_id]):
			matches.append(territory_id)
	return matches

func _has_active_operation(faction_id: String) -> bool:
	for operation_value in state.get("active_operations", []):
		if str(operation_value.get("actor_faction", "")) == faction_id:
			return true
	return false

func _conflict_key(a: String, b: String) -> String:
	return "%s|%s" % [min(a, b), max(a, b)]

func _rng_for(reason: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(hash("faction_v2|%s|%s|%s|%s" % [state.get("week", WorldState.week), WorldState.current_day, state.get("player_action_counter", 0), reason]))
	return rng

func get_faction(faction_id: String) -> Dictionary:
	return state.get("factions", {}).get(faction_id, {}).duplicate(true)

func get_territory(territory_id: String) -> Dictionary:
	return state.get("territories", {}).get(territory_id, {}).duplicate(true)

func get_conflict(a: String, b: String) -> Dictionary:
	return state.get("conflicts", {}).get(_conflict_key(a, b), {}).duplicate(true)

func get_champion(faction_id: String) -> Dictionary:
	return state.get("champions", {}).get(faction_id, {}).duplicate(true)

func get_active_debts(faction_id := "") -> Array:
	var output: Array = []
	for debt_value in state.get("debts", []):
		if str(debt_value.get("status", "active")) != "active":
			continue
		if faction_id == "" or str(debt_value.get("faction_id", "")) == faction_id:
			output.append(debt_value.duplicate(true))
	return output

func get_recent_memories(faction_id := "", limit := 8) -> Array:
	var output: Array = []
	var memories: Array = state.get("memories", [])
	for index in range(memories.size() - 1, -1, -1):
		var memory: Dictionary = memories[index]
		if faction_id == "" or str(memory.get("faction_id", "")) == faction_id:
			output.append(memory.duplicate(true))
			if output.size() >= limit:
				break
	return output

func get_pressure_level() -> int:
	return int(state.get("pressure_level", 0))

func get_snapshot() -> Dictionary:
	return {
		"version": int(state.get("version", 2)),
		"week": int(state.get("week", WorldState.week)),
		"factions": state.get("factions", {}).duplicate(true),
		"territories": state.get("territories", {}).duplicate(true),
		"conflicts": state.get("conflicts", {}).duplicate(true),
		"active_operations": state.get("active_operations", []).duplicate(true),
		"pressure": state.get("pressure", {}).duplicate(true),
		"pressure_level": int(state.get("pressure_level", 0)),
		"champions": state.get("champions", {}).duplicate(true),
		"debts": get_active_debts(),
		"recent_memories": get_recent_memories("", 12)
	}

func to_dict() -> Dictionary:
	return state.duplicate(true)

func load_from_dict(data: Dictionary) -> void:
	if data.is_empty():
		reset_director()
		return
	state = data.duplicate(true)
	for required_key in ["factions", "territories", "conflicts", "active_operations", "operation_history", "memories", "debts", "pressure", "champions"]:
		if not state.has(required_key):
			reset_director()
			return
	state["version"] = 2
	_update_all_power_tiers()
	_recalculate_pressure_level()
	_sync_legacy_relations()

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("[FactionDirector] Arquivo ausente: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}
