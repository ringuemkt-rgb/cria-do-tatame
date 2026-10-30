extends Control

const HUB_SCENE := "res://scenes/hubs/TerreiroDaLuta.tscn"
const CardButtonScript = preload("res://scenes/ui/DeckCardButton.gd")
const DeckSlotScript = preload("res://scenes/ui/DeckSlot.gd")
const VisualTheme = preload("res://src/ui/CriaVisualTheme.gd")

@onready var collection_grid: GridContainer = $Margin/Scroll/Layout/Body/CollectionPanel/Collection/Scroll/CollectionGrid
@onready var active_slots: GridContainer = $Margin/Scroll/Layout/Body/GiPanel/Gi/ActiveSlots
@onready var passive_slots: GridContainer = $Margin/Scroll/Layout/Body/GiPanel/Gi/PassiveSlots
@onready var status_label: Label = $Margin/Scroll/Layout/Status
@onready var belt_label: Label = $Margin/Scroll/Layout/Belt

var selected_card_id := ""
var _compact_layout := false

func _ready() -> void:
	_style_screen()
	_apply_responsive_layout()
	get_viewport().size_changed.connect(_apply_responsive_layout)
	$Margin/Scroll/Layout/Actions/Back.pressed.connect(_on_back)
	$Margin/Scroll/Layout/Actions/Save.pressed.connect(_on_save)
	$Margin/Scroll/Layout/Actions/UpgradeXP.pressed.connect(_on_upgrade.bind("xp"))
	$Margin/Scroll/Layout/Actions/UpgradeMoney.pressed.connect(_on_upgrade.bind("money"))
	_refresh_all()

func _style_screen() -> void:
	VisualTheme.style_heading($Margin/Scroll/Layout/Title, 34, VisualTheme.HONOR)
	$Margin/Scroll/Layout/Subtitle.add_theme_color_override("font_color", VisualTheme.OFF_WHITE)
	$Margin/Scroll/Layout/Belt.add_theme_color_override("font_color", VisualTheme.CYAN)
	$Margin/Scroll/Layout/Body/CollectionPanel.add_theme_stylebox_override("panel", VisualTheme.panel_style(0.94, VisualTheme.RIVER, 1, 10))
	$Margin/Scroll/Layout/Body/GiPanel.add_theme_stylebox_override("panel", VisualTheme.panel_style(0.94, VisualTheme.GOLD, 2, 10))
	VisualTheme.apply_primary_button($Margin/Scroll/Layout/Actions/Save)
	VisualTheme.apply_action_button($Margin/Scroll/Layout/Actions/Back, VisualTheme.RIVER)
	VisualTheme.apply_action_button($Margin/Scroll/Layout/Actions/UpgradeXP, VisualTheme.GOLD)
	VisualTheme.apply_action_button($Margin/Scroll/Layout/Actions/UpgradeMoney, VisualTheme.CYAN)


# The deck builder must remain operable on portrait phones: all five active
# slots, three passive slots, collection and actions are reachable by scroll.
# No change to DeckManager authority, card IDs, or save schema.
func _apply_responsive_layout() -> void:
	_apply_responsive_layout_for_size(get_viewport().get_visible_rect().size)

