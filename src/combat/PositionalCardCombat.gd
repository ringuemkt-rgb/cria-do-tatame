class_name PositionalCardCombat
extends Node

## Runtime de combate de jiu-jitsu orientado por cartas.
## Nao substitui CombatManager/DeckManager: coordena posicao, recursos,
## janela defensiva, pontuacao e condicoes de vitoria.

signal snapshot_changed(snapshot: Dictionary)
signal action_window_opened(window: Dictionary)
signal card_resolved(result: Dictionary)
signal combat_finished(result: Dictionary)

enum Position {
	STANDING,
	CLINCH_NEUTRAL,
	CLINCH_DOMINANT,
	GUARD_TOP,
	GUARD_BOTTOM,
	HALF_TOP,
	HALF_BOTTOM,
	SIDE_CONTROL,
	MOUNT,
	BACK_CONTROL,
	SUBMISSION
}

enum Side { ANY, TOP, BOTTOM, ATTACKER, DEFENDER }

enum Phase { READY, DECISION, DEFENSE_WINDOW, SUBMISSION, FINISHED }

const POSITION_NAMES := {
	Position.STANDING: "standing",
	Position.CLINCH_NEUTRAL: "clinch_neutral",
	Position.CLINCH_DOMINANT: "clinch_dominant",
	Position.GUARD_TOP: "guard_top",
	Position.GUARD_BOTTOM: "guard_bottom",
	Position.HALF_TOP: "half_top",
	Position.HALF_BOTTOM: "half_bottom",
	Position.SIDE_CONTROL: "side_control",
	Position.MOUNT: "mount",
	Position.BACK_CONTROL: "back_control",
	Position.SUBMISSION: "submission"
}

const POSITION_SCORE := {
	"takedown": 2,
	"sweep": 2,
	"guard_pass": 3,
	"mount": 4,
	"back_control": 4
}

const DEFAULT_RESOURCES := {
	"integrity": 100.0,
	"gas": 100.0,
	"focus": 100.0,
	"grip": 0.0,
	"pressure": 0.0,
	"guard": 100.0,
	"moral_tension": 0.0
}

var phase: int = Phase.READY
var position: int = Position.STANDING
var top_id: String = ""
var bottom_id: String = ""
var attacker_id: String = ""
var defender_id: String = ""
var fighters: Dictionary = {}
var scores: Dictionary = {}
var cards: Dictionary = {}
var deck_by_fighter: Dictionary = {}
var hand_by_fighter: Dictionary = {}
var discard_by_fighter: Dictionary = {}
var draw_cursor: Dictionary = {}
var pending_action: Dictionary = {}
var round_time_left: float = 300.0
var ruleset: Dictionary = {
	"allow_points": true,
	"allow_submission": true,
	"allow_desistance": true,
	"clean_only": false
}

func configure(card_catalog: Array, fighter_decks: Dictionary, combat_ruleset: Dictionary = {}) -> Dictionary:
	cards.clear()
	for raw_card in card_catalog:
		if typeof(raw_card) != TYPE_DICTIONARY:
			continue
		var card: Dictionary = raw_card.duplicate(true)
		var card_id := str(card.get("id", ""))
		if card_id == "":
			continue
		cards[card_id] = card
	deck_by_fighter = fighter_decks.duplicate(true)
	if not combat_ruleset.is_empty():
		ruleset.merge(combat_ruleset, true)
	return {"ok": not cards.is_empty(), "cards": cards.size(), "fighters": deck_by_fighter.size()}

