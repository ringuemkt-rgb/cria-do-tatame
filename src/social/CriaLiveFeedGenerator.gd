class_name CriaLiveFeedGenerator
extends RefCounted

func generate(state: Dictionary, current_week: int) -> Array:
	var cards: Array = []
	for post_value in state.get("posts", []):
		if typeof(post_value) != TYPE_DICTIONARY:
			continue
		var post: Dictionary = post_value
		cards.append({
			"id": str(post.get("id", "")),
			"kind": "post",
			"week": int(post.get("week", 0)),
			"score": _recency_score(int(post.get("week", 0)), current_week) + (20.0 if bool(post.get("viral", false)) else 0.0),
			"payload": post.duplicate(true)
		})
	for proposal_value in state.get("proposals", []):
		if typeof(proposal_value) != TYPE_DICTIONARY:
			continue
		var proposal: Dictionary = proposal_value
		if str(proposal.get("status", "")) != "open":
			continue
		cards.append({
			"id": str(proposal.get("id", "")),
			"kind": "proposal",
			"week": int(proposal.get("created_week", current_week)),
			"score": 100.0 + _recency_score(int(proposal.get("created_week", current_week)), current_week),
			"payload": proposal.duplicate(true)
		})
	cards.sort_custom(_sort_cards)
	return cards

func _recency_score(item_week: int, current_week: int) -> float:
	return maxf(0.0, 40.0 - float(maxi(0, current_week - item_week)) * 8.0)

func _sort_cards(a: Dictionary, b: Dictionary) -> bool:
	var a_score := float(a.get("score", 0.0))
	var b_score := float(b.get("score", 0.0))
	if not is_equal_approx(a_score, b_score):
		return a_score > b_score
	return str(a.get("id", "")) < str(b.get("id", ""))
