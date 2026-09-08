class_name BJJUtilityScorerV2
extends RefCounted

const DEFAULT_FALLBACK_VALUE := 0.45

var tuning: Dictionary = {}
var bands: Dictionary = {}
var position_groups: Dictionary = {}
var fallback_value := DEFAULT_FALLBACK_VALUE

func _init(position_value_data: Dictionary = {}):
	configure(position_value_data)

func configure(position_value_data: Dictionary) -> void:
	tuning = position_value_data.duplicate(true)
	bands = tuning.get("bands", {}).duplicate(true) if typeof(tuning.get("bands", {})) == TYPE_DICTIONARY else {}
	position_groups = tuning.get("position_groups", {}).duplicate(true) if typeof(tuning.get("position_groups", {})) == TYPE_DICTIONARY else {}
	fallback_value = float(tuning.get("unmapped_fallback", DEFAULT_FALLBACK_VALUE))

func position_value_for(position_id: String, overrides: Dictionary = {}) -> float:
	if overrides.has(position_id):
		return float(overrides[position_id])
	var group := str(position_groups.get(position_id, ""))
	if not group.is_empty() and bands.has(group):
		return float(bands[group])
	return fallback_value

func choose(candidates: Array, nemesis_bias: Dictionary = {}, position_values: Dictionary = {}) -> String:
	var ranked := rank(candidates, nemesis_bias, position_values)
	if ranked.is_empty():
		return ""
	return str(ranked[0].get("id", ""))

func rank(candidates: Array, nemesis_bias: Dictionary = {}, position_values: Dictionary = {}) -> Array:
	var scored: Array = []
	for raw_candidate in candidates:
		if typeof(raw_candidate) != TYPE_DICTIONARY:
			continue
		var candidate: Dictionary = raw_candidate
		var tid := str(candidate.get("id", ""))
		var destination := str(candidate.get("to", ""))
		var positional_value := position_value_for(destination, position_values)
		var score := 0.0
		score += float(candidate.get("authoring_prior", 0.0)) * 40.0
		score += float(candidate.get("potential_points", 0.0)) * 8.0
		score += positional_value * 20.0
		score -= float(candidate.get("counter_count", 0)) * 6.0
		score -= float(candidate.get("gas", 0.0)) * 0.3
		score += float(nemesis_bias.get(tid, 0.0))
		var item := candidate.duplicate(true)
		item["position_value"] = positional_value
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
