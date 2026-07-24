class_name SkillHubLoadoutV41
extends Node

signal card_unlocked(card_id: String, source: String)
signal card_trained(card_id: String, mastery: int)
signal loadout_changed(owner_id: String, deck: Array[String])

const DECK_SIZE := 12
const MAX_DUPLICATES := 2

var catalog: Dictionary = {}
var unlocked: Dictionary = {}
var mastery: Dictionary = {}
var loadouts: Dictionary = {}
var deck_points_by_owner: Dictionary = {}

func configure(cards_payload: Dictionary, starter_decks: Dictionary = {}) -> Dictionary:
	catalog.clear()
	unlocked.clear()
	for raw in cards_payload.get("cartas", []):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var card: Dictionary = raw.duplicate(true)
		var card_id := str(card.get("id", ""))
		if card_id == "":
			continue
		catalog[card_id] = card
		if str(card.get("raridade", "base")) == "base":
			unlocked[card_id] = true
	for owner_id_value in starter_decks.keys():
		var owner_id := str(owner_id_value)
		loadouts[owner_id] = _sanitize_deck(starter_decks[owner_id_value], owner_id)
	return {"ok": catalog.size() == 20, "cards": catalog.size(), "loadouts": loadouts.size()}

func set_deck_points(owner_id: String, points: int) -> void:
	deck_points_by_owner[owner_id] = maxi(points, 0)

func unlock(card_id: String, source: String) -> Dictionary:
	if not catalog.has(card_id):
		return {"ok": false, "error": "card_missing"}
	if not ["training", "master", "skill_tree", "story_flag", "belt"].has(source):
		return {"ok": false, "error": "invalid_unlock_source"}
	unlocked[card_id] = true
	card_unlocked.emit(card_id, source)
	return {"ok": true, "card_id": card_id, "source": source}

func train(card_id: String, repetitions: int, cria_cost: int, available_criacoin: int) -> Dictionary:
	if not bool(unlocked.get(card_id, false)):
		return {"ok": false, "error": "card_locked"}
	if repetitions <= 0 or cria_cost < 0:
		return {"ok": false, "error": "invalid_training"}
	if available_criacoin < cria_cost:
		return {"ok": false, "error": "insufficient_criacoin", "required": cria_cost}
	var gain := maxi(1, int(round(sqrt(float(repetitions)) * 4.0)))
	mastery[card_id] = clampi(int(mastery.get(card_id, 0)) + gain, 0, 100)
	card_trained.emit(card_id, int(mastery[card_id]))
	return {"ok": true, "mastery": int(mastery[card_id]), "spent_criacoin": cria_cost}

func set_loadout(owner_id: String, requested_cards: Array) -> Dictionary:
	var sanitized := _sanitize_deck(requested_cards, owner_id)
	if sanitized.size() != DECK_SIZE:
		return {"ok": false, "error": "deck_must_have_12_cards", "accepted": sanitized.size()}
	var cost := _deck_cost(sanitized)
	var capacity := int(deck_points_by_owner.get(owner_id, 999))
	if cost > capacity:
		return {"ok": false, "error": "deck_points_exceeded", "cost": cost, "capacity": capacity}
	loadouts[owner_id] = sanitized
	loadout_changed.emit(owner_id, sanitized.duplicate())
	return {"ok": true, "deck": sanitized.duplicate(), "deck_cost": cost}

func add_to_loadout(owner_id: String, card_id: String) -> Dictionary:
	if not catalog.has(card_id):
		return {"ok": false, "error": "card_missing"}
	if not bool(unlocked.get(card_id, false)):
		return {"ok": false, "error": "card_locked"}
	var deck: Array = loadouts.get(owner_id, []).duplicate()
	if deck.size() >= DECK_SIZE:
		return {"ok": false, "error": "deck_full"}
	if deck.count(card_id) >= MAX_DUPLICATES:
		return {"ok": false, "error": "duplicate_limit"}
	deck.append(card_id)
	var capacity := int(deck_points_by_owner.get(owner_id, 999))
	if _deck_cost(deck) > capacity:
		return {"ok": false, "error": "deck_points_exceeded"}
	loadouts[owner_id] = deck
	loadout_changed.emit(owner_id, deck.duplicate())
	return {"ok": true, "deck": deck.duplicate()}

func remove_from_loadout(owner_id: String, slot_index: int) -> Dictionary:
	var deck: Array = loadouts.get(owner_id, []).duplicate()
	if slot_index < 0 or slot_index >= deck.size():
		return {"ok": false, "error": "invalid_slot"}
	deck.remove_at(slot_index)
	loadouts[owner_id] = deck
	loadout_changed.emit(owner_id, deck.duplicate())
	return {"ok": true, "deck": deck.duplicate()}

func get_loadout(owner_id: String) -> Array[String]:
	var output: Array[String] = []
	for value in loadouts.get(owner_id, []):
		output.append(str(value))
	return output

func get_hub_collection() -> Array:
	var output: Array = []
	for card_id_value in catalog.keys():
		var card_id := str(card_id_value)
		var card: Dictionary = catalog[card_id].duplicate(true)
		card["unlocked"] = bool(unlocked.get(card_id, false))
		card["mastery"] = int(mastery.get(card_id, 0))
		output.append(card)
	output.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("raridade", "")) + str(a.get("nome", "")) < str(b.get("raridade", "")) + str(b.get("nome", ""))
	)
	return output

func export_state() -> Dictionary:
	return {
		"unlocked": unlocked.duplicate(true),
		"mastery": mastery.duplicate(true),
		"loadouts": loadouts.duplicate(true),
		"deck_points": deck_points_by_owner.duplicate(true),
	}

func import_state(state: Dictionary) -> void:
	unlocked.merge(state.get("unlocked", {}), true)
	mastery = state.get("mastery", {}).duplicate(true)
	deck_points_by_owner = state.get("deck_points", {}).duplicate(true)
	loadouts.clear()
	for owner_value in state.get("loadouts", {}).keys():
		var owner_id := str(owner_value)
		loadouts[owner_id] = _sanitize_deck(state["loadouts"][owner_value], owner_id)

func _sanitize_deck(values: Array, owner_id: String) -> Array[String]:
	var output: Array[String] = []
	for value in values:
		var card_id := str(value)
		if not catalog.has(card_id):
			continue
		if not bool(unlocked.get(card_id, false)) and str(catalog[card_id].get("raridade", "base")) != "base":
			continue
		if output.count(card_id) >= MAX_DUPLICATES:
			continue
		if output.size() >= DECK_SIZE:
			break
		output.append(card_id)
	return output

func _deck_cost(deck: Array) -> int:
	var total := 0
	for card_id_value in deck:
		total += int(catalog.get(str(card_id_value), {}).get("deck_cost", 0))
	return total