func _apply_responsive_layout_for_size(viewport_size: Vector2) -> void:
	_compact_layout = viewport_size.x < 1200.0
	var margin: MarginContainer = $Margin
	var horizontal_margin := 12 if _compact_layout else 40
	var vertical_margin := 12 if _compact_layout else 24
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, horizontal_margin)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, vertical_margin)
	var body: BoxContainer = $Margin/Scroll/Layout/Body
	body.orientation = BoxContainer.VERTICAL if _compact_layout else BoxContainer.HORIZONTAL
	body.size_flags_vertical = Control.SIZE_SHRINK_BEGIN if _compact_layout else Control.SIZE_EXPAND_FILL
	var collection_panel: PanelContainer = $Margin/Scroll/Layout/Body/CollectionPanel
	collection_panel.custom_minimum_size = Vector2(0, 180) if _compact_layout else Vector2.ZERO
	var gi_panel: PanelContainer = $Margin/Scroll/Layout/Body/GiPanel
	gi_panel.custom_minimum_size = Vector2.ZERO if _compact_layout else Vector2(720, 0)
	collection_grid.columns = 1 if _compact_layout else 2
	active_slots.columns = 3 if _compact_layout else 5
	passive_slots.columns = 3
	var actions: GridContainer = $Margin/Scroll/Layout/Actions
	actions.columns = 2 if _compact_layout else 4
	for child in actions.get_children():
		if child is Button:
			child.custom_minimum_size = Vector2(136 if _compact_layout else 190, 52)
	for label in [
		$Margin/Scroll/Layout/Body/GiPanel/Gi/ActiveLabel,
		$Margin/Scroll/Layout/Body/GiPanel/Gi/PassiveLabel
	]:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var hint: Label = $Margin/Scroll/Layout/Body/GiPanel/Gi/Hint
	hint.text = "Toque na carta para equipar; REMOVER libera um slot. Arrastar é opcional." if _compact_layout else "Arraste uma carta para o slot ou toque para equipar no primeiro espaço disponível."

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

func _build_slots(container: GridContainer, kind: String, count: int, equipped: Array[String]) -> void:
	_clear_children(container)
	for index in range(count):
		var slot := DeckSlotScript.new()
		slot.set("slot_kind", kind)
		slot.set("slot_index", index)
		slot.set_meta("occupied", index < equipped.size())
		slot.focus_mode = Control.FOCUS_ALL
		slot.tooltip_text = "Cartas equipadas: clique com o botão direito ou pressione Voltar para remover." if index < equipped.size() else "Arraste uma carta da coleção para este espaço."
		slot.custom_minimum_size = Vector2(96, 88) if _compact_layout else Vector2(132, 88)
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
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var slot_content := VBoxContainer.new()
		slot_content.add_theme_constant_override("separation", 4)
		slot_content.add_child(label)
		if index < equipped.size():
			var remove_btn := Button.new()
			remove_btn.text = "REMOVER"
			remove_btn.custom_minimum_size = Vector2(0, 32)
			VisualTheme.apply_action_button(remove_btn, VisualTheme.CONFLICT)
			remove_btn.pressed.connect(_on_remove_slot.bind(kind, index))
			slot_content.add_child(remove_btn)
		slot.add_child(slot_content)
		slot.connect("card_dropped", _on_card_dropped)
		slot.connect("remove_requested", _on_remove_slot)
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

func _on_remove_slot(kind: String, index: int) -> void:
	var result: Dictionary = DeckManager.unequip_card(kind, index)
	_set_status("Carta removida do Gi." if result.get("ok", false) else _error_text(str(result.get("error", "erro"))), not bool(result.get("ok", false)))
	_refresh_all()

func _on_card_dropped(card_id: String, kind: String, index: int) -> void:
	var result: Dictionary = DeckManager.equip_card(card_id, kind, index)
	_set_status("Slot do Gi atualizado." if result.get("ok", false) else _error_text(str(result.get("error", "erro"))), not bool(result.get("ok", false)))
	_refresh_all()

func _on_save() -> void:
	var saved := SaveManager.save_game(1)
	_set_status("Deck salvo." if saved else "Falha ao salvar o deck.", not saved)

func _on_back() -> void:
	if not SaveManager.save_game(1):
		_set_status("Falha ao salvar. Permanecendo no editor de deck.", true)
		return
	if get_tree().change_scene_to_file(HUB_SCENE) != OK:
		_set_status("Não foi possível voltar ao Terreiro.", true)

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
		"last_active_card": return "Mantenha pelo menos uma técnica ativa equipada."
		"invalid_slot": return "Este espaço de carta é inválido."
	return error.replace("_", " ")

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
