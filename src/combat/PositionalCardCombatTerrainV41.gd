extends "res://src/combat/PositionalCardCombatV41.gd"

const TerrainScript = preload("res://src/combat/TerrainModifiersV4.gd")

var terrain_tags: Array = []
var terrain_modifiers: Dictionary = TerrainScript.combine([])
var reduced_flash := false

func set_terrain_tags(tags: Array, reduce_flash: bool = false) -> Dictionary:
	var validation: Dictionary = TerrainScript.validate_tags(tags)
	if not bool(validation.get("ok", false)):
		return validation
	terrain_tags = tags.duplicate()
	reduced_flash = reduce_flash
	terrain_modifiers = TerrainScript.combine(terrain_tags, reduced_flash)
	if SignalBus.has_signal("terrain_modifiers_changed"):
		SignalBus.terrain_modifiers_changed.emit(terrain_tags.duplicate(), terrain_modifiers.duplicate(true))
	return {"ok": true, "tags": terrain_tags.duplicate(), "modifiers": terrain_modifiers.duplicate(true)}

func play_card(actor_id: String, card_id: String, input_quality: float = 0.5) -> Dictionary:
	var before_gas := _fighter_gas(actor_id)
	var card := _card_by_id(card_id)
	var result: Dictionary = super.play_card(actor_id, card_id, input_quality)
	if bool(result.get("ok", false)):
		_apply_extra_gas_cost(actor_id, before_gas, card.get("custo", {}), "transition")
		_apply_dirty_multiplier(actor_id, card)
		_apply_extra_positional_damage(result, card, input_quality >= 0.55)
	return result

func generic_transition(actor_id: String) -> Dictionary:
	var before_gas := _fighter_gas(actor_id)
	var result: Dictionary = super.generic_transition(actor_id)
	if bool(result.get("ok", false)):
		var spent := maxf(0.0, before_gas - _fighter_gas(actor_id))
		var multiplier := float(terrain_modifiers.get("gas_cost_mult", 1.0))
		var extra := spent * maxf(0.0, multiplier - 1.0)
		_drain_resource(actor_id, "gas", extra)
		call("_emit_snapshot")
	return result

func defend(actor_id: String, defense_id: String, timing_quality: float = 0.5) -> Dictionary:
	var adjusted_quality := clampf(timing_quality - float(terrain_modifiers.get("defense_threshold_add", 0.0)), 0.0, 1.0)
	var before_gas := _fighter_gas(actor_id)
	var result: Dictionary = super.defend(actor_id, defense_id, adjusted_quality)
	if bool(result.get("ok", false)):
		var spent := maxf(0.0, before_gas - _fighter_gas(actor_id))
		var multiplier := float(terrain_modifiers.get("escape_cost_mult", 1.0))
		_drain_resource(actor_id, "gas", spent * maxf(0.0, multiplier - 1.0))
		call("_emit_snapshot")
	return result

func tick(delta: float) -> void:
	super.tick(delta)
	if not active or phase == "finished":
		return
	var drain := float(terrain_modifiers.get("focus_drain_per_sec", 0.0)) * delta
	var regen_mult := float(terrain_modifiers.get("focus_regen_mult", 1.0))
	for fighter_id in fighters.keys():
		if drain > 0.0:
			_drain_resource(str(fighter_id), "foco", drain)
		elif regen_mult > 1.0:
			var fighter: Dictionary = fighters[fighter_id]
			fighter["foco"] = minf(100.0, float(fighter.get("foco", 0.0)) + (regen_mult - 1.0) * delta)
			fighters[fighter_id] = fighter
	call("_emit_snapshot")

func get_terrain_contract() -> Dictionary:
	return {"tags": terrain_tags.duplicate(), "modifiers": terrain_modifiers.duplicate(true), "reduced_flash": reduced_flash}

func _card_by_id(card_id: String) -> Dictionary:
	for card_value in cards_data.get("cartas", []):
		if str(card_value.get("id", "")) == card_id:
			return card_value
	return {}

func _fighter_gas(actor_id: String) -> float:
	return float(fighters.get(actor_id, {}).get("gas", 0.0))

func _apply_extra_gas_cost(actor_id: String, before_gas: float, base_cost: Dictionary, action_kind: String) -> void:
	var adjusted: Dictionary = TerrainScript.adjusted_cost(base_cost, terrain_modifiers, action_kind, true)
	var base_gas := float(base_cost.get("gas", 0.0))
	var extra := maxf(0.0, float(adjusted.get("gas", 0.0)) - base_gas)
	if before_gas > 0.0 and extra > 0.0:
		_drain_resource(actor_id, "gas", extra)
		call("_emit_snapshot")

func _apply_dirty_multiplier(actor_id: String, card: Dictionary) -> void:
	if str(card.get("moral", "limpa")) != "suja":
		return
	var multiplier := float(terrain_modifiers.get("dirty_roxo_mult", 1.0))
	var fighter: Dictionary = fighters.get(actor_id, {})
	fighter["tensao_moral"] = minf(100.0, float(fighter.get("tensao_moral", 0.0)) + 5.0 * multiplier)
	fighters[actor_id] = fighter
	WorldState.modify_reputation("sombra", 2.0 * multiplier)
	if SignalBus.has_signal("moral_tension_changed"):
		SignalBus.moral_tension_changed.emit(float(fighter["tensao_moral"]))

func _apply_extra_positional_damage(result: Dictionary, card: Dictionary, on_beat: bool) -> void:
	if bool(result.get("defended", false)) or str(card.get("tipo", "")) == "defesa":
		return
	var defender_id := str(result.get("defender_id", ""))
	if defender_id == "" or not fighters.has(defender_id):
		return
	var base_damage := float(card.get("dano_pos", 0.0))
	var adjusted := TerrainScript.adjusted_damage(base_damage, terrain_modifiers, on_beat)
	var extra := maxf(0.0, adjusted - base_damage)
	_drain_resource(defender_id, "integridade", extra)
	call("_emit_snapshot")

func _drain_resource(actor_id: String, resource: String, amount: float) -> void:
	if amount <= 0.0 or not fighters.has(actor_id):
		return
	var fighter: Dictionary = fighters[actor_id]
	fighter[resource] = maxf(0.0, float(fighter.get(resource, 0.0)) - amount)
	fighters[actor_id] = fighter