func start(player_id: String, opponent_id: String, duration_seconds: float = 300.0) -> Dictionary:
	if player_id == "" or opponent_id == "" or player_id == opponent_id:
		return {"ok": false, "error": "invalid_fighters"}
	fighters = {
		player_id: DEFAULT_RESOURCES.duplicate(true),
		opponent_id: DEFAULT_RESOURCES.duplicate(true)
	}
	scores = {player_id: 0, opponent_id: 0}
	hand_by_fighter.clear()
	discard_by_fighter.clear()
	draw_cursor.clear()
	for fighter_id in fighters.keys():
		hand_by_fighter[fighter_id] = []
		discard_by_fighter[fighter_id] = []
		draw_cursor[fighter_id] = 0
		_draw_contextual_hand(str(fighter_id))
	position = Position.STANDING
	top_id = ""
	bottom_id = ""
	attacker_id = ""
	defender_id = ""
	pending_action.clear()
	round_time_left = maxf(duration_seconds, 30.0)
	phase = Phase.DECISION
	_emit_snapshot()
	return {"ok": true, "snapshot": snapshot()}

func tick(delta: float) -> void:
	if phase == Phase.FINISHED:
		return
	round_time_left = maxf(0.0, round_time_left - delta)
	_regenerate_and_decay(delta)
	if not pending_action.is_empty():
		pending_action["time_left"] = maxf(0.0, float(pending_action.get("time_left", 0.0)) - delta)
		if float(pending_action["time_left"]) <= 0.0:
			_resolve_pending_defense(false, "window_expired")
	if round_time_left <= 0.0:
		_finish_by_points()
	else:
		_emit_snapshot()

func get_contextual_hand(fighter_id: String) -> Array:
	var output: Array = []
	for card_id_value in hand_by_fighter.get(fighter_id, []):
		var card_id := str(card_id_value)
		var card: Dictionary = cards.get(card_id, {})
		if not card.is_empty():
			var view := card.duplicate(true)
			view["playable"] = can_play_card(fighter_id, card_id)
			view["blocked_reason"] = "" if bool(view["playable"]) else _blocked_reason(fighter_id, card)
			output.append(view)
	return output

func can_play_card(fighter_id: String, card_id: String) -> bool:
	if phase != Phase.DECISION or not fighters.has(fighter_id):
		return false
	var card: Dictionary = cards.get(card_id, {})
	if card.is_empty() or not hand_by_fighter.get(fighter_id, []).has(card_id):
		return false
	if not _card_matches_position(fighter_id, card):
		return false
	if not _has_cost(fighter_id, card.get("cost", {})):
		return false
	if bool(ruleset.get("clean_only", false)) and str(card.get("moral", "clean")) != "clean":
		return false
	return true

func play_card(fighter_id: String, card_id: String, input_quality: float = 0.5) -> Dictionary:
	if not can_play_card(fighter_id, card_id):
		return {"ok": false, "error": _blocked_reason(fighter_id, cards.get(card_id, {})), "card_id": card_id}
	var card: Dictionary = cards[card_id]
	_consume_cost(fighter_id, card.get("cost", {}))
	attacker_id = fighter_id
	defender_id = _other_fighter(fighter_id)
	var quality := clampf(input_quality, 0.0, 1.0)
	var defense_window := maxf(0.15, float(card.get("window", 0.6)) * lerpf(1.2, 0.75, quality))
	pending_action = {
		"card_id": card_id,
		"attacker_id": attacker_id,
		"defender_id": defender_id,
		"input_quality": quality,
		"time_left": defense_window,
		"defense_type": str(card.get("vs_defense", "frame"))
	}
	phase = Phase.DEFENSE_WINDOW
	action_window_opened.emit(pending_action.duplicate(true))
	_emit_snapshot()
	return {"ok": true, "window": pending_action.duplicate(true)}

func defend(fighter_id: String, defense_type: String, timing_quality: float = 0.5) -> Dictionary:
	if phase != Phase.DEFENSE_WINDOW or pending_action.is_empty():
		return {"ok": false, "error": "no_defense_window"}
	if fighter_id != str(pending_action.get("defender_id", "")):
		return {"ok": false, "error": "not_defender"}
	var expected := str(pending_action.get("defense_type", "frame"))
	var correct := defense_type == expected or defense_type == "generic"
	var success := correct and clampf(timing_quality, 0.0, 1.0) >= _defense_threshold()
	return _resolve_pending_defense(success, defense_type)

