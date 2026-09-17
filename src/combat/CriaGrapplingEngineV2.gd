class_name CriaGrapplingEngineV2
extends RefCounted

const BaseRuntimeScript = preload("res://src/combat/CriaGrapplingRuntimeV1.gd")
const GripGraphScript = preload("res://src/combat/GrapplingGripGraphV1.gd")
const MicroStateScript = preload("res://src/combat/GrapplingMicroStateV1.gd")
const ReactionSelectorScript = preload("res://src/combat/GrapplingReactionSelectorV1.gd")
const MotionMatcherScript = preload("res://src/animation/GrapplingMotionMatcherV1.gd")

var base_runtime
var grip_graph
var reaction_selector
var motion_matcher
var technique_index: Dictionary = {}

func _init(
	kg_data: Dictionary,
	rules_data: Dictionary,
	timing_data: Dictionary,
	motion_requirements: Dictionary,
	physical_binding_data: Dictionary = {},
	golden_data: Dictionary = {},
	fatigue_contract: Dictionary = {},
	fatigue_profiles: Dictionary = {},
	grip_topology: Dictionary = {},
	reaction_policy: Dictionary = {},
	motion_matching_profile: Dictionary = {}
):
	base_runtime = BaseRuntimeScript.new(
		kg_data,
		rules_data,
		timing_data,
		motion_requirements,
		physical_binding_data,
		golden_data,
		fatigue_contract,
		fatigue_profiles
	)
	grip_graph = GripGraphScript.new(grip_topology)
	reaction_selector = ReactionSelectorScript.new(reaction_policy)
	motion_matcher = MotionMatcherScript.new(motion_matching_profile)
	for raw_technique in kg_data.get("techniques", kg_data.get("tecnicas", [])):
		if typeof(raw_technique) != TYPE_DICTIONARY:
			continue
		var technique: Dictionary = raw_technique
		var technique_id: String = str(technique.get("id", ""))
		if technique_id != "":
			technique_index[technique_id] = technique.duplicate(true)

func is_ready() -> bool:
	return (
		base_runtime != null
		and base_runtime.is_ready()
		and grip_graph != null
		and grip_graph.is_ready()
		and reaction_selector != null
		and reaction_selector.is_ready()
		and motion_matcher != null
		and motion_matcher.is_ready()
	)

func new_match(
	ruleset: String,
	gi: bool,
	seed: int,
	belt_or_skill_division: String = "slice_any",
	age_division: String = "adult",
	input_profile: String = "touch",
	fatigue_residual: Dictionary = {}
) -> Dictionary:
	var base_state: Dictionary = base_runtime.new_match(
		ruleset,
		gi,
		seed,
		belt_or_skill_division,
		age_division,
		input_profile,
		fatigue_residual
	)
	var grips: Dictionary = grip_graph.new_state(gi)
	var microstate: Dictionary = MicroStateScript.from_runtime(
		base_state,
		grips,
		grip_graph,
		{},
		base_state.get("physical", {}),
		""
	)
	return {
		"engine_version": "2.0.0",
		"base": base_state,
		"shadow": {
			"grips": grips,
			"microstate": microstate,
			"last_reaction_id": "",
			"last_clip_id": "",
			"step_index": 0
		},
		"authority": "BJJGraphReducerV2",
		"shadow_may_mutate_authority": false,
		"shipping": false
	}

