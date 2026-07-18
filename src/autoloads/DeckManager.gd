extends Node

const ACTIVE_LIMIT := 5
const PASSIVE_LIMIT := 3
const HAND_SIZE := 3
const BELT_LEVEL_LIMIT := {
	"branca": 2,
	"azul": 3,
	"roxa": 4,
	"marrom": 5,
	"preta": 5
}

var owner_id := "ruan_macacao"
var belt := "branca"
var cards: Dictionary = {}
var active_deck: Array[String] = []
var passive_deck: Array[String] = []
var hand: Array[String] = []
var draw_cursor := 0
var selected_card_id := ""

func _ready() -> void:
	_ensure_input_actions()
	var source: Dictionary = DataRegistry.combat_deck if DataRegistry != null else {}
	configure_from_data(source)
	if not SignalBus.belt_promoted.is_connected(_on_belt_promoted):
		SignalBus.belt_promoted.connect(_on_belt_promoted)

func configure_from_data(source: Dictionary) -> Dictionary:
	cards.clear()
	active_deck.clear()
	passive_deck.clear()
	hand.clear()
	draw_cursor = 0
	selected_card_id = ""
	if source.is_empty():
		return {"ok": false, "error": "deck_data_missing"}
	owner_id = str(source.get("owner_id", "ruan_macacao"))
	belt = str(source.get("belt", "branca"))
	for value in source.get("cards", []):
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var card: Dictionary = value.duplicate(true)
		var card_id := str(card.get("id", ""))
		if card_id != "":
			cards[card_id] = card
	var equipped: Dictionary = source.get("equipped", {})
	active_deck = _valid_equipped(equipped.get("active", []), "active", ACTIVE_LIMIT)
	passive_deck = _valid_equipped(equipped.get("passive", []), "passive", PASSIVE_LIMIT)
	start_combat_hand()
	return {"ok": true, "cards": cards.size(), "active": active_deck.size(), "passive": passive_deck.size()}

func start_combat_hand() -> void:
	if has_node("/root/WorldState"):
		var world_belt := str(WorldState.belt)
		if BELT_LEVEL_LIMIT.has(world_belt):
			belt = world_belt
	hand.clear()
	draw_cursor = 0
	selected_card_id = ""
	while hand.size() < mini(HAND_SIZE, active_deck.size()):
		hand.append(active_deck[draw_cursor])
		draw_cursor += 1
	_emit_hand_changed()

func get_hand() -> Array:
	var output: Array = []
	for card_id in hand:
		if cards.has(card_id):
			output.append(cards[card_id].duplicate(true))
	return output

func get_collection() -> Array:
	var output: Array = []
	for value in cards.values():
		output.append(value.duplicate(true))
	output.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.get("name", "")) < str(b.get("name", "")))
	return output

func select_card(card_id: String) -> bool:
	if not hand.has(card_id) or not cards.has(card_id):
		return false
	selected_card_id = card_id
	SignalBus.combat_card_selected.emit(cards[card_id].duplicate(true))
	_emit_hand_changed()
	return true

func get_attack_card(technique_id: String, resources: Dictionary, current_state: String) -> Dictionary:
	var candidates: Array[String] = []
	if selected_card_id != "":
		candidates.append(selected_card_id)
	for card_id in hand:
		if not candidates.has(card_id):
			candidates.append(card_id)
	for card_id in candidates:
		var card: Dictionary = cards.get(card_id, {})
		if str(card.get("technique_id", "")) != technique_id:
			continue
		if not _state_is_valid(card, current_state) or not can_activate(card, resources):
			continue
		return card.duplicate(true)
	return {}

func get_defense_card(attack_family: String, resources: Dictionary, current_state: String) -> Dictionary:
	var best: Dictionary = {}
	for card_id in passive_deck + hand:
		var card: Dictionary = cards.get(card_id, {})
		if not bool(card.get("unlocked", false)):
			continue
		var responses: Array = card.get("response_to_families", [])
		if not responses.has(attack_family):
			continue
		if not _state_is_valid(card, current_state) or not can_activate(card, resources):
			continue
		if best.is_empty() or int(card.get("level", 1)) > int(best.get("level", 1)):
			best = card
	return best.duplicate(true)

func can_activate(card: Dictionary, resources: Dictionary) -> bool:
	var cost: Dictionary = card.get("activation_cost", {})
	return (
		float(resources.get("focus", 0.0)) >= float(cost.get("focus", 0.0))
		and float(resources.get("gas", 0.0)) >= float(cost.get("gas", 0.0))
	)

func consume_used_card(card_id: String, success: bool) -> Dictionary:
	if card_id == "" or not cards.has(card_id):
		return {}
	var card: Dictionary = cards[card_id]
	var xp_gain := 10 if success else 3
	card["xp"] = int(card.get("xp", 0)) + xp_gain
	cards[card_id] = card
	SignalBus.card_xp_changed.emit(card_id, int(card["xp"]), int(card.get("xp_to_next", 100)))
	if hand.has(card_id):
		hand.erase(card_id)
		_draw_until_full()
	selected_card_id = ""
	_emit_hand_changed()
	return card.duplicate(true)

func get_activation_cost(card_id: String) -> Dictionary:
	return cards.get(card_id, {}).get("activation_cost", {}).duplicate(true)