func generic_action(fighter_id: String, action: String) -> Dictionary:
	if phase != Phase.DECISION or not fighters.has(fighter_id):
		return {"ok": false, "error": "action_unavailable"}
	match action:
		"grip":
			_adjust(fighter_id, "gas", -6.0)
			_adjust(fighter_id, "grip", 1.0)
			_adjust(fighter_id, "focus", 3.0)
		"pressure":
			_adjust(fighter_id, "gas", -10.0)
			_adjust(fighter_id, "pressure", 14.0)
			_adjust(_other_fighter(fighter_id), "guard", -8.0)
		"defense":
			_adjust(fighter_id, "gas", -5.0)
			_adjust(fighter_id, "guard", 10.0)
			_adjust(fighter_id, "focus", 5.0)
		"encerrar":
			_adjust(fighter_id, "gas", 12.0)
			_adjust(fighter_id, "pressure", -10.0)
			if position != Position.STANDING:
				position = Position.STANDING
				top_id = ""
				bottom_id = ""
		_:
			return {"ok": false, "error": "unknown_generic_action"}
	_draw_contextual_hand(fighter_id)
	_emit_snapshot()
	return {"ok": true, "action": action, "snapshot": snapshot()}

func snapshot() -> Dictionary:
	return {
		"phase": Phase.keys()[phase],
		"position": POSITION_NAMES.get(position, "standing"),
		"top_id": top_id,
		"bottom_id": bottom_id,
		"fighters": fighters.duplicate(true),
		"scores": scores.duplicate(true),
		"hands": hand_by_fighter.duplicate(true),
		"pending_action": pending_action.duplicate(true),
		"round_time_left": round_time_left,
		"ruleset": ruleset.duplicate(true)
	}

func _resolve_pending_defense(defended: bool, defense_label: String) -> Dictionary:
	var card_id := str(pending_action.get("card_id", ""))
	var card: Dictionary = cards.get(card_id, {})
	var attack_id := str(pending_action.get("attacker_id", ""))
	var defend_id := str(pending_action.get("defender_id", ""))
	var result := {
		"ok": true,
		"card_id": card_id,
		"attacker_id": attack_id,
		"defender_id": defend_id,
		"defended": defended,
		"defense": defense_label
	}
	if defended:
		_adjust(defend_id, "focus", 7.0)
		_adjust(defend_id, "guard", 5.0)
		_adjust(attack_id, "pressure", -12.0)
		result["success"] = false
	else:
		_apply_card_success(attack_id, defend_id, card)
		result["success"] = true
	_discard_and_redraw(attack_id, card_id)
	pending_action.clear()
	phase = Phase.SUBMISSION if position == Position.SUBMISSION else Phase.DECISION
	result["snapshot"] = snapshot()
	card_resolved.emit(result.duplicate(true))
	_check_victory(attack_id, defend_id, card)
	_emit_snapshot()
	return result

func resolve_submission(attacker_progress: float, defender_progress: float, attacker_releases: bool = false) -> Dictionary:
	if phase != Phase.SUBMISSION:
		return {"ok": false, "error": "submission_not_active"}
	if attacker_releases:
		position = Position.STANDING
		phase = Phase.DECISION
		_adjust(attacker_id, "moral_tension", -10.0)
		return {"ok": true, "released": true}
	var attack_power := clampf(attacker_progress, 0.0, 1.0) + float(fighters[attacker_id].get("grip", 0.0)) * 0.05
	var defense_power := clampf(defender_progress, 0.0, 1.0) + float(fighters[defender_id].get("focus", 0.0)) / 200.0
	if attack_power >= defense_power + 0.15:
		_adjust(defender_id, "integrity", -100.0)
		_finish(attacker_id, defender_id, "submission")
		return {"ok": true, "winner": attacker_id, "method": "submission"}
	position = Position.STANDING
	phase = Phase.DECISION
	_adjust(defender_id, "gas", -12.0)
	_adjust(attacker_id, "gas", -15.0)
	return {"ok": true, "escaped": true}

