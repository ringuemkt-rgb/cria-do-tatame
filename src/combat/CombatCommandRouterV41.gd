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
			return combat.generic_transition(actor_id)
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
	resources["gas"] = maxf(0.0, float(resources.get("gas", 0.0)) - 6.0)
	resources["grip"] = minf(3.0, float(resources.get("grip", 0.0)) + 1.0)
	resources["foco"] = minf(100.0, float(resources.get("foco", 0.0)) + 3.0)
	combat.call("_emit_snapshot")
	return {"ok": true, "command": "grip", "snapshot": combat.snapshot()}

func _pressure(actor_id: String) -> Dictionary:
	if not combat.fighters.has(actor_id):
		return {"ok": false, "error": "fighter_missing"}
	var resources: Dictionary = combat.fighters[actor_id]
	if float(resources.get("gas", 0.0)) < 10.0:
		return {"ok": false, "error": "insufficient_gas"}
	resources["gas"] = maxf(0.0, float(resources.get("gas", 0.0)) - 10.0)
	resources["pressao"] = minf(100.0, float(resources.get("pressao", 0.0)) + 14.0)
	var defender := combat.opponent_id if actor_id == combat.player_id else combat.player_id
	combat.fighters[defender]["guarda"] = maxf(0.0, float(combat.fighters[defender].get("guarda", 0.0)) - 8.0)
	combat.call("_emit_snapshot")
	return {"ok": true, "command": "pressao", "snapshot": combat.snapshot()}

func _recover_guard(actor_id: String) -> Dictionary:
	if not combat.fighters.has(actor_id):
		return {"ok": false, "error": "fighter_missing"}
	var resources: Dictionary = combat.fighters[actor_id]
	if float(resources.get("gas", 0.0)) < 5.0:
		return {"ok": false, "error": "insufficient_gas"}
	resources["gas"] = maxf(0.0, float(resources.get("gas", 0.0)) - 5.0)
	resources["guarda"] = minf(100.0, float(resources.get("guarda", 0.0)) + 10.0)
	resources["foco"] = minf(100.0, float(resources.get("foco", 0.0)) + 5.0)
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
	var resources: Dictionary = combat.fighters[actor_id]
	resources["gas"] = minf(100.0, float(resources.get("gas", 0.0)) + 12.0)
	resources["pressao"] = maxf(0.0, float(resources.get("pressao", 0.0)) - 10.0)
	combat.call("_draw_all_hands")
	combat.call("_emit_snapshot")
	return {"ok": true, "command": "encerrar", "snapshot": combat.snapshot()}
