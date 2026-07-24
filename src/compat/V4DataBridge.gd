class_name V4DataBridge
extends RefCounted

const PositionalCombatScript = preload("res://src/combat/PositionalCardCombatV41.gd")

const PATHS := {
	"cards": "res://data/combat/cards.json",
	"positions": "res://data/combat/position_data.json",
	"rulesets": "res://data/combat/rulesets.json",
	"factions": "res://data/factions/factions_v3.json",
}

var cards: Dictionary = {}
var positions: Dictionary = {}
var rulesets: Dictionary = {}
var factions: Dictionary = {}

func load_all() -> Dictionary:
	cards = _load_json(str(PATHS["cards"]))
	positions = _load_json(str(PATHS["positions"]))
	rulesets = _load_json(str(PATHS["rulesets"]))
	factions = _load_json(str(PATHS["factions"]))
	return validate()

func validate() -> Dictionary:
	var errors: Array[String] = []
	var card_list: Array = cards.get("cartas", [])
	if card_list.size() != 20:
		errors.append("cards_count_must_be_20")
	var card_ids := {}
	for raw in card_list:
		if typeof(raw) != TYPE_DICTIONARY:
			errors.append("card_not_dictionary")
			continue
		var card: Dictionary = raw
		var card_id := str(card.get("id", ""))
		if card_id == "" or card_ids.has(card_id):
			errors.append("invalid_or_duplicate_card_id:%s" % card_id)
		card_ids[card_id] = true
		for field in ["origem", "lado", "destino", "set_side", "custo", "moral", "deck_cost"]:
			if not card.has(field):
				errors.append("card_missing_%s:%s" % [field, card_id])
	if positions.get("posicoes", {}).size() != 8:
		errors.append("positions_count_must_be_8")
	if rulesets.get("rulesets", {}).size() != 6:
		errors.append("rulesets_count_must_be_6")
	var faction_ids: Array = factions.get("faccoes", {}).keys()
	faction_ids.sort()
	if faction_ids != ["ALE", "LEM", "NTM"]:
		errors.append("factions_must_be_exactly_ALE_LEM_NTM")
	return {
		"ok": errors.is_empty(),
		"errors": errors,
		"cards": card_list.size(),
		"positions": positions.get("posicoes", {}).size(),
		"rulesets": rulesets.get("rulesets", {}).size(),
		"factions": faction_ids,
	}

func create_combat(fighter_decks: Dictionary, narrative_flags: Dictionary = {}) -> Node:
	var combat: Node = PositionalCombatScript.new()
	combat.call("configure", cards, positions, rulesets, fighter_decks, narrative_flags)
	return combat

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}
