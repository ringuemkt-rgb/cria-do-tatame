extends "res://src/autoloads/CombatManager.gd"

## Fachada Strangler Fig: preserva toda a API legada do CombatManager e adiciona
## o loop posicional do GDD-SYSTEMS v4.1 sem criar um segundo singleton.

const PositionalCombatScript = preload("res://src/combat/PositionalCardCombatV41.gd")
const SkillHubScript = preload("res://src/hub/SkillHubLoadoutV41.gd")
const CommandRouterScript = preload("res://src/combat/CombatCommandRouterV41.gd")
const PositionAdapterScript = preload("res://src/compat/PositionalCombatAdapter.gd")

var positional_runtime: Node
var skill_hub_v41: Node
var command_router_v41: RefCounted
var positional_mode_active := false
var positional_ruleset_id := "OFICIAL"
var selected_card_v41 := ""
var _pending_hub_state: Dictionary = {}

func _ready() -> void:
	super._ready()
	_ensure_v41_components()

func _process(delta: float) -> void:
	if positional_mode_active and positional_runtime != null and positional_runtime.has_method("tick"):
		positional_runtime.call("tick", delta)

func _ensure_v41_components() -> void:
	if skill_hub_v41 == null:
		skill_hub_v41 = SkillHubScript.new()
		skill_hub_v41.name = "SkillHubV41"
		add_child(skill_hub_v41)
		skill_hub_v41.call("configure", DataRegistry.combat_cards_v41)
		if not _pending_hub_state.is_empty():
			skill_hub_v41.call("import_state", _pending_hub_state)
			_pending_hub_state.clear()
	if positional_runtime == null:
		positional_runtime = PositionalCombatScript.new()
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

func start_positional_combat_v41(new_arena_id: String, new_player_id: String = DEFAULT_PLAYER_ID, new_opponent_id: String = DEFAULT_OPPONENT_ID, ruleset_id: String = "OFICIAL", player_deck: Array = [], opponent_deck: Array = []) -> Dictionary:
	_ensure_runtime_components()
	_ensure_v41_components()
	arena_id = new_arena_id if new_arena_id != "" else "terreiro_da_luta"
	player_id = new_player_id if new_player_id != "" else DEFAULT_PLAYER_ID
	opponent_id = new_opponent_id if new_opponent_id != "" else DEFAULT_OPPONENT_ID
	positional_ruleset_id = ruleset_id
	selected_card_v41 = ""
	last_result = {}
	phase = CombatPhase.DISTANCE
	is_running = true
	positional_mode_active = true
	state_machine.call("reiniciar_em_pe")

	_sync_owner_policy_v41(player_id)
	var resolved_player_deck := _resolve_v41_deck(player_id, player_deck)
	var resolved_opponent_deck := _resolve_v41_deck(opponent_id, opponent_deck)
	var configure_report: Dictionary = positional_runtime.call(
		"configure",
		DataRegistry.combat_cards_v41,
		DataRegistry.combat_positions_v41,
		DataRegistry.combat_rulesets_v41,
		{player_id: resolved_player_deck, opponent_id: resolved_opponent_deck},
		_build_v41_flags(),
		_build_v41_passives()
	)
	if not bool(configure_report.get("ok", false)):
		positional_mode_active = false
		is_running = false
		return {"ok": false, "error": "v41_data_invalid", "report": configure_report}
	var start_result: Dictionary = positional_runtime.call("start_combat", player_id, opponent_id, ruleset_id)
	if not bool(start_result.get("ok", false)):
		positional_mode_active = false
		is_running = false
		return start_result
	SignalBus.combat_started.emit(arena_id, player_id, opponent_id)
	if SignalBus.has_signal("combate_iniciado"):
		SignalBus.combate_iniciado.emit(StringName(opponent_id))
	if SignalBus.has_signal("positional_mode_changed"):
		SignalBus.positional_mode_changed.emit(true, ruleset_id)
	_on_v41_snapshot(start_result.get("snapshot", {}))
	return {
		"ok": true,
		"arena_id": arena_id,
		"player_id": player_id,
		"opponent_id": opponent_id,
		"ruleset_id": ruleset_id,
		"snapshot": get_positional_snapshot_v41(),
	}

func stop_positional_mode_v41() -> void:
	positional_mode_active = false
	selected_card_v41 = ""
	if SignalBus.has_signal("positional_mode_changed"):
		SignalBus.positional_mode_changed.emit(false, positional_ruleset_id)

func get_positional_snapshot_v41() -> Dictionary:
	if positional_runtime == null:
		return {}
	return positional_runtime.call("snapshot")

func get_contextual_hand_v41(actor_id: String = "") -> Array:
	if positional_runtime == null or not positional_mode_active:
		return []
	var resolved_actor := actor_id if actor_id != "" else player_id
	return positional_runtime.call("get_contextual_hand", resolved_actor)

