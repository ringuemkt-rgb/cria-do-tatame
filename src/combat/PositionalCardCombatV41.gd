class_name PositionalCardCombatV41
extends Node

## Motor data-driven do GDD-SYSTEMS v4.1.
## Usa 8 posições simétricas + lado relativo do jogador.
## Não substitui CombatManager durante a migração; deve ser consumido por adapter/fachada.

signal snapshot_changed(snapshot: Dictionary)
signal action_window_opened(window: Dictionary)
signal card_resolved(result: Dictionary)
signal combat_finished(result: Dictionary)
signal dirty_move_attempted(card_id: String)
signal victory_rejected(candidate: Dictionary, ruleset_id: String)

const PassiveSnapshotScript = preload("res://src/combat/CombatPassiveSnapshot.gd")
const POSITIONS := ["STANDING", "CLINCH", "GUARD", "HALF", "SIDE_CONTROL", "MOUNT", "BACK_CONTROL", "SUBMISSION"]
const SIDES := ["any", "top", "bottom"]
const DEFAULT_RESOURCES := {
	"integridade": 100.0,
	"gas": 100.0,
	"foco": 100.0,
	"grip": 0.0,
	"pressao": 0.0,
	"guarda": 100.0,
	"tensao_moral": 0.0,
}

var cards: Dictionary = {}
var position_data: Dictionary = {}
var rulesets: Dictionary = {}
var flags: Dictionary = {}
var decks: Dictionary = {}
var hands: Dictionary = {}
var draw_cursor: Dictionary = {}
var fighters: Dictionary = {}
var scores: Dictionary = {}
var passive_snapshots: Dictionary = {}
var position: String = "STANDING"
var player_side: String = "any"
var player_id: String = ""
var opponent_id: String = ""
var ruleset_id: String = "OFICIAL"
var phase: String = "ready"
var pending_action: Dictionary = {}
var time_left: float = 0.0

func configure(
	cards_payload: Dictionary,
	positions_payload: Dictionary,
	rulesets_payload: Dictionary,
	fighter_decks: Dictionary,
	narrative_flags: Dictionary = {},
	fighter_passives: Dictionary = {}
) -> Dictionary:
	cards.clear()
	for raw in cards_payload.get("cartas", []):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var card: Dictionary = raw.duplicate(true)
		var card_id := str(card.get("id", ""))
		if card_id != "":
			cards[card_id] = card
	position_data = positions_payload.get("posicoes", {}).duplicate(true)
	rulesets = rulesets_payload.get("rulesets", {}).duplicate(true)
	decks = fighter_decks.duplicate(true)
	flags = narrative_flags.duplicate(true)
	passive_snapshots.clear()
	for fighter_id_value in fighter_decks.keys():
		var fighter_id := str(fighter_id_value)
		passive_snapshots[fighter_id] = PassiveSnapshotScript.normalize(fighter_passives.get(fighter_id, {}))
	return {
		"ok": cards.size() == 20 and position_data.size() == 8 and rulesets.size() == 6,
		"cards": cards.size(),
		"positions": position_data.size(),
		"rulesets": rulesets.size(),
		"passive_snapshots": passive_snapshots.size(),
	}

func start_combat(new_player_id: String, new_opponent_id: String, new_ruleset_id: String = "OFICIAL") -> Dictionary:
	if new_player_id == "" or new_opponent_id == "" or new_player_id == new_opponent_id:
		return {"ok": false, "error": "invalid_fighters"}
	if not rulesets.has(new_ruleset_id):
		return {"ok": false, "error": "invalid_ruleset"}
	player_id = new_player_id
	opponent_id = new_opponent_id
	ruleset_id = new_ruleset_id
	fighters = {
		player_id: _initial_resources(player_id),
		opponent_id: _initial_resources(opponent_id),
	}
	scores = {player_id: 0, opponent_id: 0}
	position = "STANDING"
	player_side = "any"
	pending_action.clear()
	hands.clear()
	draw_cursor.clear()
	time_left = float(rulesets[ruleset_id].get("timer_seg", 0))
	phase = "decision"
	_draw_hand(player_id)
	_draw_hand(opponent_id)
	_emit_snapshot()
	return {"ok": true, "snapshot": snapshot()}

