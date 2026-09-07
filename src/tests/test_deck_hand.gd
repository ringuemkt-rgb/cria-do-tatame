extends SceneTree
## Headless smoke do contrato canônico: DeckManager + CardSlot.
## godot --headless --script res://src/tests/test_deck_hand.gd

const SLOT_SCENE := "res://scenes/ui/card_slot.tscn"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	assert(has_node("/root/DeckManager"), "DeckManager autoload ausente")
	assert(FileAccess.file_exists(SLOT_SCENE), "card_slot.tscn ausente")

	var cards: Array = [
		_card("c1", "Baiana", ["GI", "NO-GI"], true, {"focus": 1, "gas": 2}),
		_card("c2", "Arco e Flecha", ["GI"], true, {"focus": 1}),
		_card("c3", "Sprawl", ["GI", "NO-GI"], true, {}),
		_card("c4", "Tesoura", ["GI", "NO-GI"], true, {"focus": 1}),
		_card("c5", "Knee Cut", ["GI", "NO-GI"], true, {"gas": 1}),
		_card("c6", "Heel Hook", ["NO-GI"], false, {"focus": 2}),
	]
	var source := {
		"schema_version": "1.0.0",
		"owner_id": "ruan_macacao",
		"belt": "branca",
		"limits": {"active": 5, "passive": 3, "hand": 4},
		"cards": cards,
		"equipped": {"active": ["c1", "c2", "c3", "c4", "c5"], "passive": []}
	}
	var configured: Dictionary = DeckManager.configure_from_data(source)
	assert(configured.get("ok", false), "configure_from_data falhou")
	assert(DeckManager.hand.size() == 4, "mão inicial deve ter 4 cartas")
	assert(DeckManager.active_deck.size() == 5, "deck ativo deve manter 5 cartas")

	assert(DeckManager.set_combat_format("NO-GI"), "NO-GI deve ser formato válido")
	assert(not DeckManager.select_card("c2"), "Arco e Flecha GI-only deve bloquear em NO-GI")
	assert(DeckManager.select_card("c1"), "carta GI+NO-GI deve selecionar")
	DeckManager.consume_used_card("c1", true)
	assert(DeckManager.hand.size() == 4, "mão deve recompor para 4")
	var hand_ids: Array[String] = []
	for item in DeckManager.get_hand():
		hand_ids.append(str(item.get("id", "")))
	assert(hand_ids.has("c5"), "rotação determinística deve puxar a quinta carta")
	assert(not DeckManager.select_card("c6"), "carta bloqueada não pode ser selecionada")

	var packed := load(SLOT_SCENE) as PackedScene
	assert(packed != null, "falha ao carregar CardSlot")
	var slot: CardSlot = packed.instantiate()
	get_root().add_child(slot)
	var rich_resources := {"gas": 100.0, "focus": 100.0, "moral": 100.0}
	slot.setup(cards[1], "NO-GI", rich_resources, "PLAYER_STANDING_NEUTRAL")
	assert(slot.is_blocked() and slot.block_reason == "FORMAT", "slot deve bloquear formato incompatível")
	slot.setup(cards[0], "NO-GI", {"gas": 0.0, "focus": 0.0, "moral": 100.0}, "PLAYER_STANDING_NEUTRAL")
	assert(slot.is_blocked() and slot.block_reason == "STAMINA", "slot deve bloquear recurso insuficiente")
	slot.setup(cards[0], "NO-GI", rich_resources, "PLAYER_STANDING_NEUTRAL")
	assert(not slot.is_blocked(), "slot deve liberar carta válida com recursos")

	print("✅ test_deck_hand: mão 4 + formato + lock + recursos + CardSlot PASSOU")
	quit(0)

func _card(id: String, title: String, formats: Array, unlocked: bool, activation_cost: Dictionary) -> Dictionary:
	return {
		"id": id,
		"name": title,
		"kind": "active",
		"category": "queda",
		"technique_id": "test_%s" % id,
		"level": 1,
		"base_power": 10,
		"activation_cost": activation_cost,
		"passive_effect": {},
		"clash_effect": {},
		"response_to_families": [],
		"valid_states": ["PLAYER_STANDING_NEUTRAL"],
		"formats": formats,
		"rarity": "rara",
		"xp": 0,
		"xp_to_next": 100,
		"unlocked": unlocked,
	}