func select_card_v41(card_id: String) -> Dictionary:
	if not positional_mode_active:
		return {"ok": false, "error": "positional_mode_inactive"}
	var hand := get_contextual_hand_v41(player_id)
	for card_value in hand:
		if str(card_value.get("id", "")) == card_id:
			selected_card_v41 = card_id
			if SignalBus.has_signal("combat_card_selected_v41"):
				SignalBus.combat_card_selected_v41.emit(card_id)
			return {"ok": true, "card_id": card_id, "playable": bool(card_value.get("playable", false))}
	return {"ok": false, "error": "card_not_in_hand"}

func play_card_v41(actor_id: String, card_id: String, input_quality: float = 0.5) -> Dictionary:
	if not positional_mode_active or positional_runtime == null:
		return {"ok": false, "error": "positional_mode_inactive"}
	var result: Dictionary = positional_runtime.call("play_card", actor_id, card_id, input_quality)
	if bool(result.get("ok", false)) and actor_id == player_id:
		selected_card_v41 = ""
	return result

func defend_v41(actor_id: String, defense_id: String = "generic", timing_quality: float = 0.5) -> Dictionary:
	if not positional_mode_active or positional_runtime == null:
		return {"ok": false, "error": "positional_mode_inactive"}
	return positional_runtime.call("defend", actor_id, defense_id, timing_quality)

func execute_command_v41(actor_id: String, command: String, card_id: String = "", quality: float = 0.5) -> Dictionary:
	if not positional_mode_active or command_router_v41 == null:
		return {"ok": false, "error": "positional_mode_inactive"}
	var selected := card_id
	if command == "transicao" and selected == "" and actor_id == player_id:
		selected = selected_card_v41
	var result: Dictionary = command_router_v41.call("execute", actor_id, command, selected, quality)
	if bool(result.get("ok", false)) and command == "transicao" and actor_id == player_id:
		selected_card_v41 = ""
	return result

func resolve_submission_v41(attacker_progress: float, defender_progress: float, attacker_releases: bool = false) -> Dictionary:
	if not positional_mode_active or positional_runtime == null:
		return {"ok": false, "error": "positional_mode_inactive"}
	return positional_runtime.call("resolve_submission", attacker_progress, defender_progress, attacker_releases)

func resolve_ruleset_objective_v41(method: String, winner_id: String, loser_id: String = "") -> Dictionary:
	if not positional_mode_active or positional_runtime == null:
		return {"ok": false, "error": "positional_mode_inactive"}
	return positional_runtime.call("resolve_ruleset_objective", method, winner_id, loser_id)

func get_skill_hub_v41() -> Node:
	_ensure_v41_components()
	return skill_hub_v41

func export_v41_state() -> Dictionary:
	_ensure_v41_components()
	return {
		"hub": skill_hub_v41.call("export_state"),
		"selected_card": selected_card_v41,
		"ruleset_id": positional_ruleset_id,
	}

func import_v41_state(data: Dictionary) -> void:
	if skill_hub_v41 == null:
		_pending_hub_state = data.get("hub", {}).duplicate(true)
	else:
		skill_hub_v41.call("import_state", data.get("hub", {}))
	selected_card_v41 = str(data.get("selected_card", ""))
	positional_ruleset_id = str(data.get("ruleset_id", "OFICIAL"))

func _resolve_v41_deck(owner_id: String, requested: Array) -> Array:
	_ensure_v41_components()
	if not requested.is_empty():
		_unlock_requested_cards(owner_id, requested)
		skill_hub_v41.call("set_deck_points", owner_id, 100)
		var set_result: Dictionary = skill_hub_v41.call("set_loadout", owner_id, requested)
		if bool(set_result.get("ok", false)):
			return skill_hub_v41.call("get_loadout", owner_id)
	var stored: Array = skill_hub_v41.call("get_loadout", owner_id)
	if stored.size() == 12:
		return stored
	var starter := _default_v41_deck()
	_unlock_requested_cards(owner_id, starter)
	skill_hub_v41.call("set_deck_points", owner_id, 100)
	skill_hub_v41.call("set_loadout", owner_id, starter)
	return skill_hub_v41.call("get_loadout", owner_id)

func _unlock_requested_cards(owner_id: String, cards: Array) -> void:
	for card_id_value in cards:
		var card_id := str(card_id_value)
		var card: Dictionary = DataRegistry.get_combat_card_v41(card_id)
		if card.is_empty():
			continue
		if str(card.get("raridade", "base")) != "base":
			skill_hub_v41.call("unlock_for_owner", owner_id, card_id, "training")

func _default_v41_deck() -> Array:
	return [
		"grip_de_ferro", "baiana", "guarda_fechada", "raspagem_tesoura",
		"knee_cut_pass", "cem_quilos", "montada", "kimura",
		"triangulo", "mata_leao", "grip_de_ferro", "baiana",
	]

