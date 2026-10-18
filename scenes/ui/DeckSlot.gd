extends PanelContainer

signal card_dropped(card_id: String, slot_kind: String, slot_index: int)
signal remove_requested(slot_kind: String, slot_index: int)

var slot_kind := "active"
var slot_index := 0

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and bool(get_meta("occupied", false)):
		remove_requested.emit(slot_kind, slot_index)
		accept_event()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and has_focus() and bool(get_meta("occupied", false)):
		remove_requested.emit(slot_kind, slot_index)
		accept_event()

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return (
		typeof(data) == TYPE_DICTIONARY
		and str(data.get("type", "")) == "combat_deck_card"
		and str(data.get("kind", "")) == slot_kind
	)

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	card_dropped.emit(str(data.get("card_id", "")), slot_kind, slot_index)
