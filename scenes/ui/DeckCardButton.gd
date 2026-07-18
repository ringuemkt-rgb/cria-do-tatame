extends Button

var card_data: Dictionary = {}

func setup(card: Dictionary) -> void:
	card_data = card.duplicate(true)
	var level := int(card_data.get("level", 1))
	text = "%s\nNv.%d  %s" % [
		str(card_data.get("name", "Carta")),
		level,
		"◆".repeat(level)
	]
	disabled = not bool(card_data.get("unlocked", false))
	tooltip_text = "%s • %s • XP %d/%d" % [
		str(card_data.get("category", "tecnica")).capitalize(),
		str(card_data.get("technique_id", "")),
		int(card_data.get("xp", 0)),
		int(card_data.get("xp_to_next", 100))
	]

func _get_drag_data(_at_position: Vector2) -> Variant:
	if card_data.is_empty() or disabled:
		return null
	var preview := Label.new()
	preview.text = str(card_data.get("name", "Carta"))
	preview.add_theme_font_size_override("font_size", 16)
	set_drag_preview(preview)
	return {
		"type": "combat_deck_card",
		"card_id": str(card_data.get("id", "")),
		"kind": str(card_data.get("kind", "active"))
	}
