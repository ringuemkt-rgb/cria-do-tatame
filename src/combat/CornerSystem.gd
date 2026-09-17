class_name CornerSystem
extends RefCounted

var position_values: Dictionary = {}
var technique_catalog: Dictionary = {}

func configure(position_value_data: Dictionary, techniques: Dictionary) -> void:
	position_values = position_value_data.duplicate(true)
	technique_catalog = techniques.duplicate(true)

func suggest_action(state: Dictionary, hand: Array, scouting: Dictionary) -> Dictionary:
	var ranked: Array = []
	var counters: Array = scouting.get("counters_known", [])
	var weaknesses: Array = scouting.get("weaknesses", [])
	var fighter: Dictionary = state.get("p1", {})
	for raw_id in hand:
		var technique_id := str(raw_id)
		var info: Dictionary = technique_catalog.get(technique_id, {})
		if info.is_empty():
			continue
		var score := 0.0
		var from_pos := str(info.get("from", info.get("entry_state", "")))
		var to_pos := str(info.get("to", info.get("state_to", "")))
		if weaknesses.has(from_pos) or weaknesses.has(to_pos):
			score += 30.0
		if counters.has(technique_id):
			score -= 40.0
		score += _position_value(to_pos) * 20.0
		var gas_cost := float(info.get("gas", info.get("gas_cost", 0.0)))
		if float(fighter.get("gas", 100.0)) < 30.0:
			score -= gas_cost * 2.0
		ranked.append({
			"kg_id": technique_id,
			"score": score,
			"reason": _reason(technique_id, score, counters, weaknesses, from_pos, to_pos)
		})
	ranked.sort_custom(_sort_score)
	return ranked[0] if not ranked.is_empty() else {}

func suggest_deck(scouting: Dictionary, available: Array, limit: int = 8) -> Array:
	var ranked: Array = []
	var counters: Array = scouting.get("counters_known", [])
	var weaknesses: Array = scouting.get("weaknesses", [])
	for raw_id in available:
		var technique_id := str(raw_id)
		var info: Dictionary = technique_catalog.get(technique_id, {})
		if info.is_empty():
			continue
		var from_pos := str(info.get("from", info.get("entry_state", "")))
		var to_pos := str(info.get("to", info.get("state_to", "")))
		var score := _position_value(to_pos) * 20.0
		if weaknesses.has(from_pos) or weaknesses.has(to_pos):
			score += 30.0
		if counters.has(technique_id):
			score -= 40.0
		ranked.append({"id": technique_id, "score": score})
	ranked.sort_custom(_sort_score)
	var output: Array[String] = []
	for row in ranked:
		if output.size() >= clampi(limit, 6, 8):
			break
		output.append(str(row.get("id", "")))
	return output

func _position_value(position_id: String) -> float:
	var groups: Dictionary = position_values.get("position_groups", {})
	var bands: Dictionary = position_values.get("bands", {})
	var group := str(groups.get(position_id, ""))
	if group != "" and bands.has(group):
		return float(bands[group])
	return float(position_values.get("unmapped_fallback", 0.45))

func _reason(
	technique_id: String,
	score: float,
	counters: Array,
	weaknesses: Array,
	from_pos: String,
	to_pos: String
) -> String:
	if counters.has(technique_id):
		return "Ele ja viu essa tecnica no CriaLive; evita repetir."
	if weaknesses.has(from_pos) or weaknesses.has(to_pos):
		return "Esse caminho ataca uma fraqueza detectada no scouting."
	if score > 15.0:
		return "Boa relacao entre valor posicional e risco."
	return "Opcao segura para manter o plano."

func _sort_score(a: Dictionary, b: Dictionary) -> bool:
	var sa := float(a.get("score", -INF))
	var sb := float(b.get("score", -INF))
	if not is_equal_approx(sa, sb):
		return sa > sb
	return str(a.get("id", a.get("kg_id", ""))) < str(b.get("id", b.get("kg_id", "")))