func tick(delta: float) -> void:
	if phase == "finished" or phase == "ready":
		return
	_regenerate(delta)
	if not pending_action.is_empty():
		pending_action["time_left"] = maxf(0.0, float(pending_action.get("time_left", 0.0)) - delta)
		if float(pending_action["time_left"]) <= 0.0:
			_resolve_pending(false, "window_expired")
	var configured_timer := int(rulesets.get(ruleset_id, {}).get("timer_seg", 0))
	if configured_timer > 0:
		time_left = maxf(0.0, time_left - delta)
		if time_left <= 0.0:
			_finish_by_points()
	_emit_snapshot()

## Única fonte de verdade para HUD, IA e comandos.
func pode_jogar(fighter_id: String, card_id: String) -> Dictionary:
	if not cards.has(card_id):
		return _blocked("CARD_MISSING", "card_missing")
	if not fighters.has(fighter_id):
		return _blocked("FIGHTER_MISSING", "fighter_missing", cards[card_id])
	if not decks.get(fighter_id, []).has(card_id):
		return _blocked("CARD_NOT_IN_LOADOUT", "card_not_in_loadout", cards[card_id])
	var card: Dictionary = cards[card_id]
	if not _profile_allows(fighter_id, card):
		return _blocked("CARD_FORBIDDEN_BY_PROFILE", "card_forbidden_by_profile", card)
	if not hands.get(fighter_id, []).has(card_id):
		return _blocked("CARD_NOT_IN_HAND", "card_not_in_hand", card)
	if not _matches_position(fighter_id, card):
		return _blocked("POSITION_INVALID", "wrong_position_or_side", card)
	if not _flag_requirement_met(str(card.get("requisito_flag", ""))):
		return _blocked("STORY_REQUIREMENT", "story_requirement", card)
	var dirty_rule := str(rulesets[ruleset_id].get("cartas_sujas", "banida_desclassifica"))
	if str(card.get("moral", "limpa")) == "suja" and dirty_rule in ["banida_desclassifica", "falha_rito"]:
		return _blocked("RULESET_FORBIDS_CARD", dirty_rule, card)
	if not _has_cost(fighter_id, card.get("custo", {})):
		return _blocked("RESOURCE_INSUFFICIENT", "insufficient_resources", card)
	if phase != "decision":
		return _blocked("DECISION_LOCKED", "decision_locked", card)
	return _playability_result(true, "OK", "ok", card)

func can_play_card(fighter_id: String, card_id: String) -> Dictionary:
	return pode_jogar(fighter_id, card_id)

func play_card(fighter_id: String, card_id: String, input_quality: float = 0.5) -> Dictionary:
	var validation := pode_jogar(fighter_id, card_id)
	if not bool(validation.get("ok", false)):
		if str(validation.get("reason", "")) in ["banida_desclassifica", "falha_rito"]:
			dirty_move_attempted.emit(card_id)
		return {"ok": false, "error": validation.get("reason", "blocked"), "playability": validation}
	var card: Dictionary = cards[card_id]
	_consume_cost(fighter_id, card.get("custo", {}))
	if str(card.get("moral", "limpa")) == "suja":
		dirty_move_attempted.emit(card_id)
		_adjust(fighter_id, "tensao_moral", 20.0)
	var defender_id := _other(fighter_id)
	var window := maxf(0.0, float(card.get("janela", 0.0)))
	if window <= 0.0 or str(card.get("vs_defesa", "nenhum")) == "nenhum":
		return _resolve_card_success(fighter_id, defender_id, card)
	pending_action = {
		"attacker_id": fighter_id,
		"defender_id": defender_id,
		"card_id": card_id,
		"defense": str(card.get("vs_defesa", "nenhum")),
		"time_left": window * lerpf(1.15, 0.75, clampf(input_quality, 0.0, 1.0)),
	}
	phase = "defense_window"
	action_window_opened.emit(pending_action.duplicate(true))
	_emit_snapshot()
	return {"ok": true, "window": pending_action.duplicate(true)}

func defend(fighter_id: String, defense_id: String, timing_quality: float) -> Dictionary:
	if phase != "defense_window" or pending_action.is_empty():
		return {"ok": false, "error": "no_defense_window"}
	if fighter_id != str(pending_action.get("defender_id", "")):
		return {"ok": false, "error": "not_defender"}
	var expected := str(pending_action.get("defense", "nenhum"))
	var labels := expected.split("_")
	var correct := defense_id == expected or labels.has(defense_id) or defense_id == "generic"
	var focus := float(fighters[fighter_id].get("foco", 0.0))
	var attacker := str(pending_action.get("attacker_id", ""))
	var pressure := float(fighters[attacker].get("pressao", 0.0))
	var threshold := clampf(0.55 + pressure / 250.0 - focus / 300.0, 0.25, 0.85)
	return _resolve_pending(correct and timing_quality >= threshold, defense_id)

