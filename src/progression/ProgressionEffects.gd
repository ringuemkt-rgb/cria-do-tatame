class_name ProgressionEffects
extends RefCounted

## Fachada sem UI para publicar os efeitos da árvore nos sistemas consumidores.
## O chamador continua responsável por validar custo, pré-requisitos e persistência do nó.

static func apply_skill_node(
	node_id: String,
	effect: Dictionary,
	owner_id: String,
	skill_hub: Node,
	world_state: Node
) -> Dictionary:
	var effect_type := str(effect.get("type", ""))
	match effect_type:
		"deck_points":
			if skill_hub == null or not skill_hub.has_method("set_deck_points"):
				return {"ok": false, "error": "skill_hub_missing"}
			var points := int(effect.get("value", effect.get("points", 0)))
			skill_hub.call("set_deck_points", owner_id, points)
			return {"ok": true, "effect": effect_type, "points": points}
		"desbloqueia_carta":
			if skill_hub == null or not skill_hub.has_method("unlock_for_owner"):
				return {"ok": false, "error": "skill_hub_missing"}
			return skill_hub.call("unlock_for_owner", owner_id, str(effect.get("card_id", "")), "skill_tree")
		"remove_cartas_sujas":
			if skill_hub == null or not skill_hub.has_method("forbid_moral_for_owner"):
				return {"ok": false, "error": "skill_hub_missing"}
			var result: Dictionary = skill_hub.call("forbid_moral_for_owner", owner_id, "suja")
			if bool(result.get("ok", false)) and world_state != null and world_state.has_method("set_narrative_flag"):
				world_state.call("set_narrative_flag", "dirty_cards_forbidden", true)
			return result
		"path_gate_final":
			if world_state == null or not world_state.has_method("set_narrative_flag"):
				return {"ok": false, "error": "world_state_missing"}
			var flag_key := str(effect.get("flag", "moral_nao_humilhar"))
			world_state.call("set_narrative_flag", flag_key, true)
			return {"ok": true, "effect": effect_type, "flag": flag_key}
		"passivo_stat":
			return _apply_passive_stat(effect, owner_id, world_state)
		_:
			# Compatibilidade para os dois nós morais antes de tree.json estabilizar.
			if node_id == "respeito_nao_humilhar":
				return apply_skill_node(node_id, {"type": "path_gate_final", "flag": "moral_nao_humilhar"}, owner_id, skill_hub, world_state)
			if node_id == "respeito_codigo_do_cria":
				return apply_skill_node(node_id, {"type": "remove_cartas_sujas"}, owner_id, skill_hub, world_state)
			return {"ok": false, "error": "unsupported_effect", "node_id": node_id, "effect_type": effect_type}

static func _apply_passive_stat(effect: Dictionary, owner_id: String, world_state: Node) -> Dictionary:
	if world_state == null or not world_state.has_method("get_narrative_flag") or not world_state.has_method("set_narrative_flag"):
		return {"ok": false, "error": "world_state_missing"}
	var stat := str(effect.get("stat", ""))
	if stat == "":
		return {"ok": false, "error": "passive_stat_missing"}
	var all_passives: Dictionary = world_state.call("get_narrative_flag", "combat_passives", {}).duplicate(true)
	var owner_passives: Dictionary = all_passives.get(owner_id, {}).duplicate(true)
	var mode := str(effect.get("mode", "set"))
	var value := float(effect.get("value", 0.0))
	match mode:
		"add": owner_passives[stat] = float(owner_passives.get(stat, 0.0)) + value
		"multiply": owner_passives[stat] = float(owner_passives.get(stat, 1.0)) * value
		_: owner_passives[stat] = value
	all_passives[owner_id] = owner_passives
	world_state.call("set_narrative_flag", "combat_passives", all_passives)
	return {"ok": true, "effect": "passivo_stat", "owner_id": owner_id, "stat": stat, "value": owner_passives[stat]}
