class_name ScoutingSystem
extends RefCounted

const LEARN_THRESHOLD := 2

var observed_in_fight: Dictionary = {}

func reset_fight() -> void:
	observed_in_fight.clear()

func build_report(
	opponent_id: String,
	rival_profile: Dictionary,
	scouting_overlay: Dictionary = {},
	social_state: Dictionary = {}
) -> Dictionary:
	var exposure: Dictionary = social_state.get("technique_exposure", {}) if typeof(social_state.get("technique_exposure", {})) == TYPE_DICTIONARY else {}
	var known: Array[String] = []
	var watched := 0
	var ids: Array = exposure.keys()
	ids.sort()
	for raw_id in ids:
		var technique_id := str(raw_id)
		var count := int(exposure[raw_id])
		watched += count
		if count >= LEARN_THRESHOLD:
			known.append(technique_id)
	return {
		"opponent": opponent_id,
		"display_name": str(rival_profile.get("display_name", opponent_id)),
		"style": str(scouting_overlay.get("style", rival_profile.get("archetype", "unknown"))),
		"archetype": str(scouting_overlay.get("archetype", rival_profile.get("archetype", "unknown"))),
		"counters_known": known,
		"weaknesses": scouting_overlay.get("weaknesses", []).duplicate(),
		"signature_chain": str(scouting_overlay.get("signature_chain", "")),
		"clips_watched": watched,
		"faction": str(scouting_overlay.get("faction", "")),
		"preferred_actions": rival_profile.get("preferred_actions", []).duplicate(),
		"preferred_states": rival_profile.get("preferred_states", []).duplicate()
	}

func observe_runtime(technique_id: String) -> Dictionary:
	if technique_id == "":
		return {"ok": false, "reason": "empty_technique"}
	var count := int(observed_in_fight.get(technique_id, 0)) + 1
	observed_in_fight[technique_id] = count
	return {
		"ok": true,
		"technique_id": technique_id,
		"count": count,
		"counter_suggestion_unlocked": count >= LEARN_THRESHOLD
	}

func to_dict() -> Dictionary:
	return {"observed_in_fight": observed_in_fight.duplicate(true)}
