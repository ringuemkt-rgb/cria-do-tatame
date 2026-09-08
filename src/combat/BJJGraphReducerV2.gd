class_name BJJGraphReducerV2
extends RefCounted

const RulesEngineScript = preload("res://src/combat/BJJRulesEngineV1.gd")

var kg: Dictionary = {}
var techniques: Dictionary = {}
var positions: Dictionary = {}
var rules_engine: BJJRulesEngineV1
var validation_errors: Array = []

func _init(kg_data: Dictionary, rules_data: Dictionary):
	kg = kg_data.duplicate(true)
	rules_engine = RulesEngineScript.new(rules_data)
	for raw_position in kg.get("positions", kg.get("posicoes", [])):
		if typeof(raw_position) == TYPE_DICTIONARY:
			var position: Dictionary = raw_position
			positions[str(position.get("id", ""))] = position
	for raw_technique in kg.get("techniques", kg.get("tecnicas", [])):
		if typeof(raw_technique) == TYPE_DICTIONARY:
			var technique: Dictionary = raw_technique
			techniques[str(technique.get("id", ""))] = technique
	if not positions.has("standing_neutral"):
		validation_errors.append("standing_neutral_missing")
	if not positions.has("submission"):
		validation_errors.append("submission_terminal_missing")

func is_ready() -> bool:
	return validation_errors.is_empty() and not techniques.is_empty()

func new_state(ruleset: String, gi: bool, seed: int, belt_or_skill_division: String = "slice_any", age_division: String = "adult") -> Dictionary:
	return {
		"pos": "standing_neutral",
		"top": 0,
		"gi": gi,
		"ruleset": ruleset,
		"belt_or_skill_division": belt_or_skill_division,
		"age_division": age_division,
		"seed": seed,
		"tick": 0,
		"winner": 0,
		"pending_score": {},
		"p1": {"gas": 100.0, "score": 0, "grip": 50.0},
		"p2": {"gas": 100.0, "score": 0, "grip": 50.0},
		"log": []
	}

func available_actions(state: Dictionary, player: int) -> Array:
	var out: Array = []
	var ids: Array = techniques.keys()
	ids.sort()
	for tid_value in ids:
		var tid := str(tid_value)
		var technique: Dictionary = techniques[tid]
		if _technique_available_for_player(technique, state, player):
			out.append(tid)
	return out

func reduce(state: Dictionary, action: Dictionary) -> Dictionary:
	var s: Dictionary = state.duplicate(true)
	if int(s.get("winner", 0)) != 0:
		return s
	if str(action.get("kind", "technique")) == "stabilize":
		return _reduce_stabilization(s, action)

	var attack_id := str(action.get("atk", ""))
	var attack_player := int(action.get("atk_player", 0))
	if attack_player not in [1, 2] or not techniques.has(attack_id):
		return s
	var attack: Dictionary = techniques[attack_id]
	if not _technique_available_for_player(attack, s, attack_player):
		return s

	s["tick"] = int(s.get("tick", 0)) + 1
	_pay_gas(s, attack_player, float(attack.get("gas", 0.0)))
	var defense_player := 2 if attack_player == 1 else 1
	var defense_id := str(action.get("def", ""))
	if defense_id != "":
		var counter_relation := _counter_relation(attack, defense_id)
		if not counter_relation.is_empty() and techniques.has(defense_id):
			var counter: Dictionary = techniques[defense_id]
			if _technique_available_for_player(counter, s, defense_player):
				_pay_gas(s, defense_player, float(counter.get("gas", 0.0)))
				var counter_roll := _rng(s, defense_player * 31 + _string_salt(defense_id))
				var counter_chance := clampf(float(counter.get("authoring_prior", 0.0)) + _grip_modifier(s, counter, defense_player), 0.0, 1.0)
				if counter_roll < counter_chance:
					_apply_counter_success(s, counter, counter_relation, defense_player)
					_append_log(s, {"ev":"counter","t":defense_id,"against":attack_id,"by":defense_player,"outcome":str(counter_relation.get("outcome", "")),"roll":counter_roll,"chance":counter_chance})
					return s

	var attack_roll := _rng(s, attack_player * 17 + _string_salt(attack_id))
	var attack_chance := clampf(float(attack.get("authoring_prior", 0.0)) + _grip_modifier(s, attack, attack_player), 0.0, 1.0)
	if attack_roll < attack_chance:
		_apply_technique_success(s, attack, attack_player)
		_append_log(s, {"ev":"hit","t":attack_id,"by":attack_player,"roll":attack_roll,"chance":attack_chance})
	else:
		_append_log(s, {"ev":"miss","t":attack_id,"by":attack_player,"roll":attack_roll,"chance":attack_chance})
	return s

