class_name CombatDeckRuntimeV2
extends RefCounted

const MIN_DECK_SIZE := 6
const MAX_DECK_SIZE := 8
const HAND_SIZE := 6
const PRESET_IDS := ["ofensivo", "defensivo", "adaptativo"]

var deck: Array[String] = []
var hand: Array[String] = []
var draw_pile: Array[String] = []
var discard: Array[String] = []
var presets: Dictionary = {}
var seed: int = 0
var rng := RandomNumberGenerator.new()

func build_deck(available_techniques: Array, selection: Array) -> Dictionary:
	var available: Dictionary = {}
	for raw in available_techniques:
		available[str(raw)] = true
	var normalized: Array[String] = []
	for raw in selection:
		var technique_id := str(raw)
		if technique_id == "":
			continue
		if not available.has(technique_id):
			return {"ok": false, "reason": "technique_locked", "technique_id": technique_id}
		if normalized.has(technique_id):
			return {"ok": false, "reason": "duplicate_technique", "technique_id": technique_id}
		normalized.append(technique_id)
	if normalized.size() < MIN_DECK_SIZE or normalized.size() > MAX_DECK_SIZE:
		return {"ok": false, "reason": "deck_size_invalid", "size": normalized.size()}
	deck = normalized
	hand.clear()
	draw_pile.clear()
	discard.clear()
	return {"ok": true, "deck": deck.duplicate()}

func save_preset(preset_id: String) -> Dictionary:
	if preset_id not in PRESET_IDS:
		return {"ok": false, "reason": "invalid_preset"}
	if deck.size() < MIN_DECK_SIZE:
		return {"ok": false, "reason": "deck_not_ready"}
	presets[preset_id] = deck.duplicate()
	return {"ok": true, "preset_id": preset_id}

func load_preset(preset_id: String, available_techniques: Array) -> Dictionary:
	if not presets.has(preset_id):
		return {"ok": false, "reason": "preset_missing"}
	return build_deck(available_techniques, presets[preset_id])

func shuffle_deck(seed_value: int) -> void:
	seed = seed_value
	rng.seed = seed
	draw_pile = deck.duplicate()
	discard.clear()
	_fisher_yates(draw_pile)

func draw_hand() -> Array:
	hand.clear()
	_refill_to(HAND_SIZE)
	return hand.duplicate()

func play_card(technique_id: String) -> bool:
	if not hand.has(technique_id):
		return false
	hand.erase(technique_id)
	discard.append(technique_id)
	return true

func refill_hand() -> Array:
	_refill_to(HAND_SIZE)
	return hand.duplicate()

func contains_in_hand(technique_id: String) -> bool:
	return hand.has(technique_id)

func to_dict() -> Dictionary:
	return {
		"version": "2.0.0",
		"seed": seed,
		"deck": deck.duplicate(),
		"hand": hand.duplicate(),
		"draw_pile": draw_pile.duplicate(),
		"discard": discard.duplicate(),
		"presets": presets.duplicate(true)
	}

func load_from_dict(data: Dictionary) -> void:
	seed = int(data.get("seed", 0))
	rng.seed = seed
	deck = _string_array(data.get("deck", []))
	hand = _string_array(data.get("hand", []))
	draw_pile = _string_array(data.get("draw_pile", []))
	discard = _string_array(data.get("discard", []))
	presets = data.get("presets", {}).duplicate(true) if typeof(data.get("presets", {})) == TYPE_DICTIONARY else {}

func _refill_to(target_size: int) -> void:
	while hand.size() < mini(target_size, deck.size()):
		if draw_pile.is_empty():
			_reshuffle_discard()
		if draw_pile.is_empty():
			break
		hand.append(draw_pile.pop_back())

func _reshuffle_discard() -> void:
	if discard.is_empty():
		return
	draw_pile = discard.duplicate()
	discard.clear()
	_fisher_yates(draw_pile)

func _fisher_yates(values: Array[String]) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var tmp := values[index]
		values[index] = values[swap_index]
		values[swap_index] = tmp

func _string_array(values: Array) -> Array[String]:
	var out: Array[String] = []
	for value in values:
		out.append(str(value))
	return out
