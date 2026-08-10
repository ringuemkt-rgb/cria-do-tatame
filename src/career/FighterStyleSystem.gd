class_name FighterStyleSystem
extends RefCounted

const LEVELS_STATE_KEY := "skill_tree_v2_levels"
const ACTIVE_STYLE_STATE_KEY := "active_fighter_style_v1"

func list_styles() -> Array:
	return DataRegistry.fighter_styles.get("styles", []).duplicate(true)

func list_branches() -> Array:
	return DataRegistry.skill_tree_v2.get("branches", []).duplicate(true)

func get_active_style_id() -> String:
	var default_id := str(DataRegistry.fighter_styles.get("default_style_id", "pressao"))
	var stored_id := str(WorldState.story_flags.get(ACTIVE_STYLE_STATE_KEY, default_id))
	if DataRegistry.get_fighter_style(stored_id).is_empty():
		return default_id
	return stored_id

func get_active_style() -> Dictionary:
	var style := DataRegistry.get_fighter_style(get_active_style_id())
	if not style.is_empty():
		return style
	return DataRegistry.get_fighter_style(str(DataRegistry.fighter_styles.get("default_style_id", "pressao")))

func get_levels() -> Dictionary:
	var stored = WorldState.story_flags.get(LEVELS_STATE_KEY, {})
	if typeof(stored) == TYPE_DICTIONARY:
		return stored.duplicate(true)
	return {}

func get_node_level(node_id: String) -> int:
	return int(get_levels().get(node_id, 0))

func get_branch_points(branch_id: String) -> int:
	var total := 0
	var levels := get_levels()
	for branch_value in list_branches():
		if str(branch_value.get("id", "")) != branch_id:
			continue
		for node_value in branch_value.get("nodes", []):
			total += int(levels.get(str(node_value.get("id", "")), 0))
		break
	return total

func is_style_unlocked(style_id: String) -> bool:
	var default_id := str(DataRegistry.fighter_styles.get("default_style_id", "pressao"))
	if style_id == default_id:
		return true
	var style := DataRegistry.get_fighter_style(style_id)
	if style.is_empty():
		return false
	var requirements: Dictionary = style.get("requirements", {})
	for branch_value in requirements.keys():
		var branch_id := str(branch_value)
		if get_branch_points(branch_id) < int(requirements[branch_value]):
			return false
	return true

func set_active_style(style_id: String) -> Dictionary:
	var style := DataRegistry.get_fighter_style(style_id)
	if style.is_empty():
		return {"ok": false, "error": "style_not_found", "style_id": style_id}
	if not is_style_unlocked(style_id):
		return {"ok": false, "error": "style_locked", "style_id": style_id}
	WorldState.story_flags[ACTIVE_STYLE_STATE_KEY] = style_id
	WorldState._sync_aliases()
	return {"ok": true, "style_id": style_id, "style": style.duplicate(true)}

func purchase_node(node_id: String) -> Dictionary:
	var node := DataRegistry.get_skill_tree_node(node_id)
	if node.is_empty():
		return {"ok": false, "error": "node_not_found", "node_id": node_id}
	var levels := get_levels()
	var current_level := int(levels.get(node_id, 0))
	var max_level := int(node.get("max_level", 0))
	if current_level >= max_level:
		return {"ok": false, "error": "node_maxed", "node_id": node_id, "level": current_level}
	var cost := int(node.get("cost_per_level", 1))
	if WorldState.skill_points < cost:
		return {"ok": false, "error": "insufficient_skill_points", "node_id": node_id, "cost": cost}
	WorldState.skill_points -= cost
	current_level += 1
	levels[node_id] = current_level
	WorldState.story_flags[LEVELS_STATE_KEY] = levels
	if not WorldState.unlocked_skills.has(node_id):
		WorldState.unlocked_skills.append(node_id)
	WorldState._sync_aliases()
	SignalBus.skill_unlocked.emit("%s:%d" % [node_id, current_level])
	return {
		"ok": true,
		"node_id": node_id,
		"branch_id": str(node.get("branch_id", "")),
		"level": current_level,
		"skill_points": WorldState.skill_points
	}

