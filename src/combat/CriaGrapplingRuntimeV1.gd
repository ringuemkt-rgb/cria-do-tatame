class_name CriaGrapplingRuntimeV1
extends RefCounted

const ReducerScript = preload("res://src/combat/BJJGraphReducerV2.gd")
const PhysicalStateScript = preload("res://src/combat/GrapplingPhysicalStateV1.gd")
const MotionBindingScript = preload("res://src/animation/BJJMotionBindingV1.gd")
const FatigueScript = preload("res://src/combat/GrapplingFatigueModelV1.gd")

var reducer
var motion_binding
var fatigue_model
var physical_bindings: Dictionary = {}
var binding_by_technique: Dictionary = {}
var golden_contract: Dictionary = {}

func _init(kg_data: Dictionary, rules_data: Dictionary, timing_data: Dictionary, motion_requirements: Dictionary, physical_binding_data: Dictionary = {}, golden_data: Dictionary = {}, fatigue_contract: Dictionary = {}, fatigue_profiles: Dictionary = {}):
	reducer = ReducerScript.new(kg_data, rules_data, timing_data)
	motion_binding = MotionBindingScript.new(motion_requirements)
	fatigue_model = FatigueScript.new(fatigue_contract, fatigue_profiles)
	physical_bindings = physical_binding_data.duplicate(true)
	golden_contract = golden_data.duplicate(true)
	for raw_binding in physical_bindings.get("bindings", []):
		if typeof(raw_binding) != TYPE_DICTIONARY:
			continue
		var binding: Dictionary = raw_binding
		var technique_id := str(binding.get("technique_id", ""))
		if technique_id != "":
			binding_by_technique[technique_id] = binding.duplicate(true)

func is_ready() -> bool:
	return reducer != null and reducer.is_ready()

func fatigue_shadow_ready() -> bool:
	return fatigue_model != null and fatigue_model.is_ready()

func new_match(ruleset: String, gi: bool, seed: int, belt_or_skill_division: String = "slice_any", age_division: String = "adult", input_profile: String = "touch", fatigue_residual: Dictionary = {}) -> Dictionary:
	var combat: Dictionary = reducer.new_state(ruleset, gi, seed, belt_or_skill_division, age_division, input_profile)
	var state := {
		"runtime_version": "1.0.0",
		"combat": combat,
		"physical": PhysicalStateScript.from_reducer_state(combat),
		"authority": "BJJGraphReducerV2",
		"renderer_authoritative": false,
		"shipping": false
	}
	if fatigue_shadow_ready():
		state["fatigue"] = fatigue_model.new_state(fatigue_residual)
	return state

func step(runtime_state: Dictionary, action: Dictionary) -> Dictionary:
	var before_combat: Dictionary = runtime_state.get("combat", {}).duplicate(true)
	var before_tick := int(before_combat.get("tick", 0))
	var before_log_size := int(before_combat.get("log", []).size())
	var after_combat: Dictionary = reducer.reduce(before_combat, action)
	var accepted := int(after_combat.get("tick", 0)) > before_tick
	var outcome_event := _new_outcome_event(after_combat, before_log_size)
	var transition := _transition(before_combat, after_combat, action, outcome_event, accepted)
	var motion_request: Dictionary = motion_binding.build_request(before_combat, after_combat, action, outcome_event)

	# Reducer truth is committed immediately; biomechanical phase detail is not.
	# The renderer/animation system must explicitly request a reviewed phase via
	# physical_state_for_phase(). This prevents a completed technique from being
	# silently collapsed into a guessed recovery pose/contact graph.
	var physical := PhysicalStateScript.from_reducer_state(after_combat)
	var visual_technique_id := str(motion_request.get("technique_id", ""))
	if visual_technique_id != "":
		physical = PhysicalStateScript.set_unobserved_phase(physical, "UNKNOWN")

	var next_state := {
		"runtime_version": "1.0.0",
		"combat": after_combat,
		"physical": physical,
		"authority": "BJJGraphReducerV2",
		"renderer_authoritative": false,
		"shipping": false
	}
	if fatigue_shadow_ready():
		var before_fatigue: Dictionary = runtime_state.get("fatigue", fatigue_model.new_state())
		next_state["fatigue"] = fatigue_model.observe_step(before_fatigue, before_combat, after_combat, action, outcome_event)

	return {
		"accepted": accepted,
		"state": next_state,
		"transition": transition,
		"motion_request": motion_request,
		"outcome_event": outcome_event,
		"fatigue_effect": fatigue_model.projected_effect(next_state.get("fatigue", {}), int(action.get("atk_player", 0))) if fatigue_shadow_ready() else {},
		"authoritative_state_changed_by_renderer": false,
		"authoritative_state_changed_by_fatigue": false
	}

