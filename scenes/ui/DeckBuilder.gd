extends Control

const HUB_SCENE := "res://scenes/hubs/TerreiroDaLuta.tscn"
const CardButtonScript = preload("res://scenes/ui/DeckCardButton.gd")
const DeckSlotScript = preload("res://scenes/ui/DeckSlot.gd")
const VisualTheme = preload("res://src/ui/CriaVisualTheme.gd")

@onready var collection_grid: GridContainer = $Margin/Layout/Body/CollectionPanel/Collection/Scroll/CollectionGrid
@onready var active_slots: HBoxContainer = $Margin/Layout/Body/GiPanel/Gi/ActiveSlots
@onready var passive_slots: HBoxContainer = $Margin/Layout/Body/GiPanel/Gi/PassiveSlots
@onready var status_label: Label = $Margin/Layout/Status
@onready var belt_label: Label = $Margin/Layout/Belt

var selected_card_id := ""

func _ready() -> void:
	_style_screen()
	$Margin/Layout/Actions/Back.pressed.connect(_on_back)
	$Margin/Layout/Actions/Save.pressed.connect(_on_save)
	$Margin/Layout/Actions/UpgradeXP.pressed.connect(_on_upgrade.bind("xp"))
	$Margin/Layout/Actions/UpgradeMoney.pressed.connect(_on_upgrade.bind("money"))
	_refresh_all()

func _style_screen() -> void:
	VisualTheme.style_heading($Margin/Layout/Title, 34, VisualTheme.HONOR)
	$Margin/Layout/Subtitle.add_theme_color_override("font_color", VisualTheme.OFF_WHITE)
	$Margin/Layout/Belt.add_theme_color_override("font_color", VisualTheme.CYAN)
	$Margin/Layout/Body/CollectionPanel.add_theme_stylebox_override("panel", VisualTheme.panel_style(0.94, VisualTheme.RIVER, 1, 10))
	$Margin/Layout/Body/GiPanel.add_theme_stylebox_override("panel", VisualTheme.panel_style(0.94, VisualTheme.GOLD, 2, 10))
	VisualTheme.apply_primary_button($Margin/Layout/Actions/Save)
	VisualTheme.apply_action_button($Margin/Layout/Actions/Back, VisualTheme.RIVER)
	VisualTheme.apply_action_button($Margin/Layout/Actions/UpgradeXP, VisualTheme.GOLD)
	VisualTheme.apply_action_button($Margin/Layout/Actions/UpgradeMoney, VisualTheme.CYAN)

func _refresh_all() -> void:
	belt_label.text = "FAIXA %s • LIMITE DE CARTA Nv.%d" % [
		DeckManager.belt.to_upper(),
		int(DeckManager.BELT_LEVEL_LIMIT.get(DeckManager.belt, 2))
	]
	_clear_children(collection_grid)
	for card_value in DeckManager.get_collection():
		var card: Dictionary = card_value
		var button := CardButtonScript.new()
		button.custom_minimum_size = Vector2(180, 76)
		button.call("setup", card)
		VisualTheme.apply_action_button(button, VisualTheme.GOLD if card.get("kind", "active") == "active" else VisualTheme.CYAN)
		button.pressed.connect(_on_collection_card_pressed.bind(str(card.get("id", ""))))
		collection_grid.add_child(button)
	_build_slots(active_slots, "active", DeckManager.ACTIVE_LIMIT, DeckManager.active_deck)
	_build_slots(passive_slots, "passive", DeckManager.PASSIVE_LIMIT, DeckManager.passive_deck)

func _build_slots(container: HBoxContainer, kind: String, count: int, equipped: Array[String]) -> void:
	_clear_children(container)
	for index in range(count):
		var slot := DeckSlotScript.new()
		slot.set("slot_kind", kind)
		slot.set("slot_index", index)
		slot.custom_minimum_size = Vector2(132, 88)
		slot.add_theme_stylebox_override("panel", VisualTheme.panel_style(0.72, VisualTheme.GOLD if kind == "active" else VisualTheme.CYAN, 1, 8))
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if index < equipped.size() and DeckManager.cards.has(equipped[index]):
			var card: Dictionary = DeckManager.cards[equipped[index]]
			label.text = "%s\nNv.%d" % [str(card.get("name", "Carta")), int(card.get("level", 1))]
		else:
			label.text = "%s %d\nARRASTE AQUI" % [kind.to_upper(), index + 1]
		slot.add_child(label)
		slot.connect("card_dropped", _on_card_dropped)
		container.add_child(slot)

func _on_collection_card_pressed(card_id: String) -> void:
	selected_card_id = card_id
	var card: Dictionary = DeckManager.cards.get(card_id, {})
	if card.is_empty() or not bool(card.get("unlocked", false)):
		_set_status("Carta bloqueada. Treine no Terreiro para liberar.", true)
		return
	var result: Dictionary = DeckManager.equip_card(card_id, str(card.get("kind", "active")))
	_set_status("Carta equipada." if result.get("ok", false) else _error_text(str(result.get("error", "erro"))), not bool(result.get("ok", false)))
	_refresh_all()

func _on_upgrade(payment: String) -> void:
	if selected_card_id == "":
		_set_status("Selecione uma carta da coleção primeiro.", true)
		return
	var result: Dictionary = DeckManager.upgrade_card(selected_card_id, payment)
	if bool(result.get("ok", false)):
		_set_status("Carta aperfeiçoada no Terreiro.", false)
		SaveManager.save_game(1)
	else:
		_set_status(_error_text(str(result.get("error", "erro"))), true)
	_refresh_all()

func _on_card_dropped(card_id: String, kind: String, index: int) -> void:
	var result: Dictionary = DeckManager.equip_card(card_id, kind, index)
	_set_status("Slot do Gi atualizado." if result.get("ok", false) else _error_text(str(result.get("error", "erro"))), not bool(result.get("ok", false)))
	_refresh_all()

func _on_save() -> void:
	_set_status("Deck salvo." if SaveManager.save_game(1) else "Falha ao salvar o deck.", false)

func _on_back() -> void:
	SaveManager.save_game(1)
	get_tree().change_scene_to_file(HUB_SCENE)

func _set_status(message: String, is_error: bool) -> void:
	status_label.text = message
	status_label.add_theme_color_override("font_color", VisualTheme.CONFLICT if is_error else VisualTheme.HONOR)

func _error_text(error: String) -> String:
	match error:
		"deck_full": return "Slots completos. Arraste a carta para substituir um slot."
		"slot_kind_mismatch": return "Cartas ativas e passivas ocupam zonas diferentes do Gi."
		"card_locked_or_missing": return "Carta bloqueada ou inexistente."
		"card_xp_insufficient": return "XP técnico insuficiente para aperfeiçoar esta carta."
		"money_insufficient": return "Dinheiro insuficiente para o treino particular."
		"belt_level_limit": return "Sua faixa atual limita o nível desta carta."
	return error.replace("_", " ")

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
