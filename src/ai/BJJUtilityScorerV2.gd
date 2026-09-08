class_name BJJUtilityScorerV2
extends RefCounted

const DEFAULT_POSITION_VALUES := {
	"standing_neutral": 0.10,
	"front_headlock": 0.55,
	"closed_guard": 0.35,
	"half_guard_top": 0.50,
	"knee_shield_half": 0.30,
	"side_control": 0.75,
	"mount_high": 0.95,
	"back_mount_seatbelt": 0.90,
	"inside_ashi_garami": 0.70,
	"submission": 1.00
}

func choose(candidates: Array, nemesis_bias: Dictionary = {}, position_values: Dictionary = {}) -> String:
	var values := DEFAULT_POSITION_VALUES.duplicate(true)
	for key in position_values.keys():
		values[key] = position_values[key]
	var ranked := rank(candidates, nemesis_bias, values)
	if ranked.is_empty():
		return ""
	return str(ranked[0].get("id", ""))

func rank(candidates: Array, nemesis_bias: Dictionary = {}, position_values: Dictionary = {}) -> Array:
	var values := DEFAULT_POSITION_VALUES.duplicate(true)
	for key in position_values.keys():
		values[key] = position_values[key]
	var scored: Array = []
	for raw_candidate in candidates:
		if typeof(raw_candidate) != TYPE_DICTIONARY:
			continue
		var candidate: Dictionary = raw_candidate
		var tid := str(candidate.get("id", ""))
		var score := 0.0
		score += float(candidate.get("authoring_prior", 0.0)) * 40.0
		score += float(candidate.get("potential_points", 0.0)) * 8.0
		score += float(values.get(str(candidate.get("to", "")), 0.0)) * 20.0
		score -= float(candidate.get("counter_count", 0)) * 6.0
		score -= float(candidate.get("gas", 0.0)) * 0.3
		score += float(nemesis_bias.get(tid, 0.0))
		var item := candidate.duplicate(true)
		item["utility_score"] = score
		scored.append(item)
	scored.sort_custom(_sort_ranked)
	return scored

func _sort_ranked(a: Dictionary, b: Dictionary) -> bool:
	var score_a := float(a.get("utility_score", -INF))
	var score_b := float(b.get("utility_score", -INF))
	if not is_equal_approx(score_a, score_b):
		return score_a > score_b
	return str(a.get("id", "")) < str(b.get("id", ""))