func rest_fatigue(runtime_state: Dictionary, seconds: float) -> Dictionary:
	var next := runtime_state.duplicate(true)
	if not fatigue_shadow_ready():
		return next
	var before_combat: Dictionary = runtime_state.get("combat", {}).duplicate(true)
	next["fatigue"] = fatigue_model.rest(runtime_state.get("fatigue", fatigue_model.new_state()), seconds)
	# Rest is a between-match/recovery observation in V1. It cannot alter reducer gas,
	# score, position, winner or RNG state.
	next["combat"] = before_combat
	return next

func physical_state_for_phase(runtime_state: Dictionary, technique_id: String, phase: String) -> Dictionary:
	var combat: Dictionary = runtime_state.get("combat", {}).duplicate(true)
	var physical := PhysicalStateScript.from_reducer_state(combat)
	if not binding_by_technique.has(technique_id):
		return PhysicalStateScript.set_unobserved_phase(physical, phase)
	var binding: Dictionary = binding_by_technique[technique_id]
	if str(binding.get("review_status", "PENDING")) != "APPROVED":
		return PhysicalStateScript.set_unobserved_phase(physical, phase)
	return PhysicalStateScript.apply_reviewed_binding(physical, binding, phase)

func available_actions(runtime_state: Dictionary, player: int) -> Array:
	return reducer.available_actions(runtime_state.get("combat", {}), player)

func query(runtime_state: Dictionary, player: int) -> Array:
	var rows: Array = reducer.query(runtime_state.get("combat", {}), player)
	if not fatigue_shadow_ready():
		return rows
	var effect: Dictionary = fatigue_model.projected_effect(runtime_state.get("fatigue", {}), player)
	for index in range(rows.size()):
		if typeof(rows[index]) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = rows[index].duplicate(true)
		row["fatigue_shadow"] = effect.duplicate(true)
		row["fatigue_profile"] = fatigue_model.profile_for(str(row.get("id", "")))
		rows[index] = row
	return rows

func motion_coverage() -> Dictionary:
	var technique_ids: Array = []
	for raw_step in golden_contract.get("success_chain", []):
		if typeof(raw_step) == TYPE_DICTIONARY:
			technique_ids.append(str(raw_step.get("technique_id", "")))
	for raw_branch in golden_contract.get("defense_branches", []):
		if typeof(raw_branch) == TYPE_DICTIONARY:
			technique_ids.append(str(raw_branch.get("counter_id", "")))
	for raw_branch in golden_contract.get("alternate_branches", []):
		if typeof(raw_branch) == TYPE_DICTIONARY:
			technique_ids.append(str(raw_branch.get("technique_id", "")))
	var unique_ids: Array = []
	for technique_id in technique_ids:
		if str(technique_id) != "" and technique_id not in unique_ids:
			unique_ids.append(technique_id)
	return motion_binding.coverage(unique_ids)

func fatigue_coverage() -> Dictionary:
	if not fatigue_shadow_ready():
		return {"ok": false, "reason": "FATIGUE_SHADOW_UNCONFIGURED"}
	var technique_ids: Array = []
	for raw_step in golden_contract.get("success_chain", []):
		if typeof(raw_step) == TYPE_DICTIONARY:
			technique_ids.append(str(raw_step.get("technique_id", "")))
	for raw_branch in golden_contract.get("defense_branches", []):
		if typeof(raw_branch) == TYPE_DICTIONARY:
			technique_ids.append(str(raw_branch.get("attack_id", "")))
			technique_ids.append(str(raw_branch.get("counter_id", "")))
	for raw_branch in golden_contract.get("alternate_branches", []):
		if typeof(raw_branch) == TYPE_DICTIONARY:
			technique_ids.append(str(raw_branch.get("technique_id", "")))
	var unique_ids: Array = []
	for technique_id in technique_ids:
		if str(technique_id) != "" and technique_id not in unique_ids:
			unique_ids.append(technique_id)
	return fatigue_model.coverage(unique_ids)

func _new_outcome_event(after_combat: Dictionary, before_log_size: int) -> Dictionary:
	var log: Array = after_combat.get("log", [])
	if log.size() <= before_log_size:
		return {}
	var raw_event = log[log.size() - 1]
	return raw_event.duplicate(true) if typeof(raw_event) == TYPE_DICTIONARY else {}

func _transition(before_combat: Dictionary, after_combat: Dictionary, action: Dictionary, outcome_event: Dictionary, accepted: bool) -> Dictionary:
	return {
		"accepted": accepted,
		"from_position": str(before_combat.get("pos", "")),
		"to_position": str(after_combat.get("pos", "")),
		"top_before": int(before_combat.get("top", 0)),
		"top_after": int(after_combat.get("top", 0)),
		"tick_before": int(before_combat.get("tick", 0)),
		"tick_after": int(after_combat.get("tick", 0)),
		"action_kind": str(action.get("kind", "technique")),
		"attack_id": str(action.get("atk", "")),
		"defense_id": str(action.get("def", "")),
		"outcome": str(outcome_event.get("ev", "")),
		"winner": int(after_combat.get("winner", 0)),
		"pending_score": after_combat.get("pending_score", {}).duplicate(true)
	}