func generic_transition(fighter_id: String, transition_index: int = 0) -> Dictionary:
	if phase != "decision":
		return {"ok": false, "error": "decision_locked"}
	var side := _side_for(fighter_id)
	var pos: Dictionary = position_data.get(position, {})
	var side_data: Dictionary = pos.get("lados", {}).get(side, pos.get("lados", {}).get("any", {}))
	var options: Array = side_data.get("transicoes_genericas", [])
	if transition_index < 0 or transition_index >= options.size():
		return {"ok": false, "error": "no_generic_transition"}
	var generic: Dictionary = options[transition_index].duplicate(true)
	generic["id"] = str(generic.get("id", "generic"))
	generic["origem"] = [position]
	generic["lado"] = side
	generic["tipo"] = "transicao"
	generic["moral"] = "limpa"
	generic["janela"] = 0.45 if str(generic.get("vs_defesa", "nenhum")) != "nenhum" else 0.0
	generic["custo"] = generic.get("custo", {})
	generic["deck_cost"] = 0
	cards[generic["id"]] = generic
	decks[fighter_id] = [generic["id"]]
	hands[fighter_id] = [generic["id"]]
	return play_card(fighter_id, generic["id"], 0.5)

func resolve_submission(attacker_progress: float, defender_progress: float, attacker_releases: bool = false) -> Dictionary:
	if phase != "submission":
		return {"ok": false, "error": "submission_not_active"}
	var attacker := str(pending_action.get("attacker_id", player_id if player_side == "top" else opponent_id))
	var defender := _other(attacker)
	if attacker_releases:
		var release_resolution := try_resolve_victory({"method": "ceder", "winner_id": attacker, "loser_id": defender})
		if bool(release_resolution.get("accepted", false)):
			return {"ok": true, "released": true, "winner": attacker, "method": "ceder"}
		position = "STANDING"
		player_side = "any"
		phase = "decision"
		pending_action.clear()
		_adjust(attacker, "tensao_moral", -10.0)
		_draw_all_hands()
		return {"ok": true, "released": true, "victory": release_resolution}
	var attacker_passives := get_passive_snapshot(attacker)
	var defender_passives := get_passive_snapshot(defender)
	var attack_power := clampf(attacker_progress, 0.0, 1.0)
	attack_power *= float(attacker_passives.get("sweet_spot_mult", 1.0))
	attack_power *= float(attacker_passives.get("submission_attack_mult", 1.0))
	attack_power += float(fighters[attacker].get("grip", 0.0)) * 0.06
	var defense_power := clampf(defender_progress, 0.0, 1.0)
	defense_power *= float(defender_passives.get("submission_defense_mult", 1.0))
	defense_power += float(fighters[defender].get("foco", 0.0)) / 220.0
	if attack_power >= defense_power + 0.12:
		var resolution := try_resolve_victory({"method": "finalizacao", "winner_id": attacker, "loser_id": defender})
		if bool(resolution.get("accepted", false)):
			_adjust(defender, "integridade", -100.0)
			return {"ok": true, "winner": attacker, "method": "finalizacao", "victory": resolution}
		_reset_after_blocked_submission(attacker, defender)
		return {"ok": true, "victory_blocked": true, "method": "finalizacao", "victory": resolution}
	position = "GUARD"
	player_side = "bottom" if attacker == player_id else "top"
	phase = "decision"
	pending_action.clear()
	_adjust(attacker, "gas", -15.0)
	_adjust(defender, "gas", -10.0)
	_draw_all_hands()
	return {"ok": true, "escaped": true}

func resolve_ruleset_objective(method: String, winner_id: String, loser_id: String = "") -> Dictionary:
	return try_resolve_victory({"method": method, "winner_id": winner_id, "loser_id": loser_id})