func query(state: Dictionary, player: int) -> Array:
	var out: Array = []
	for tid_value in available_actions(state, player):
		var tid := str(tid_value)
		var technique: Dictionary = techniques[tid]
		var event_id := str(technique.get("scoring_event", ""))
		out.append({
			"id": tid,
			"type": str(technique.get("type", technique.get("tipo", ""))),
			"authoring_prior": float(technique.get("authoring_prior", 0.0)),
			"empirical_success": technique.get("empirical_success", null),
			"gas": float(technique.get("gas", 0.0)),
			"to": str(technique.get("to", technique.get("para", ""))),
			"scoring_event": event_id,
			"potential_points": rules_engine.points_for_event(str(state.get("ruleset", "")), event_id),
			"counter_count": int(technique.get("counters", []).size())
		})
	return out

func _reduce_stabilization(s: Dictionary, action: Dictionary) -> Dictionary:
	var pending: Dictionary = s.get("pending_score", {})
	if pending.is_empty():
		return s
	var player := int(action.get("player", 0))
	if player != int(pending.get("player", 0)):
		return s
	var seconds := maxf(0.0, float(action.get("seconds", 0.0)))
	if seconds <= 0.0:
		return s
	s["tick"] = int(s.get("tick", 0)) + 1
	pending["stabilized_seconds"] = float(pending.get("stabilized_seconds", 0.0)) + seconds
	if float(pending.get("stabilized_seconds", 0.0)) >= float(pending.get("required_seconds", 3.0)):
		var points := rules_engine.points_for_event(str(s.get("ruleset", "")), str(pending.get("event", "")))
		if points > 0:
			var fighter_key := _fighter_key(player)
			var fighter: Dictionary = s.get(fighter_key, {}).duplicate(true)
			fighter["score"] = int(fighter.get("score", 0)) + points
			s[fighter_key] = fighter
			_append_log(s, {"ev":"score","event":str(pending.get("event", "")),"by":player,"points":points})
		s["pending_score"] = {}
	else:
		s["pending_score"] = pending
	return s

func _technique_available_for_player(technique: Dictionary, state: Dictionary, player: int) -> bool:
	var current_pos := str(state.get("pos", ""))
	var from_id := str(technique.get("from", technique.get("de", "")))
	if from_id != current_pos:
		return false
	var expected_player := _player_for_role(state, str(technique.get("actor_role_from", "neutral")))
	if expected_player != 0 and expected_player != player:
		return false
	if not rules_engine.technique_allowed(technique, state, positions):
		return false
	var fighter: Dictionary = state.get(_fighter_key(player), {})
	if float(fighter.get("gas", 0.0)) < float(technique.get("gas", 0.0)):
		return false
	return true

func _player_for_role(state: Dictionary, role: String) -> int:
	var top := int(state.get("top", 0))
	match role:
		"top": return top
		"bottom":
			if top == 1: return 2
			if top == 2: return 1
			return 0
		_: return 0

func _apply_counter_success(s: Dictionary, counter: Dictionary, relation: Dictionary, player: int) -> void:
	var outcome := str(relation.get("outcome", ""))
	if outcome != "deny_to_same_state":
		_apply_position(s, str(counter.get("to", counter.get("para", s.get("pos", "")))), str(counter.get("actor_role_to", "neutral")), player)
	_apply_grip_effect(s, counter, player)
	s["pending_score"] = {}
	if str(counter.get("to", counter.get("para", ""))) == "submission":
		s["winner"] = player

