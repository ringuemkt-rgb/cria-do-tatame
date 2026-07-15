extends Node
class_name DaviAIController

var rival_id: String = "davi_relampago"
var difficulty: String = "normal"
var seen_player_actions: Dictionary = {}
var seen_player_families: Dictionary = {}
var last_action: String = ""
var last_chosen_technique: String = ""
var profile: Dictionary = {}
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	setup(rival_id, difficulty)

func setup(p_rival_id: String = "davi_relampago", p_difficulty: String = "normal") -> void:
	rival_id = p_rival_id
	difficulty = p_difficulty
	profile = DataRegistry.rival_ai_profiles.get("profiles", {}).get(rival_id, {})
	rng.seed = hash("%s|%s" % [rival_id, difficulty])
	reset()

func reset() -> void:
	seen_player_actions.clear()
	seen_player_families.clear()
	last_action = ""
	last_chosen_technique = ""

func record_player_action(action_id: String) -> void:
	seen_player_actions[action_id] = int(seen_player_actions.get(action_id, 0)) + 1
	last_action = action_id
	var technique: Dictionary = DataRegistry.get_technique(action_id)
	var family := str(technique.get("family", technique.get("familia", "geral")))
	seen_player_families[family] = int(seen_player_families.get(family, 0)) + 1

func choose_technique(combat_manager: Node) -> Dictionary:
	if combat_manager == null or not bool(combat_manager.get("is_running")):
		return {}
	var available: Array = combat_manager.call("get_available_techniques", rival_id)
	var affordable: Array[Dictionary] = []
	for value in available:
		if typeof(value) == TYPE_DICTIONARY and bool(value.get("affordable", false)):
			affordable.append(value)
	if affordable.is_empty():
		return {}

	var actor_state := str(combat_manager.call("get_actor_state_name", rival_id))
	var player_id := str(combat_manager.get("player_id"))
	var fighters: Dictionary = combat_manager.get("fighters")
	var player_resources: Dictionary = fighters.get(player_id, {})
	var rival_resources: Dictionary = fighters.get(rival_id, {})
	var best: Dictionary = affordable[0]
	var best_score := -INF
	for technique in affordable:
		var score := _score_technique(technique, actor_state, player_resources, rival_resources)
		if score > best_score:
			best_score = score
			best = technique
	last_chosen_technique = str(best.get("id", ""))
	return best

func _score_technique(
	technique: Dictionary,
	actor_state: String,
	player_resources: Dictionary,
	rival_resources: Dictionary
) -> float:
	var technique_id := str(technique.get("id", ""))
	var base_chance := float(technique.get("base_chance", technique.get("chance_sucesso", 0.5)))
	var score := base_chance * 100.0
	var cost: Dictionary = technique.get("cost", technique.get("custo", {}))
	var gas_cost := float(cost.get("gas", technique.get("gas_cost", 0)))
	var focus_cost := float(cost.get("focus", cost.get("foco", technique.get("focus_cost", 0))))
	var gas_ratio := float(rival_resources.get("gas", 0)) / 100.0
	var focus_ratio := float(rival_resources.get("focus", 0)) / 100.0
	score -= gas_cost * (1.4 if gas_ratio < 0.35 else 0.55)
	score -= focus_cost * (1.2 if focus_ratio < 0.35 else 0.45)

	var preferred_actions: Array = profile.get("preferred_actions", [])
	if preferred_actions.has(technique_id):
		score += 18.0
	var preferred_states: Array = profile.get("preferred_states", [])
	if preferred_states.has(actor_state):
		score += 8.0

	score += _anti_pattern_bonus(technique_id, player_resources)
	score += _difficulty_bonus(technique)
	score -= _risk_penalty(technique)
	if float(player_resources.get("gas", 100)) < 30.0:
		score += float(technique.get("control_gain", 0)) * 0.6
	if int(seen_player_actions.get(technique_id, 0)) > 0:
		score += 2.0
	# Pequena variacao deterministica evita que a IA repita sempre a mesma tecnica
	# quando duas opcoes possuem valor praticamente igual.
	score += rng.randf_range(-1.5, 1.5)
	return score

func _anti_pattern_bonus(technique_id: String, player_resources: Dictionary) -> float:
	var bonus := 0.0
	for rule_value in profile.get("anti_patterns", []):
		if typeof(rule_value) != TYPE_DICTIONARY:
			continue
		var rule: Dictionary = rule_value
		if str(rule.get("response", "")) != technique_id:
			continue
		var weight := float(rule.get("weight", 1.0))
		if rule.has("if_player_repeats_family"):
			var family := str(rule.get("if_player_repeats_family", ""))
			if int(seen_player_families.get(family, 0)) >= 2:
				bonus += 32.0 * weight
		if bool(rule.get("if_player_low_gas", false)) and float(player_resources.get("gas", 100)) < 30.0:
			bonus += 28.0 * weight
		if bool(rule.get("if_player_low_focus", false)) and float(player_resources.get("focus", 100)) < 30.0:
			bonus += 24.0 * weight
	return bonus

func _difficulty_bonus(technique: Dictionary) -> float:
	match difficulty:
		"facil":
			return -float(technique.get("control_gain", 0)) * 0.25
		"dificil":
			return float(technique.get("control_gain", 0)) * 0.45
		"pesadelo":
			return float(technique.get("control_gain", 0)) * 0.75
		_:
			return float(technique.get("control_gain", 0)) * 0.20

func _risk_penalty(technique: Dictionary) -> float:
	var risk_value = technique.get("risk", technique.get("risco", "medio"))
	var risk_level := 2.0
	if typeof(risk_value) == TYPE_STRING:
		match str(risk_value):
			"baixo": risk_level = 1.0
			"medio": risk_level = 2.0
			"alto": risk_level = 3.0
			"extremo": risk_level = 4.0
	else:
		risk_level = float(risk_value)
	var configured_risk := float(profile.get("tuning", {}).get("risk", 0.35))
	return risk_level * (1.0 - configured_risk) * 4.0

func pressure_message() -> String:
	if last_action != "" and int(seen_player_actions.get(last_action, 0)) >= 3:
		return "Davi leu a repeticao. Muda o ritmo."
	for family_value in seen_player_families.keys():
		var family: String = str(family_value)
		if int(seen_player_families.get(family, 0)) >= 3:
			return "Davi percebeu seu padrao de %s." % family.replace("_", " ")
	return "Davi Relampago esta estudando seu jogo."

func chosen_action_label() -> String:
	if last_chosen_technique == "":
		return "esperando"
	var technique: Dictionary = DataRegistry.get_technique(last_chosen_technique)
	return str(technique.get("nome", technique.get("name", last_chosen_technique)))

# Compatibilidade com a interface antiga de dica. A decisao real usa choose_technique().
func choose_response(combat_phase: String, player_resources: Dictionary) -> String:
	var gas: float = float(player_resources.get("gas", 100))
	if _player_is_repeating("baiana"):
		return "sprawl"
	if _player_is_repeating("grip_de_ferro"):
		return "quebra_base"
	if combat_phase == "GROUND" or combat_phase == "TRANSITION":
		return "saida_cem_quilos"
	if gas < 30.0:
		return "pressao_cabeca"
	return "grip_de_ferro"

func _player_is_repeating(action_id: String) -> bool:
	return int(seen_player_actions.get(action_id, 0)) >= 2