func _apply_card_success(attack_id: String, defend_id: String, card: Dictionary) -> void:
	var destination := _position_from_name(str(card.get("to", "standing")))
	position = destination
	_assign_sides(attack_id, defend_id, card)
	_adjust(defend_id, "integrity", -float(card.get("positional_damage", 0.0)))
	_adjust(defend_id, "guard", -float(card.get("guard_damage", 8.0)))
	_adjust(attack_id, "pressure", float(card.get("pressure_gain", 10.0)))
	var score_event := str(card.get("score_event", ""))
	if bool(ruleset.get("allow_points", true)) and POSITION_SCORE.has(score_event):
		scores[attack_id] = int(scores.get(attack_id, 0)) + int(POSITION_SCORE[score_event])
	var moral := str(card.get("moral", "clean"))
	if moral == "dirty":
		_adjust(attack_id, "moral_tension", 20.0)
	elif moral == "gray":
		_adjust(attack_id, "moral_tension", 8.0)
	_draw_all_contextual_hands()

func _assign_sides(attack_id: String, defend_id: String, card: Dictionary) -> void:
	var destination := str(card.get("to", "standing"))
	if destination.ends_with("_bottom"):
		top_id = defend_id
		bottom_id = attack_id
	elif destination in ["guard_top", "half_top", "side_control", "mount", "back_control"]:
		top_id = attack_id
		bottom_id = defend_id
	elif destination == "submission":
		top_id = attack_id
		bottom_id = defend_id
	else:
		top_id = ""
		bottom_id = ""

func _card_matches_position(fighter_id: String, card: Dictionary) -> bool:
	var origins: Array = card.get("from", [])
	var current_name := str(POSITION_NAMES.get(position, "standing"))
	if not origins.is_empty() and not origins.has(current_name) and not origins.has("any"):
		return false
	var side := str(card.get("side", "any"))
	if side == "top" and fighter_id != top_id and position != Position.STANDING:
		return false
	if side == "bottom" and fighter_id != bottom_id:
		return false
	return true

func _blocked_reason(fighter_id: String, card: Dictionary) -> String:
	if card.is_empty(): return "card_missing"
	if phase != Phase.DECISION: return "decision_locked"
	if not _card_matches_position(fighter_id, card): return "wrong_position"
	if not _has_cost(fighter_id, card.get("cost", {})): return "insufficient_resources"
	if bool(ruleset.get("clean_only", false)) and str(card.get("moral", "clean")) != "clean": return "ruleset_blocks_card"
	return "card_not_in_hand"

func _has_cost(fighter_id: String, cost: Dictionary) -> bool:
	var res: Dictionary = fighters.get(fighter_id, {})
	return float(res.get("gas", 0.0)) >= float(cost.get("gas", 0.0)) \
		and float(res.get("focus", 0.0)) >= float(cost.get("focus", 0.0)) \
		and float(res.get("grip", 0.0)) >= float(cost.get("grip", 0.0)) \
		and float(res.get("pressure", 0.0)) >= float(cost.get("pressure", 0.0))

func _consume_cost(fighter_id: String, cost: Dictionary) -> void:
	for key in ["gas", "focus", "grip", "pressure"]:
		_adjust(fighter_id, key, -float(cost.get(key, 0.0)))

func _adjust(fighter_id: String, key: String, delta: float) -> void:
	if not fighters.has(fighter_id): return
	var limits := {"integrity": 100.0, "gas": 100.0, "focus": 100.0, "grip": 3.0, "pressure": 100.0, "guard": 100.0, "moral_tension": 100.0}
	fighters[fighter_id][key] = clampf(float(fighters[fighter_id].get(key, 0.0)) + delta, 0.0, float(limits.get(key, 100.0)))