func try_resolve_victory(candidate: Dictionary) -> Dictionary:
	var method := str(candidate.get("method", ""))
	var allowed: Array = rulesets.get(ruleset_id, {}).get("caminhos_vitoria", [])
	if method == "" or not allowed.has(method):
		var rejected := {
			"accepted": false,
			"method": method,
			"ruleset_id": ruleset_id,
			"allowed_methods": allowed.duplicate(),
		}
		victory_rejected.emit(candidate.duplicate(true), ruleset_id)
		return rejected
	var winner := str(candidate.get("winner_id", ""))
	var loser := str(candidate.get("loser_id", ""))
	_finish(winner, loser, method)
	return {"accepted": true, "method": method, "ruleset_id": ruleset_id, "winner_id": winner, "loser_id": loser}

func apply_external_focus_drain(fighter_id: String, amount: float, _source: String = "arena") -> float:
	var passive := get_passive_snapshot(fighter_id)
	var applied := maxf(0.0, amount) * float(passive.get("dreno_foco_arena_mult", 1.0))
	_adjust(fighter_id, "foco", -applied)
	return applied

func get_passive_snapshot(fighter_id: String) -> Dictionary:
	return passive_snapshots.get(fighter_id, PassiveSnapshotScript.empty()).duplicate(true)

func get_contextual_hand(fighter_id: String) -> Array:
	var result: Array = []
	for card_id_value in hands.get(fighter_id, []):
		var card_id := str(card_id_value)
		if not cards.has(card_id):
			continue
		var view: Dictionary = cards[card_id].duplicate(true)
		var validation := pode_jogar(fighter_id, card_id)
		view["playable"] = bool(validation.get("ok", false))
		view["blocked_reason"] = str(validation.get("reason", ""))
		view["playability"] = validation
		result.append(view)
	return result

func snapshot() -> Dictionary:
	return {
		"phase": phase,
		"position": position,
		"player_side": player_side,
		"opponent_side": _opposite_side(player_side),
		"ruleset_id": ruleset_id,
		"time_left": time_left,
		"fighters": fighters.duplicate(true),
		"scores": scores.duplicate(true),
		"hands": hands.duplicate(true),
		"pending_action": pending_action.duplicate(true),
		"passive_snapshots": passive_snapshots.duplicate(true),
	}

func _resolve_pending(defended: bool, defense_label: String) -> Dictionary:
	var action := pending_action.duplicate(true)
	pending_action.clear()
	if defended:
		phase = "decision"
		_adjust(str(action["defender_id"]), "foco", 7.0)
		_adjust(str(action["defender_id"]), "guarda", 5.0)
		_adjust(str(action["attacker_id"]), "pressao", -12.0)
		var defended_result := {"ok": true, "success": false, "defended": true, "defense": defense_label, "card_id": action["card_id"]}
		card_resolved.emit(defended_result)
		_emit_snapshot()
		return defended_result
	return _resolve_card_success(str(action["attacker_id"]), str(action["defender_id"]), cards[str(action["card_id"])])

func _resolve_card_success(attacker: String, defender: String, card: Dictionary) -> Dictionary:
	var destination := str(card.get("destino", "keep"))
	if destination != "keep":
		position = destination
	_apply_side(attacker, str(card.get("set_side", "keep")))
	_adjust(defender, "integridade", -float(card.get("dano_pos", 0.0)))
	_adjust(defender, "guarda", -maxf(3.0, float(card.get("dano_pos", 0.0)) * 1.2))
	_adjust(attacker, "pressao", 10.0)
	if str(card.get("tipo", "")) == "pegada" or str(card.get("tecnica", "")).contains("grip"):
		_adjust(attacker, "grip", float(get_passive_snapshot(attacker).get("grip_por_pegada", 0.0)))
	_apply_extra(attacker, defender, card.get("efeito_extra", {}))
	if bool(rulesets[ruleset_id].get("pontos_ativos", false)):
		scores[attacker] = int(scores.get(attacker, 0)) + int(card.get("pontos", 0))
	phase = "submission" if position == "SUBMISSION" else "decision"
	pending_action = {"attacker_id": attacker, "defender_id": defender, "card_id": str(card.get("id", ""))} if phase == "submission" else {}
	_draw_all_hands()
	var result := {"ok": true, "success": true, "card_id": card.get("id", ""), "attacker_id": attacker, "defender_id": defender, "snapshot": snapshot()}
	card_resolved.emit(result)
	if float(fighters[defender].get("integridade", 0.0)) <= 0.0:
		result["victory"] = try_resolve_victory({"method": "desistencia", "winner_id": attacker, "loser_id": defender})
	_emit_snapshot()
	return result

