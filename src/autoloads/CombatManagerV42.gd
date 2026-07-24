extends "res://src/autoloads/CombatManagerV41.gd"

const TerrainRuntimeScript = preload("res://src/combat/PositionalCardCombatTerrainV41.gd")

var current_terrain_tags_v41: Array = []
var reduced_flash_v41 := false

func _ensure_v41_components() -> void:
	if skill_hub_v41 == null:
		skill_hub_v41 = SkillHubScript.new()
		skill_hub_v41.name = "SkillHubV41"
		add_child(skill_hub_v41)
		skill_hub_v41.call("configure", DataRegistry.combat_cards_v41)
		if not _pending_hub_state.is_empty():
			skill_hub_v41.call("import_state", _pending_hub_state)
			_pending_hub_state.clear()
	if positional_runtime == null or positional_runtime.get_script() != TerrainRuntimeScript:
		if positional_runtime != null:
			for connection in [
				["snapshot_changed", Callable(self, "_on_v41_snapshot")],
				["action_window_opened", Callable(self, "_on_v41_defense_window")],
				["card_resolved", Callable(self, "_on_v41_card_resolved")],
				["combat_finished", Callable(self, "_on_v41_combat_finished")],
				["dirty_move_attempted", Callable(self, "_on_v41_dirty_move")],
			]:
				if positional_runtime.is_connected(str(connection[0]), connection[1]):
					positional_runtime.disconnect(str(connection[0]), connection[1])
			remove_child(positional_runtime)
			positional_runtime.free()
		positional_runtime = TerrainRuntimeScript.new()
		positional_runtime.name = "PositionalRuntimeV41"
		add_child(positional_runtime)
		positional_runtime.connect("snapshot_changed", _on_v41_snapshot)
		positional_runtime.connect("action_window_opened", _on_v41_defense_window)
		positional_runtime.connect("card_resolved", _on_v41_card_resolved)
		positional_runtime.connect("combat_finished", _on_v41_combat_finished)
		positional_runtime.connect("dirty_move_attempted", _on_v41_dirty_move)
	if command_router_v41 == null:
		command_router_v41 = CommandRouterScript.new()
	command_router_v41.call("setup", positional_runtime)
	if not current_terrain_tags_v41.is_empty():
		positional_runtime.call("set_terrain_tags", current_terrain_tags_v41, reduced_flash_v41)

func start_positional_combat_v41(new_arena_id: String, new_player_id: String = DEFAULT_PLAYER_ID, new_opponent_id: String = DEFAULT_OPPONENT_ID, ruleset_id: String = "OFICIAL", player_deck: Array = [], opponent_deck: Array = []) -> Dictionary:
	var result: Dictionary = super.start_positional_combat_v41(new_arena_id, new_player_id, new_opponent_id, ruleset_id, player_deck, opponent_deck)
	if bool(result.get("ok", false)):
		var tags := _resolve_arena_tags_v41(new_arena_id)
		set_terrain_tags_v41(tags, _reduce_flash_enabled())
		result["terrain"] = get_terrain_contract_v41()
	return result

func set_terrain_tags_v41(tags: Array, reduce_flash: bool = false) -> Dictionary:
	_ensure_v41_components()
	current_terrain_tags_v41 = tags.duplicate()
	reduced_flash_v41 = reduce_flash
	return positional_runtime.call("set_terrain_tags", current_terrain_tags_v41, reduced_flash_v41)

func get_terrain_contract_v41() -> Dictionary:
	if positional_runtime != null and positional_runtime.has_method("get_terrain_contract"):
		return positional_runtime.call("get_terrain_contract")
	return {"tags": current_terrain_tags_v41.duplicate(), "modifiers": {}, "reduced_flash": reduced_flash_v41}

func export_v41_state() -> Dictionary:
	var data: Dictionary = super.export_v41_state()
	data["terrain_tags"] = current_terrain_tags_v41.duplicate()
	data["reduced_flash"] = reduced_flash_v41
	return data

func import_v41_state(data: Dictionary) -> void:
	super.import_v41_state(data)
	current_terrain_tags_v41 = data.get("terrain_tags", []).duplicate()
	reduced_flash_v41 = bool(data.get("reduced_flash", false))
	if positional_runtime != null and positional_runtime.has_method("set_terrain_tags"):
		positional_runtime.call("set_terrain_tags", current_terrain_tags_v41, reduced_flash_v41)

func _resolve_arena_tags_v41(resolved_arena_id: String) -> Array:
	var arena: Dictionary = DataRegistry.get_arena(resolved_arena_id)
	var tags: Array = arena.get("terrain_tags", arena.get("tags", [])).duplicate()
	if not tags.is_empty():
		return tags
	var current_node := WorldMapManager.get_node_data(WorldMapManager._current_node_id()) if WorldMapManager.has_method("get_node_data") else {}
	if not current_node.is_empty():
		return current_node.get("tags", []).duplicate()
	if resolved_arena_id == "terreiro_da_luta":
		return ["silencio_eco"]
	return []

func _reduce_flash_enabled() -> bool:
	return bool(DataRegistry.settings.get("accessibility", {}).get("reduce_flash", false))