func _regenerate_and_decay(delta: float) -> void:
	for fighter_id_value in fighters.keys():
		var fighter_id := str(fighter_id_value)
		_adjust(fighter_id, "gas", 2.5 * delta)
		_adjust(fighter_id, "focus", 1.2 * delta)
		_adjust(fighter_id, "pressure", -2.0 * delta)
		if float(fighters[fighter_id].get("gas", 0.0)) < 10.0:
			_adjust(fighter_id, "integrity", -1.5 * delta)

func _draw_contextual_hand(fighter_id: String) -> void:
	var deck: Array = deck_by_fighter.get(fighter_id, [])
	if deck.is_empty(): return
	var playable_pool: Array = []
	for card_id_value in deck:
		var card_id := str(card_id_value)
		var card: Dictionary = cards.get(card_id, {})
		if not card.is_empty() and _card_matches_position(fighter_id, card):
			playable_pool.append(card_id)
	if playable_pool.is_empty():
		playable_pool = deck.duplicate()
	var hand: Array = []
	var cursor := int(draw_cursor.get(fighter_id, 0))
	var attempts := 0
	while hand.size() < mini(3, playable_pool.size()) and attempts < playable_pool.size() * 2:
		var card_id := str(playable_pool[cursor % playable_pool.size()])
		cursor += 1
		attempts += 1
		if not hand.has(card_id): hand.append(card_id)
	draw_cursor[fighter_id] = cursor
	hand_by_fighter[fighter_id] = hand

func _draw_all_contextual_hands() -> void:
	for fighter_id in fighters.keys(): _draw_contextual_hand(str(fighter_id))

func _discard_and_redraw(fighter_id: String, card_id: String) -> void:
	var discard: Array = discard_by_fighter.get(fighter_id, [])
	discard.append(card_id)
	discard_by_fighter[fighter_id] = discard
	_draw_contextual_hand(fighter_id)

func _defense_threshold() -> float:
	var defend_focus := float(fighters.get(defender_id, {}).get("focus", 0.0))
	var attack_pressure := float(fighters.get(attacker_id, {}).get("pressure", 0.0))
	return clampf(0.55 + attack_pressure / 250.0 - defend_focus / 300.0, 0.25, 0.85)

func _check_victory(attack_id: String, defend_id: String, card: Dictionary) -> void:
	if phase == Phase.FINISHED: return
	if bool(ruleset.get("allow_desistance", true)) and float(fighters[defend_id].get("integrity", 0.0)) <= 0.0:
		_finish(attack_id, defend_id, "desistance")
	elif position == Position.SUBMISSION and bool(ruleset.get("allow_submission", true)):
		attacker_id = attack_id
		defender_id = defend_id
		phase = Phase.SUBMISSION

func _finish_by_points() -> void:
	if not bool(ruleset.get("allow_points", true)):
		return
	var ids: Array = scores.keys()
	if ids.size() != 2: return
	var a := str(ids[0]); var b := str(ids[1])
	if int(scores[a]) == int(scores[b]):
		_finish("", "", "draw")
	elif int(scores[a]) > int(scores[b]):
		_finish(a, b, "points")
	else:
		_finish(b, a, "points")

func _finish(winner_id: String, loser_id: String, method: String) -> void:
	phase = Phase.FINISHED
	var result := {"winner_id": winner_id, "loser_id": loser_id, "method": method, "scores": scores.duplicate(true), "snapshot": snapshot()}
	combat_finished.emit(result)

func _other_fighter(fighter_id: String) -> String:
	for candidate in fighters.keys():
		if str(candidate) != fighter_id: return str(candidate)
	return ""

func _position_from_name(value: String) -> int:
	for key in POSITION_NAMES.keys():
		if str(POSITION_NAMES[key]) == value: return int(key)
	return Position.STANDING

func _emit_snapshot() -> void:
	snapshot_changed.emit(snapshot())