func _playability_result(allowed: bool, reason_code: String, reason: String, card: Dictionary = {}) -> Dictionary:
	var cost: Dictionary = card.get("custo", {}).duplicate(true)
	return {
		"ok": allowed,
		"allowed": allowed,
		"reason_code": reason_code,
		"reason": reason,
		"localized_reason_key": "combat.playability.%s" % reason_code.to_lower(),
		"specialized_slot": str(card.get("slot", card.get("tipo", ""))),
		"resource_preview": cost,
		"predicted_transition": {
			"position": str(card.get("destino", "keep")),
			"set_side": str(card.get("set_side", "keep")),
		},
	}

func _blocked(reason_code: String, reason: String, card: Dictionary = {}) -> Dictionary:
	return _playability_result(false, reason_code, reason, card)

func _matches_position(fighter_id: String, card: Dictionary) -> bool:
	if not card.get("origem", []).has(position):
		return false
	var required_side := str(card.get("lado", "any"))
	return required_side == "any" or required_side == _side_for(fighter_id)

func _profile_allows(fighter_id: String, card: Dictionary) -> bool:
	var policies: Dictionary = flags.get("owner_policies", {})
	var policy: Dictionary = policies.get(fighter_id, {})
	var forbidden: Array = policy.get("forbidden_morals", [])
	return not forbidden.has(str(card.get("moral", "limpa")))

func _has_cost(fighter_id: String, cost: Dictionary) -> bool:
	var res: Dictionary = fighters.get(fighter_id, {})
	var passive := get_passive_snapshot(fighter_id)
	var gas_cost := float(cost.get("gas", 0.0)) * float(passive.get("gas_cost_mult", 1.0))
	var focus_cost := float(cost.get("foco", 0.0)) * float(passive.get("focus_cost_mult", 1.0))
	return float(res.get("grip", 0.0)) >= float(cost.get("grip", 0.0)) and float(res.get("gas", 0.0)) >= gas_cost and float(res.get("foco", 0.0)) >= focus_cost

func _consume_cost(fighter_id: String, cost: Dictionary) -> void:
	var passive := get_passive_snapshot(fighter_id)
	_adjust(fighter_id, "grip", -float(cost.get("grip", 0.0)))
	_adjust(fighter_id, "gas", -float(cost.get("gas", 0.0)) * float(passive.get("gas_cost_mult", 1.0)))
	_adjust(fighter_id, "foco", -float(cost.get("foco", 0.0)) * float(passive.get("focus_cost_mult", 1.0)))

func _apply_side(attacker: String, set_side: String) -> void:
	match set_side:
		"top": player_side = "top" if attacker == player_id else "bottom"
		"bottom": player_side = "bottom" if attacker == player_id else "top"
		"invert":
			if player_side == "top": player_side = "bottom"
			elif player_side == "bottom": player_side = "top"
		"any": player_side = "any"
		_: pass
	if position in ["STANDING", "CLINCH"]:
		player_side = "any"

func _apply_extra(attacker: String, defender: String, extra: Dictionary) -> void:
	for key_value in extra.keys():
		var key := str(key_value)
		var value = extra[key_value]
		if key.ends_with("_self"):
			_adjust(attacker, key.trim_suffix("_self"), _parse_delta(value))
		elif key.ends_with("_oponente"):
			_adjust(defender, key.trim_suffix("_oponente"), _parse_delta(value))
		elif key == "quebra_grip_oponente":
			_adjust(defender, "grip", -float(value))

func _parse_delta(value: Variant) -> float:
	if typeof(value) in [TYPE_INT, TYPE_FLOAT]:
		return float(value)
	return float(str(value).replace("+", ""))

func _flag_requirement_met(requirement: String) -> bool:
	if requirement == "":
		return true
	if requirement.contains(">="):
		var parts := requirement.split(">=")
		return float(flags.get(parts[0], 0)) >= float(parts[1])
	return bool(flags.get(requirement, false))

