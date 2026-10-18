extends RefCounted
class_name SkillTreeRulesV1

## Sole new progression service for the slice (not an autoload).
## The graph owns identity/order. WorldState owns purchased IDs and skill points.
## DeckManager remains the only authority for technique-card unlocks.
const GRAPH_PATH := "res://data/progression/skill_graph_v1.json"
const POLICY_PATH := "res://data/progression/skill_tree_playable_slice_v1.json"

var graph: Dictionary = {}
var policy: Dictionary = {}
var nodes: Dictionary = {}

func _init() -> void:
	graph = _read_json(GRAPH_PATH)
	policy = _read_json(POLICY_PATH)
	for raw_path in graph.get("paths", []):
		if typeof(raw_path) != TYPE_DICTIONARY:
			continue
		var path_data: Dictionary = raw_path
		var ids: Array = path_data.get("nodes", [])
		for index in range(ids.size()):
			var skill_id := str(ids[index])
			if nodes.has(skill_id):
				push_error("[SkillTreeRulesV1] Duplicate skill id: " + skill_id)
				continue
			nodes[skill_id] = {
				"id": skill_id,
				"path_id": str(path_data.get("id", "")),
				"path_name": str(path_data.get("display_name", "")),
				"color": str(path_data.get("color", "#c9971c")),
				"index": index,
				"requires": str(ids[index - 1]) if index > 0 else "",
				"capstone": skill_id == str(path_data.get("capstone", "")),
				"card_reward": str(policy.get("card_unlock_rewards", {}).get(skill_id, ""))
			}

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

func is_valid() -> bool:
	if graph.is_empty() or policy.is_empty() or nodes.is_empty():
		return false
	if bool(policy.get("shipping", true)) or str(policy.get("status", "")) != "PROVISIONAL_GAMEPLAY_BALANCE_NOT_FINAL":
		return false
	if str(policy.get("graph_source", "")) != "data/progression/skill_graph_v1.json":
		return false
	if int(policy.get("cost_per_node", 0)) < 1 or str(policy.get("unlock_order", "")) != "sequential_within_each_path":
		return false
	for reward in policy.get("card_unlock_rewards", {}).keys():
		if not nodes.has(str(reward)):
			return false
	return true

func list_paths() -> Array:
	return graph.get("paths", []).duplicate(true)

func get_node(skill_id: String) -> Dictionary:
	return nodes.get(skill_id, {}).duplicate(true)

func list_nodes(path_id: String) -> Array:
	for raw in graph.get("paths", []):
		if str(raw.get("id", "")) != path_id:
			continue
		var result: Array = []
		for skill_id in raw.get("nodes", []):
			result.append(get_node(str(skill_id)))
		return result
	return []

func evaluate(skill_id: String, purchased: Array, available_points: int) -> Dictionary:
	if not is_valid():
		return {"ok": false, "error": "invalid_skill_contract"}
	var node: Dictionary = get_node(skill_id)
	if node.is_empty():
		return {"ok": false, "error": "unknown_skill"}
	if purchased.has(skill_id):
		return {"ok": false, "error": "already_unlocked", "node": node}
	var previous := str(node.get("requires", ""))
	if previous != "" and not purchased.has(previous):
		return {"ok": false, "error": "requires_previous", "required_id": previous, "node": node}
	var cost := int(policy.get("cost_per_node", 1))
	if available_points < cost:
		return {"ok": false, "error": "insufficient_skill_points", "cost": cost, "node": node}
	return {"ok": true, "cost": cost, "node": node}

func purchase(skill_id: String, world: Node, deck: Node) -> Dictionary:
	if not is_instance_valid(world) or not is_instance_valid(deck):
		return {"ok": false, "error": "missing_runtime_authority"}
	var unlocked: Array = world.get("unlocked_skills")
	var points := int(world.get("skill_points"))
	var permission := evaluate(skill_id, unlocked, points)
	if not bool(permission.get("ok", false)):
		return permission
	var node: Dictionary = permission["node"]
	var reward := str(node.get("card_reward", ""))
	# Fail closed before spending a point. DeckManager enforces existing
	# belt/card constraints; no direct mutation of its cards is allowed.
	if reward != "":
		var cards: Dictionary = deck.get("cards")
		if not cards.has(reward):
			return {"ok": false, "error": "reward_card_missing", "card_id": reward}
		if not bool(cards[reward].get("unlocked", false)):
			var unlock: Dictionary = deck.call("unlock_card", reward)
			if not bool(unlock.get("ok", false)):
				return {"ok": false, "error": "reward_locked_by_deck", "detail": str(unlock.get("error", ""))}
	unlocked.append(skill_id)
	world.set("unlocked_skills", unlocked)
	world.set("skill_points", points - int(permission.get("cost", 1)))
	world.call("_sync_aliases")
	return {"ok": true, "node": node, "remaining_points": int(world.get("skill_points")), "card_reward": reward}

func display_name(skill_id: String) -> String:
	return skill_id.replace("_", " ").capitalize()
