class_name GrapplingMotionMatcherV1
extends RefCounted

var profile: Dictionary = {}
var weights: Dictionary = {}

func _init(profile_data: Dictionary):
	profile = profile_data.duplicate(true)
	weights = profile.get("weights", {}).duplicate(true)

func is_ready() -> bool:
	return str(profile.get("version", "")) == "1.0.0" and not weights.is_empty()

func select(query: Dictionary, clips: Array) -> Dictionary:
	if not is_ready() or clips.is_empty():
		return {"ok": false, "reason": "NO_SELECTION", "clip_id": "", "cost": INF}
	var best: Dictionary = {}
	var best_cost := INF
	for raw_clip in clips:
		if typeof(raw_clip) != TYPE_DICTIONARY:
			continue
		var clip: Dictionary = raw_clip
		var clip_id := str(clip.get("clip_id", ""))
		if clip_id == "":
			continue
		var features = clip.get("features", {})
		if typeof(features) != TYPE_DICTIONARY:
			continue
		var cost := _cost(query, features)
		if cost < best_cost or (is_equal_approx(cost, best_cost) and clip_id < str(best.get("clip_id", "~"))):
			best_cost = cost
			best = {
				"ok": true,
				"clip_id": clip_id,
				"cost": cost,
				"features": features.duplicate(true),
				"sync_map_ref": str(clip.get("sync_map_ref", "")),
				"contact_signature": clip.get("contact_signature", []).duplicate(true),
				"authority": "VISUAL_SELECTION_ONLY"
			}
	if best.is_empty():
		return {"ok": false, "reason": "NO_VALID_CLIPS", "clip_id": "", "cost": INF}
	return best

func rank(query: Dictionary, clips: Array, max_results: int = 6) -> Array:
	var rows: Array = []
	for raw_clip in clips:
		if typeof(raw_clip) != TYPE_DICTIONARY:
			continue
		var clip: Dictionary = raw_clip
		var features = clip.get("features", {})
		if typeof(features) != TYPE_DICTIONARY or str(clip.get("clip_id", "")) == "":
			continue
		rows.append({
			"clip_id": str(clip.get("clip_id", "")),
			"cost": _cost(query, features),
			"features": features.duplicate(true)
		})
	_sort_by_cost(rows)
	var limit := mini(maxi(max_results, 0), rows.size())
	return rows.slice(0, limit)

func _cost(query: Dictionary, candidate: Dictionary) -> float:
	var cost := 0.0
	cost += _categorical_cost(query, candidate, "technique_id", float(weights.get("technique_id", 10.0)))
	cost += _categorical_cost(query, candidate, "attack_type", float(weights.get("attack_type", 4.0)))
	cost += _categorical_cost(query, candidate, "position_id", float(weights.get("position_id", 6.0)))
	cost += _categorical_cost(query, candidate, "top_role", float(weights.get("top_role", 2.0)))
	cost += _categorical_cost(query, candidate, "mode", float(weights.get("mode", 5.0)))
	cost += _categorical_cost(query, candidate, "phase", float(weights.get("phase", 4.0)))
	cost += _categorical_cost(query, candidate, "reaction_id", float(weights.get("reaction_id", 3.0)))
	cost += _categorical_cost(query, candidate, "gas_bucket", float(weights.get("gas_bucket", 1.5)))
	cost += _array_cost(query, candidate, "self_grip_signature", float(weights.get("self_grip_signature", 2.5)))
	cost += _array_cost(query, candidate, "opponent_grip_signature", float(weights.get("opponent_grip_signature", 2.5)))
	cost += _array_cost(query, candidate, "reviewed_connection_signature", float(weights.get("reviewed_connection_signature", 5.0)))

	var previous := str(query.get("previous_clip_id", ""))
	if previous != "" and previous == str(candidate.get("previous_clip_id", "")):
		cost -= float(weights.get("previous_clip_continuity", 1.0))
	return maxf(0.0, cost)

func _categorical_cost(query: Dictionary, candidate: Dictionary, key: String, weight: float) -> float:
	var q_missing := not query.has(key) or str(query.get(key, "")) == ""
	var c_missing := not candidate.has(key) or str(candidate.get(key, "")) == ""
	if q_missing or c_missing:
		return weight * float(profile.get("missing_feature_penalty_scale", 0.25))
	return 0.0 if str(query.get(key, "")) == str(candidate.get(key, "")) else weight

func _array_cost(query: Dictionary, candidate: Dictionary, key: String, weight: float) -> float:
	var q = query.get(key, [])
	var c = candidate.get(key, [])
	if typeof(q) != TYPE_ARRAY or typeof(c) != TYPE_ARRAY:
		return weight * float(profile.get("missing_feature_penalty_scale", 0.25))
	if q.is_empty() and c.is_empty():
		return 0.0
	var union_values: Array = []
	var intersection_count := 0
	for value in q:
		if value not in union_values:
			union_values.append(value)
		if value in c:
			intersection_count += 1
	for value in c:
		if value not in union_values:
			union_values.append(value)
	if union_values.is_empty():
		return 0.0
	var distance := 1.0 - (float(intersection_count) / float(union_values.size()))
	return weight * clampf(distance, 0.0, 1.0)

func _sort_by_cost(rows: Array) -> void:
	for i in range(1, rows.size()):
		var current: Dictionary = rows[i]
		var j := i - 1
		while j >= 0 and _comes_before(current, rows[j]):
			rows[j + 1] = rows[j]
			j -= 1
		rows[j + 1] = current

func _comes_before(a: Dictionary, b: Dictionary) -> bool:
	var cost_a := float(a.get("cost", INF))
	var cost_b := float(b.get("cost", INF))
	if not is_equal_approx(cost_a, cost_b):
		return cost_a < cost_b
	return str(a.get("clip_id", "")) < str(b.get("clip_id", ""))