func get_combat_modifiers() -> Dictionary:
	var output := {
		"style_id": get_active_style_id(),
		"starting_resources": {},
		"family_chance_bonus": {},
		"post_combat": {"money_multiplier": 1.0, "honor_win_bonus": 0.0, "hype_win_bonus": 0.0}
	}
	var style := get_active_style()
	var starting_resources: Dictionary = output["starting_resources"]
	var family_chance_bonus: Dictionary = output["family_chance_bonus"]
	var post_combat: Dictionary = output["post_combat"]
	_merge_numeric_map(starting_resources, style.get("starting_resources", {}), 1.0)
	_merge_numeric_map(family_chance_bonus, style.get("family_chance_bonus", {}), 1.0)
	_merge_numeric_map(post_combat, style.get("post_combat", {}), 1.0, true)

	var levels := get_levels()
	for branch_value in list_branches():
		for node_value in branch_value.get("nodes", []):
			var node_id := str(node_value.get("id", ""))
			var level := int(levels.get(node_id, 0))
			if level <= 0:
				continue
			var effects: Dictionary = node_value.get("effects_per_level", {})
			_merge_numeric_map(starting_resources, effects.get("starting_resources", {}), float(level))
			_merge_numeric_map(family_chance_bonus, effects.get("family_chance_bonus", {}), float(level))

	_apply_caps(output)
	return output

func apply_starting_resources(stats: Dictionary) -> Dictionary:
	var output := stats.duplicate(true)
	var starting: Dictionary = get_combat_modifiers().get("starting_resources", {})
	for resource_value in starting.keys():
		var resource := str(resource_value)
		output[resource] = clampf(float(output.get(resource, 0.0)) + float(starting[resource_value]), 0.0, 100.0)
	return output

func get_family_chance_bonus(family: String) -> float:
	return float(get_combat_modifiers().get("family_chance_bonus", {}).get(family, 0.0))

func get_post_combat_modifiers() -> Dictionary:
	return get_combat_modifiers().get("post_combat", {}).duplicate(true)

func get_cria_live_profile() -> Dictionary:
	return get_active_style().get("cria_live", {}).duplicate(true)

func get_snapshot() -> Dictionary:
	var unlocked := []
	for style_value in list_styles():
		var style_id := str(style_value.get("id", ""))
		if is_style_unlocked(style_id):
			unlocked.append(style_id)
	return {
		"active_style_id": get_active_style_id(),
		"levels": get_levels(),
		"skill_points": WorldState.skill_points,
		"unlocked_styles": unlocked,
		"modifiers": get_combat_modifiers()
	}

func _merge_numeric_map(target: Dictionary, source: Dictionary, multiplier: float, preserve_baseline := false) -> void:
	for key_value in source.keys():
		var key := str(key_value)
		var incoming := float(source[key_value])
		if preserve_baseline and key == "money_multiplier":
			target[key] = maxf(float(target.get(key, 1.0)), incoming)
		else:
			target[key] = float(target.get(key, 0.0)) + incoming * multiplier

func _apply_caps(modifiers: Dictionary) -> void:
	var limits: Dictionary = DataRegistry.fighter_styles.get("runtime_limits", {})
	var resource_cap := float(limits.get("starting_resource_bonus_cap", 20.0))
	for key_value in modifiers["starting_resources"].keys():
		modifiers["starting_resources"][key_value] = clampf(float(modifiers["starting_resources"][key_value]), -resource_cap, resource_cap)
	var chance_cap := float(limits.get("family_chance_bonus_cap", 0.12))
	for key_value in modifiers["family_chance_bonus"].keys():
		modifiers["family_chance_bonus"][key_value] = clampf(float(modifiers["family_chance_bonus"][key_value]), -chance_cap, chance_cap)
	var post: Dictionary = modifiers["post_combat"]
	post["money_multiplier"] = clampf(float(post.get("money_multiplier", 1.0)), 1.0, float(limits.get("win_money_multiplier_cap", 1.2)))
	var reputation_cap := float(limits.get("reputation_bonus_cap", 3.0))
	post["honor_win_bonus"] = clampf(float(post.get("honor_win_bonus", 0.0)), 0.0, reputation_cap)
	post["hype_win_bonus"] = clampf(float(post.get("hype_win_bonus", 0.0)), 0.0, reputation_cap)
