class_name GrapplingReactionSelectorV1
extends RefCounted

var policy: Dictionary = {}
var reactions: Array = []

func _init(policy_data: Dictionary):
	policy = policy_data.duplicate(true)
	reactions = policy.get("reactions", []).duplicate(true)

func is_ready() -> bool:
	return str(policy.get("version", "")) == "1.0.0" and not reactions.is_empty()

func rank(microstate: Dictionary, action_context: Dictionary, defender_player: int, max_results: int = 4) -> Array:
	if defender_player not in [1, 2] or not is_ready():
		return []
	var scored: Array = []
	var attack_type := str(action_context.get("attack_type", microstate.get("attack_type", "")))
	var position_id := str(microstate.get("position_id", ""))
	var mode := str(microstate.get("mode", ""))
	var top_player := int(microstate.get("top_player", 0))
	var role := "neutral"
	if top_player != 0:
		role = "top" if top_player == defender_player else "bottom"
	var players: Dictionary = microstate.get("players", {})
	var defender_data: Dictionary = players.get("p%d" % defender_player, {})
	var opponent_data: Dictionary = players.get("p%d" % (2 if defender_player == 1 else 1), {})
	var opponent_grips: Array = opponent_data.get("grip_signature", [])
	var score_model: Dictionary = policy.get("score_model", {})

	for raw_reaction in reactions:
		if typeof(raw_reaction) != TYPE_DICTIONARY:
			continue
		var reaction: Dictionary = raw_reaction
		var attack_types: Array = reaction.get("attack_types", [])
		if not attack_types.is_empty() and attack_type not in attack_types:
			continue
		var modes: Array = reaction.get("modes", [])
		if not modes.is_empty() and mode not in modes:
			continue
		var positions: Array = reaction.get("positions", [])
		if not positions.is_empty() and position_id not in positions:
			continue
		var roles: Array = reaction.get("roles", [])
		if not roles.is_empty() and role not in roles:
			continue

		var score := float(score_model.get("base_score", 1.0))
		if attack_type in attack_types:
			score += float(score_model.get("exact_attack_type_bonus", 2.0))
		if position_id in positions:
			score += float(score_model.get("position_match_bonus", 1.5))
		if mode in modes:
			score += float(score_model.get("mode_match_bonus", 0.5))
		if role in roles:
			score += float(score_model.get("role_match_bonus", 0.75))

		var preferred: Array = reaction.get("preferred_opponent_grips", [])
		if not preferred.is_empty() and _has_overlap(preferred, opponent_grips):
			score += float(score_model.get("grip_signature_bonus", 0.75))
		if str(defender_data.get("gas_bucket", "working")) == "fatigued":
			score -= float(score_model.get("low_gas_penalty", 0.5))

		scored.append({
			"reaction_id": str(reaction.get("id", "")),
			"score": score,
			"tags": reaction.get("tags", []).duplicate(true),
			"visual_only": true,
			"executes_combat_action": false
		})

	_sort_ranked(scored)
	var limit := mini(maxi(max_results, 0), scored.size())
	return scored.slice(0, limit)

func primary(microstate: Dictionary, action_context: Dictionary, defender_player: int) -> String:
	var ranked := rank(microstate, action_context, defender_player, 1)
	if ranked.is_empty():
		return ""
	return str(ranked[0].get("reaction_id", ""))

func _has_overlap(a: Array, b: Array) -> bool:
	for value in a:
		if value in b:
			return true
	return false

func _sort_ranked(rows: Array) -> void:
	for i in range(1, rows.size()):
		var current: Dictionary = rows[i]
		var j := i - 1
		while j >= 0 and _comes_before(current, rows[j]):
			rows[j + 1] = rows[j]
			j -= 1
		rows[j + 1] = current

func _comes_before(a: Dictionary, b: Dictionary) -> bool:
	var score_a := float(a.get("score", 0.0))
	var score_b := float(b.get("score", 0.0))
	if not is_equal_approx(score_a, score_b):
		return score_a > score_b
	return str(a.get("reaction_id", "")) < str(b.get("reaction_id", ""))
