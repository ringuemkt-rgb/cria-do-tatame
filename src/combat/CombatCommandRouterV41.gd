class_name CombatCommandRouterV41
extends RefCounted

var combat: PositionalCardCombatV41

func setup(runtime: PositionalCardCombatV41) -> void:
	combat = runtime

func execute(actor_id: String, command: String, selected_card_id: String = "", quality: float = 0.5) -> Dictionary:
	if combat == null:
		return {"ok": false, "error": "combat_missing"}
	match command:
		"grip":
			return _grip(actor_id)
		"pressao":
			return _pressure(actor_id)
		"transicao":
			if selected_card_id != "":
				return combat.play_card(actor_id, selected_card_id, quality)
			return _generic_transition_preserving_loadout(actor_id)
		"defesa":
			if combat.phase == "defense_window":
				return combat.defend(actor_id, "generic", quality)
			return _recover_guard(actor_id)
		"encerrar":
			return _end_exchange(actor_id)
		_:
			return {"ok": false, "error": "unknown_command"}

func _grip(actor_id: String) -> Dictionary:
	if not combat.fighters.has(actor_id):
		return {"ok": false, "error": "fighter_missing"}
	var resources: Dictionary = combat.fighters[actor_id]
	if float(resources.get("gas", 0.0)) < 6.0:
		return {"ok": false, "error": "insufficient_gas"}
	combat.call("_adjust", actor_id, "gas", -6.0)
	combat.call("_adjust", actor_id, "grip", 1.0)
	combat.call("_adjust", actor_id, "foco", 3.0)
	combat.call("_emit_snapshot")
	return {"ok": true, "command": "grip", "snapshot": combat.snapshot()}

func _pressure(actor_id: String) -> Dictionary:
	if not combat.fighters.has(actor_id):
		return {"ok": false, "error": "fighter_missing"}
	var resources: Dictionary = combat.fighters[actor_id]
	if float(resources.get("gas", 0.0)) < 10.0:
		return {"ok": false, "error": "insufficient_gas"}
	combat.call("_adjust", actor_id, "gas", -10.0)
	combat.call("_adjust", actor_id, "pressao", 14.0)
	var defender := combat.opponent_id if actor_id == combat.player_id else combat.player_id
	combat.call("_adjust", defender, "guarda", -8.0)
	combat.call("_emit_snapshot")
	return {"ok": true, "command": "pressao", "snapshot": combat.snapshot()}

func _recover_guard(actor_id: String) -> Dictionary:
	if not combat.fighters.has(actor_id):
		return {"ok": false, "error": "fighter_missing"}
	var resources: Dictionary = combat.fighters[actor_id]
	if float(resources.get("gas", 0.0)) < 5.0:
		return {"ok": false, "error": "insufficient_gas"}
	combat.call("_adjust", actor_id, "gas", -5.0)
	combat.call("_adjust", actor_id, "guarda", 10.0)
	combat.call("_adjust", actor_id, "foco", 5.0)
	combat.call("_emit_snapshot")
	return {"ok": true, "command": "defesa", "snapshot": combat.snapshot()}

func _end_exchange(actor_id: String) -> Dictionary:
	if combat.phase == "submission":
		return combat.resolve_submission(0.0, 0.0, true)
	if not combat.fighters.has(actor_id):
		return {"ok": false, "error": "fighter_missing"}
	combat.position = "STANDING"
	combat.player_side = "any"
	combat.phase = "decision"
	combat.pending_action.clear()
	combat.call("_adjust", actor_id, "gas", 12.0)
	combat.call("_adjust", actor_id, "pressao", -10.0)
	combat.call("_draw_all_hands")
	combat.call("_emit_snapshot")
	return {"ok": true, "command": "encerrar", "snapshot": combat.snapshot()}

func _generic_transition_preserving_loadout(actor_id: String) -> Dictionary:
	var original_deck: Array = combat.decks.get(actor_id, []).duplicate()
	var result := combat.generic_transition(actor_id)
	combat.decks[actor_id] = original_deck
	if combat.phase == "decision":
		combat.call("_draw_all_hands")
		combat.call("_emit_snapshot")
	return result
