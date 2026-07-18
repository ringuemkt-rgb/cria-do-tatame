extends PanelContainer

signal card_dropped(card_id: String, slot_kind: String, slot_index: int)

var slot_kind := "active"
var slot_index := 0

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return (
		typeof(data) == TYPE_DICTIONARY
		and str(data.get("type", "")) == "combat_deck_card"
		and str(data.get("kind", "")) == slot_kind
	)

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	card_dropped.emit(str(data.get("card_id", "")), slot_kind, slot_index)