func _apply_technique_success(s: Dictionary, technique: Dictionary, player: int) -> void:
	var to_id := str(technique.get("to", technique.get("para", s.get("pos", ""))))
	_apply_position(s, to_id, str(technique.get("actor_role_to", "neutral")), player)
	_apply_grip_effect(s, technique, player)
	var event_id := str(technique.get("scoring_event", ""))
	if event_id != "" and rules_engine.points_for_event(str(s.get("ruleset", "")), event_id) > 0:
		s["pending_score"] = {
			"event": event_id,
			"player": player,
			"required_seconds": maxf(0.0, float(technique.get("stabilization_seconds", 3.0))),
			"stabilized_seconds": 0.0,
			"position": to_id
		}
	else:
		s["pending_score"] = {}
	if to_id == "submission":
		s["winner"] = player

func _apply_position(s: Dictionary, to_id: String, actor_role_to: String, player: int) -> void:
	s["pos"] = to_id
	match actor_role_to:
		"top": s["top"] = player
		"bottom": s["top"] = 2 if player == 1 else 1
		"neutral": s["top"] = 0

func _apply_grip_effect(s: Dictionary, technique: Dictionary, player: int) -> void:
	var ttype := str(technique.get("type", technique.get("tipo", "")))
	if ttype == "grip":
		_adjust_grip(s, player, 8.0)
	elif ttype == "grip_break":
		_adjust_grip(s, 2 if player == 1 else 1, -6.0)

func _grip_modifier(s: Dictionary, technique: Dictionary, player: int) -> float:
	var ttype := str(technique.get("type", technique.get("tipo", "")))
	if ttype not in ["takedown", "pass", "grip"]:
		return 0.0
	var mine: Dictionary = s.get(_fighter_key(player), {})
	var opponent := 2 if player == 1 else 1
	var theirs: Dictionary = s.get(_fighter_key(opponent), {})
	return clampf((float(mine.get("grip", 50.0)) - float(theirs.get("grip", 50.0))) / 200.0, -0.15, 0.15)

func _counter_relation(attack: Dictionary, defense_id: String) -> Dictionary:
	for raw_relation in attack.get("counters", []):
		if typeof(raw_relation) != TYPE_DICTIONARY:
			continue
		var relation: Dictionary = raw_relation
		if str(relation.get("technique_id", "")) == defense_id:
			return relation
	return {}

func _pay_gas(s: Dictionary, player: int, amount: float) -> void:
	var key := _fighter_key(player)
	var fighter: Dictionary = s.get(key, {}).duplicate(true)
	fighter["gas"] = maxf(0.0, float(fighter.get("gas", 0.0)) - maxf(0.0, amount))
	s[key] = fighter

func _adjust_grip(s: Dictionary, player: int, delta: float) -> void:
	var key := _fighter_key(player)
	var fighter: Dictionary = s.get(key, {}).duplicate(true)
	fighter["grip"] = clampf(float(fighter.get("grip", 50.0)) + delta, 0.0, 100.0)
	s[key] = fighter

func _fighter_key(player: int) -> String:
	return "p1" if player == 1 else "p2"

func _rng(state: Dictionary, salt: int) -> float:
	var h: int = int(state.get("seed", 0)) * 1000003 + int(state.get("tick", 0)) * 9176 + salt * 7919
	h = int((h * 1103515245 + 12345) % 2147483647)
	if h < 0:
		h = -h
	return float(h % 1000000) / 1000000.0

func _string_salt(value: String) -> int:
	var out := 17
	for index in range(value.length()):
		out = int((out * 31 + value.unicode_at(index)) % 1000003)
	return out

func _append_log(s: Dictionary, event: Dictionary) -> void:
	var log: Array = s.get("log", []).duplicate(true)
	var item := event.duplicate(true)
	item["tick"] = int(s.get("tick", 0))
	log.append(item)
	s["log"] = log