func _draw_hand(fighter_id: String) -> void:
	var deck: Array = decks.get(fighter_id, [])
	var pool: Array = []
	for card_id_value in deck:
		var card_id := str(card_id_value)
		if cards.has(card_id) and _profile_allows(fighter_id, cards[card_id]) and _matches_position(fighter_id, cards[card_id]):
			pool.append(card_id)
	if pool.is_empty():
		for card_id_value in deck:
			var fallback_id := str(card_id_value)
			if cards.has(fallback_id) and _profile_allows(fighter_id, cards[fallback_id]):
				pool.append(fallback_id)
	var hand: Array = []
	if not pool.is_empty():
		var cursor := int(draw_cursor.get(fighter_id, 0))
		var attempts := 0
		while hand.size() < mini(3, pool.size()) and attempts < pool.size() * 2:
			var card_id := str(pool[cursor % pool.size()])
			cursor += 1
			attempts += 1
			if not hand.has(card_id):
				hand.append(card_id)
		draw_cursor[fighter_id] = cursor
	hands[fighter_id] = hand

func _draw_all_hands() -> void:
	_draw_hand(player_id)
	_draw_hand(opponent_id)

func _regenerate(delta: float) -> void:
	for fighter_id_value in fighters.keys():
		var fighter_id := str(fighter_id_value)
		_adjust(fighter_id, "gas", 2.0 * delta)
		_adjust(fighter_id, "foco", 1.0 * delta)
		_adjust(fighter_id, "pressao", -1.5 * delta)
		if float(fighters[fighter_id].get("gas", 0.0)) <= 0.0:
			var fatigue_mult := float(get_passive_snapshot(fighter_id).get("fadiga_dano_mult", 1.0))
			_adjust(fighter_id, "integridade", -1.0 * fatigue_mult * delta)

func _initial_resources(fighter_id: String) -> Dictionary:
	var resources := DEFAULT_RESOURCES.duplicate(true)
	var passive := get_passive_snapshot(fighter_id)
	resources["integridade"] = 100.0 + float(passive.get("vida_max_bonus", 0.0))
	resources["gas"] = 100.0 + float(passive.get("gas_max_bonus", 0.0))
	resources["foco"] = 100.0 + float(passive.get("foco_max_bonus", 0.0))
	resources["grip"] = clampf(float(passive.get("grip_inicial", 0.0)), 0.0, 3.0)
	return resources

func _adjust(fighter_id: String, key: String, delta: float) -> void:
	if not fighters.has(fighter_id):
		return
	fighters[fighter_id][key] = clampf(float(fighters[fighter_id].get(key, 0.0)) + delta, 0.0, _maximum_for(fighter_id, key))

func _maximum_for(fighter_id: String, key: String) -> float:
	var passive := get_passive_snapshot(fighter_id)
	match key:
		"grip": return 3.0
		"integridade": return 100.0 + float(passive.get("vida_max_bonus", 0.0))
		"gas": return 100.0 + float(passive.get("gas_max_bonus", 0.0))
		"foco": return 100.0 + float(passive.get("foco_max_bonus", 0.0))
		_: return 100.0

func _finish_by_points() -> void:
	if not bool(rulesets[ruleset_id].get("pontos_ativos", false)):
		return
	if int(scores[player_id]) == int(scores[opponent_id]):
		try_resolve_victory({"method": "pontos", "winner_id": "", "loser_id": ""})
	elif int(scores[player_id]) > int(scores[opponent_id]):
		try_resolve_victory({"method": "pontos", "winner_id": player_id, "loser_id": opponent_id})
	else:
		try_resolve_victory({"method": "pontos", "winner_id": opponent_id, "loser_id": player_id})

func _reset_after_blocked_submission(attacker: String, defender: String) -> void:
	position = "GUARD"
	player_side = "bottom" if attacker == player_id else "top"
	phase = "decision"
	pending_action.clear()
	_adjust(attacker, "gas", -15.0)
	_adjust(defender, "gas", -10.0)
	_draw_all_hands()

func _finish(winner: String, loser: String, method: String) -> void:
	phase = "finished"
	var result := {"winner_id": winner, "loser_id": loser, "method": method, "scores": scores.duplicate(true), "snapshot": snapshot()}
	combat_finished.emit(result)

func _side_for(fighter_id: String) -> String:
	if player_side == "any":
		return "any"
	return player_side if fighter_id == player_id else _opposite_side(player_side)

func _opposite_side(side: String) -> String:
	if side == "top":
		return "bottom"
	if side == "bottom":
		return "top"
	return "any"

func _other(fighter_id: String) -> String:
	return opponent_id if fighter_id == player_id else player_id

func _emit_snapshot() -> void:
	snapshot_changed.emit(snapshot())