func _sync_owner_policy_v41(owner_id: String) -> void:
	var forbidden: Array[String] = []
	if bool(WorldState.flags.get("dirty_cards_forbidden", false)):
		forbidden.append("suja")
	skill_hub_v41.call("set_owner_policy", owner_id, {"forbidden_morals": forbidden})

func _build_v41_flags() -> Dictionary:
	return {
		"honra": int(WorldState.reputation.get("honra", 0)),
		"raiz": int(WorldState.reputation.get("raiz", 0)),
		"roxo": int(WorldState.reputation.get("sombra", 0)),
		"bencao_mare": bool(WorldState.flags.get("bencao_mare", false)),
		"leoa_vinculo": int(WorldState.flags.get("leoa_vinculo", 0)),
		"dende_confianca": int(WorldState.flags.get("dende_confianca", 0)),
		"owner_policies": {
			player_id: skill_hub_v41.call("get_owner_policy", player_id),
			opponent_id: skill_hub_v41.call("get_owner_policy", opponent_id),
		},
	}

func _build_v41_passives() -> Dictionary:
	var stored: Dictionary = WorldState.flags.get("combat_passives", {})
	return {
		player_id: stored.get(player_id, {}).duplicate(true),
		opponent_id: stored.get(opponent_id, {}).duplicate(true),
	}

func _on_v41_snapshot(snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		return
	var v41_fighters: Dictionary = snapshot.get("fighters", {})
	fighters = {
		player_id: _legacy_resources_from_v41(v41_fighters.get(player_id, {})),
		opponent_id: _legacy_resources_from_v41(v41_fighters.get(opponent_id, {})),
	}
	var legacy_state := PositionAdapterScript.v4_to_legacy(str(snapshot.get("position", "STANDING")), str(snapshot.get("player_side", "any")))
	_apply_state_transition(legacy_state)
	phase = _legacy_phase_from_v41(str(snapshot.get("position", "STANDING")))
	_emit_resources()
	if SignalBus.has_signal("positional_snapshot_changed"):
		SignalBus.positional_snapshot_changed.emit(snapshot.duplicate(true))
	if SignalBus.has_signal("combat_hand_changed_v41"):
		SignalBus.combat_hand_changed_v41.emit(get_contextual_hand_v41(player_id))

func _legacy_resources_from_v41(resources: Dictionary) -> Dictionary:
	return {
		"health": float(resources.get("integridade", 100.0)),
		"gas": float(resources.get("gas", 100.0)),
		"focus": float(resources.get("foco", 100.0)),
		"grip": float(resources.get("grip", 0.0)) * 33.333,
		"guard": float(resources.get("guarda", 100.0)),
		"grip_integrity": float(resources.get("guarda", 100.0)),
		"control": float(resources.get("pressao", 0.0)),
		"moral": 100.0 - float(resources.get("tensao_moral", 0.0)),
	}

func _legacy_phase_from_v41(position: String) -> int:
	match position:
		"STANDING": return CombatPhase.DISTANCE
		"CLINCH": return CombatPhase.CLINCH
		"GUARD", "HALF", "SIDE_CONTROL", "MOUNT", "BACK_CONTROL": return CombatPhase.GROUND
		"SUBMISSION": return CombatPhase.TECHNICAL
		_: return CombatPhase.TRANSITION

func _on_v41_defense_window(window: Dictionary) -> void:
	if SignalBus.has_signal("defense_window_opened_v41"):
		SignalBus.defense_window_opened_v41.emit(window.duplicate(true))

func _on_v41_card_resolved(result: Dictionary) -> void:
	last_result = result.duplicate(true)
	last_result["v41"] = true
	last_result["fighters"] = fighters.duplicate(true)
	SignalBus.technique_resolved.emit(last_result)

func _on_v41_dirty_move(card_id: String) -> void:
	if SignalBus.has_signal("dirty_move_attempted"):
		SignalBus.dirty_move_attempted.emit(card_id)
	WorldState.modify_reputation("sombra", 2.0)

func _on_v41_combat_finished(result: Dictionary) -> void:
	if not positional_mode_active or not is_running:
		return
	positional_mode_active = false
	var winner := str(result.get("winner_id", ""))
	var loser := str(result.get("loser_id", ""))
	finish_combat({
		"winner": winner,
		"loser": loser,
		"method": str(result.get("method", "positional_v41")),
		"technical": str(result.get("method", "")) == "finalizacao",
		"ruleset_id": positional_ruleset_id,
		"scores": result.get("scores", {}).duplicate(true),
		"v41": true,
	})
	if SignalBus.has_signal("positional_mode_changed"):
		SignalBus.positional_mode_changed.emit(false, positional_ruleset_id)