func step(
	engine_state: Dictionary,
	action: Dictionary,
	interaction_events: Array = [],
	visual_context: Dictionary = {},
	motion_clips: Array = []
) -> Dictionary:
	var base_before: Dictionary = engine_state.get("base", {}).duplicate(true)
	var base_result: Dictionary = base_runtime.step(base_before, action)
	var base_after: Dictionary = base_result.get("state", base_before).duplicate(true)
	var accepted: bool = bool(base_result.get("accepted", false))
	var shadow_before: Dictionary = engine_state.get("shadow", {}).duplicate(true)
	var grips: Dictionary = shadow_before.get(
		"grips",
		grip_graph.new_state(bool(base_after.get("combat", {}).get("gi", false)))
	).duplicate(true)
	var interaction_errors: Array = []

	if accepted and not interaction_events.is_empty():
		var grip_result: Dictionary = grip_graph.apply_events(grips, interaction_events)
		grips = grip_result.get("state", grips)
		interaction_errors = grip_result.get("errors", []).duplicate(true)

	var motion_request: Dictionary = base_result.get("motion_request", {}).duplicate(true)
	var technique_id: String = str(motion_request.get("technique_id", action.get("atk", "")))
	var technique_meta: Dictionary = technique_index.get(technique_id, {})
	motion_request["technique_type"] = str(technique_meta.get("type", technique_meta.get("tipo", "")))

	var physical_state: Dictionary = base_after.get("physical", {}).duplicate(true)
	var requested_phase: String = str(visual_context.get("phase", ""))
	if accepted and technique_id != "" and requested_phase != "":
		physical_state = base_runtime.physical_state_for_phase(base_after, technique_id, requested_phase)

	var microstate: Dictionary = MicroStateScript.from_runtime(
		base_after,
		grips,
		grip_graph,
		motion_request,
		physical_state,
		str(shadow_before.get("last_clip_id", ""))
	)

	var attacker: int = int(action.get("atk_player", 0))
	var defender: int = 2 if attacker == 1 else (1 if attacker == 2 else 0)
	var action_context: Dictionary = {
		"technique_id": technique_id,
		"attack_type": str(motion_request.get("technique_type", "")),
		"outcome": str(base_result.get("outcome_event", {}).get("ev", ""))
	}
	var reactions: Array = []
	var reaction_id: String = ""
	if accepted and defender in [1, 2]:
		reactions = reaction_selector.rank(microstate, action_context, defender, 4)
		if not reactions.is_empty():
			reaction_id = str(reactions[0].get("reaction_id", ""))

	var motion_selection: Dictionary = {"ok": false, "reason": "NO_SELECTION", "clip_id": ""}
	if accepted and attacker in [1, 2] and not motion_clips.is_empty():
		var motion_query: Dictionary = MicroStateScript.motion_query(microstate, attacker, reaction_id)
		motion_selection = motion_matcher.select(motion_query, motion_clips)

	var last_clip_id: String = str(shadow_before.get("last_clip_id", ""))
	if bool(motion_selection.get("ok", false)):
		last_clip_id = str(motion_selection.get("clip_id", ""))

	var next_state: Dictionary = {
		"engine_version": "2.0.0",
		"base": base_after,
		"shadow": {
			"grips": grips,
			"microstate": microstate,
			"last_reaction_id": reaction_id,
			"last_clip_id": last_clip_id,
			"step_index": int(shadow_before.get("step_index", 0)) + (1 if accepted else 0)
		},
		"authority": "BJJGraphReducerV2",
		"shadow_may_mutate_authority": false,
		"shipping": false
	}

	var result: Dictionary = base_result.duplicate(true)
	result["engine_state"] = next_state
	result["motion_request"] = motion_request
	result["reaction_candidates"] = reactions
	result["motion_selection"] = motion_selection
	result["interaction_errors"] = interaction_errors
	result["authoritative_state_changed_by_grappling_engine_v2"] = false
	return result

func available_actions(engine_state: Dictionary, player: int) -> Array:
	return base_runtime.available_actions(engine_state.get("base", {}), player)

func query(engine_state: Dictionary, player: int) -> Array:
	return base_runtime.query(engine_state.get("base", {}), player)

func physical_state_for_phase(engine_state: Dictionary, technique_id: String, phase: String) -> Dictionary:
	return base_runtime.physical_state_for_phase(engine_state.get("base", {}), technique_id, phase)

func motion_coverage() -> Dictionary:
	return base_runtime.motion_coverage()

func fatigue_coverage() -> Dictionary:
	return base_runtime.fatigue_coverage()
