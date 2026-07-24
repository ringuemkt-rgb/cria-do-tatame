class_name SkillHubLoadout
extends Node

## Serviço do Hub de Habilidades.
## Controla desbloqueio, treino, custo de deck e montagem sem gacha.

signal card_unlocked(card_id: String)
signal card_trained(card_id: String, mastery: int)
signal loadout_changed(owner_id: String, deck: Array[String])

const DECK_SIZE := 12
const MAX_DUPLICATES := 2

var catalog: Dictionary = {}
var unlocked: Dictionary = {}
var mastery: Dictionary = {}
var loadouts: Dictionary = {}

func configure(card_catalog: Array, starter_decks: Dictionary = {}) -> Dictionary:
	catalog.clear()
	for raw_card in card_catalog:
		if typeof(raw_card) != TYPE_DICTIONARY:
			continue
		var card: Dictionary = raw_card.duplicate(true)
		var card_id := str(card.get("id", ""))
		if card_id == "":
			continue
		catalog[card_id] = card
		if str(card.get("rarity", "base")) == "base":
			unlocked[card_id] = true
	for owner_id_value in starter_decks.keys():
		var owner_id := str(owner_id_value)
		loadouts[owner_id] = _sanitize_deck(starter_decks[owner_id_value])
	return {"ok": not catalog.is_empty(), "cards": catalog.size(), "loadouts": loadouts.size()}

func unlock(card_id: String, source: String) -> Dictionary:
	if not catalog.has(card_id):
		return {"ok": false, "error": "card_missing"}
	if not ["training", "master", "skill_tree", "story_flag"].has(source):
		return {"ok": false, "error": "invalid_unlock_source"}
	unlocked[card_id] = true
	card_unlocked.emit(card_id)
	return {"ok": true, "card_id": card_id, "source": source}

func train(card_id: String, repetitions: int, cria_cost: int, available_cria: int) -> Dictionary:
	if not bool(unlocked.get(card_id, false)):
		return {"ok": false, "error": "card_locked"}
	if repetitions <= 0 or cria_cost < 0:
		return {"ok": false, "error": "invalid_training"}
	if available_cria < cria_cost:
		return {"ok": false, "error": "insufficient_criacoin", "required": cria_cost}
	var gain := maxi(1, int(round(sqrt(float(repetitions)) * 4.0)))
	mastery[card_id] = clampi(int(mastery.get(card_id, 0)) + gain, 0, 100)
	card_trained.emit(card_id, int(mastery[card_id]))
	return {"ok": true, "mastery": int(mastery[card_id]), "spent_criacoin": cria_cost}

func set_loadout(owner_id: String, requested_cards: Array) -> Dictionary:
	var sanitized := _sanitize_deck(requested_cards)
	if sanitized.size() != DECK_SIZE:
		return {"ok": false, "error": "deck_must_have_12_cards", "accepted": sanitized.size()}
	loadouts[owner_id] = sanitized
	loadout_changed.emit(owner_id, sanitized.duplicate())
	return {"ok": true, "deck": sanitized.duplicate()}

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
		return str(a.get("hub_branch", "")) + str(a.get("name", "")) < str(b.get("hub_branch", "")) + str(b.get("name", ""))
	)
	return output

func _sanitize_deck(values: Array) -> Array[String]:
	var output: Array[String] = []
	for value in values:
		var card_id := str(value)
		if not catalog.has(card_id):
			continue
		if not bool(unlocked.get(card_id, false)) and str(catalog[card_id].get("rarity", "base")) != "base":
			continue
		if output.count(card_id) >= MAX_DUPLICATES:
			continue
		if output.size() >= DECK_SIZE:
			break
		output.append(card_id)
	return output