func equip_card(card_id: String, slot_kind: String, slot_index: int = -1) -> Dictionary:
	var card: Dictionary = cards.get(card_id, {})
	if card.is_empty() or not bool(card.get("unlocked", false)):
		return {"ok": false, "error": "card_locked_or_missing"}
	if str(card.get("kind", "")) != slot_kind:
		return {"ok": false, "error": "slot_kind_mismatch"}
	var target: Array[String] = active_deck if slot_kind == "active" else passive_deck
	var limit := ACTIVE_LIMIT if slot_kind == "active" else PASSIVE_LIMIT
	active_deck.erase(card_id)
	passive_deck.erase(card_id)
	if slot_index >= 0 and slot_index < target.size():
		target[slot_index] = card_id
	elif target.size() < limit:
		target.append(card_id)
	else:
		return {"ok": false, "error": "deck_full"}
	start_combat_hand()
	SignalBus.deck_configuration_changed.emit(to_dict())
	return {"ok": true}

func upgrade_card(card_id: String, payment: String = "xp") -> Dictionary:
	var card: Dictionary = cards.get(card_id, {})
	if card.is_empty() or not bool(card.get("unlocked", false)):
		return {"ok": false, "error": "card_locked_or_missing"}
	var level := int(card.get("level", 1))
	var max_level := int(BELT_LEVEL_LIMIT.get(belt, 2))
	if level >= max_level:
		return {"ok": false, "error": "belt_level_limit", "limit": max_level}
	var money_cost := level * 150
	if payment == "money":
		if not has_node("/root/WorldState") or int(WorldState.money) < money_cost:
			return {"ok": false, "error": "money_insufficient", "cost": money_cost}
		WorldState.money -= money_cost
	elif int(card.get("xp", 0)) >= int(card.get("xp_to_next", 100)):
		card["xp"] = int(card.get("xp", 0)) - int(card.get("xp_to_next", 100))
	else:
		return {"ok": false, "error": "card_xp_insufficient", "required": int(card.get("xp_to_next", 100))}
	card["level"] = level + 1
	card["xp_to_next"] = int(round(float(card.get("xp_to_next", 100)) * 1.8))
	cards[card_id] = card
	SignalBus.deck_configuration_changed.emit(to_dict())
	return {"ok": true, "card": card.duplicate(true)}

func unlock_card(card_id: String) -> Dictionary:
	var card: Dictionary = cards.get(card_id, {})
	if card.is_empty():
		return {"ok": false, "error": "card_missing"}
	if int(card.get("level", 1)) > int(BELT_LEVEL_LIMIT.get(belt, 2)):
		return {"ok": false, "error": "belt_level_limit"}
	card["unlocked"] = true
	cards[card_id] = card
	SignalBus.deck_configuration_changed.emit(to_dict())
	return {"ok": true, "card": card.duplicate(true)}

func passive_modifiers() -> Dictionary:
	var output: Dictionary = {}
	for card_id in passive_deck:
		var effect: Dictionary = cards.get(card_id, {}).get("passive_effect", {})
		for key_value in effect.keys():
			var key := str(key_value)
			output[key] = float(output.get(key, 0.0)) + float(effect[key_value])
	return output

func to_dict() -> Dictionary:
	return {
		"schema_version": "1.0.0",
		"owner_id": owner_id,
		"belt": belt,
		"limits": {"active": ACTIVE_LIMIT, "passive": PASSIVE_LIMIT, "hand": HAND_SIZE},
		"cards": get_collection(),
		"equipped": {"active": active_deck.duplicate(), "passive": passive_deck.duplicate()}
	}

func load_from_dict(data: Dictionary) -> void:
	if data.is_empty():
		return
	configure_from_data(data)

func _valid_equipped(values: Array, kind: String, limit: int) -> Array[String]:
	var output: Array[String] = []
	for value in values:
		var card_id := str(value)
		var card: Dictionary = cards.get(card_id, {})
		if card.is_empty() or str(card.get("kind", "")) != kind or not bool(card.get("unlocked", false)):
			continue
		if int(card.get("level", 1)) > int(BELT_LEVEL_LIMIT.get(belt, 2)):
			continue
		if not output.has(card_id) and output.size() < limit:
			output.append(card_id)
	return output

func _draw_until_full() -> void:
	if active_deck.is_empty():
		return
	var attempts := 0
	while hand.size() < mini(HAND_SIZE, active_deck.size()) and attempts < active_deck.size() * 2:
		var card_id := active_deck[draw_cursor % active_deck.size()]
		draw_cursor = (draw_cursor + 1) % active_deck.size()
		if not hand.has(card_id):
			hand.append(card_id)
		attempts += 1

func _state_is_valid(card: Dictionary, current_state: String) -> bool:
	var states: Array = card.get("valid_states", [])
	return states.is_empty() or states.has(current_state)

func _emit_hand_changed() -> void:
	SignalBus.combat_deck_hand_changed.emit(get_hand(), selected_card_id)

func _on_belt_promoted(new_belt) -> void:
	var normalized := str(new_belt).to_lower()
	if BELT_LEVEL_LIMIT.has(normalized):
		belt = normalized
		SignalBus.deck_configuration_changed.emit(to_dict())

func _ensure_input_actions() -> void:
	var bindings := [
		{"action": "deck_card_1", "key": KEY_1, "joy": JOY_BUTTON_DPAD_LEFT},
		{"action": "deck_card_2", "key": KEY_2, "joy": JOY_BUTTON_DPAD_UP},
		{"action": "deck_card_3", "key": KEY_3, "joy": JOY_BUTTON_DPAD_RIGHT}
	]
	for binding in bindings:
		var action := StringName(binding["action"])
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var key_event := InputEventKey.new()
		key_event.physical_keycode = int(binding["key"])
		if not InputMap.action_has_event(action, key_event):
			InputMap.action_add_event(action, key_event)
		var joy_event := InputEventJoypadButton.new()
		joy_event.button_index = int(binding["joy"])
		if not InputMap.action_has_event(action, joy_event):
			InputMap.action_add_event(action, joy_event)
