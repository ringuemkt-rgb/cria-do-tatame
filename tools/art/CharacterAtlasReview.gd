extends Control

const MANIFEST := "res://production/character_art_v1/atlas_manifest.json"
const Preview = preload("res://tools/art/CharacterAtlasPreview.gd")

var entries: Array = []
var lookup: Dictionary = {}
var selected_character_id := ""
var texture_cache: Dictionary = {}
var character_list: ItemList
var heading: Label
var details: Label
var previews: Array[Control] = []

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Character art manifest must be a dictionary")
		return
	entries = parsed.get("characters", [])
	_build_ui()
	for index in range(entries.size()):
		var entry: Dictionary = entries[index]
		var id := str(entry.get("character_id", ""))
		lookup[id] = entry
		for alias in entry.get("aliases", []):
			lookup[str(alias)] = entry
		character_list.add_item(str(entry.get("display_name", id)))
		character_list.set_item_metadata(index, id)
	character_list.item_selected.connect(_on_item_selected)
	if not entries.is_empty():
		character_list.select(0)
		select_character(str(entries[0].get("character_id", "")))

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("0b0b0d")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)
	var root_box := VBoxContainer.new()
	margin.add_child(root_box)
	var title := Label.new()
	title.text = "CRIA DO TATAME • IDENTIDADE DOS PERSONAGENS"
	title.add_theme_color_override("font_color", Color("c9971c"))
	title.add_theme_font_size_override("font_size", 24)
	root_box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "39 personagens • Frente / perfil / costas • Estudos para revisão"
	root_box.add_child(subtitle)
	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_box.add_child(content)
	character_list = ItemList.new()
	character_list.custom_minimum_size = Vector2(245, 0)
	character_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(character_list)
	var sheet := VBoxContainer.new()
	sheet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(sheet)
	heading = Label.new()
	heading.add_theme_font_size_override("font_size", 22)
	sheet.add_child(heading)
	var views := HBoxContainer.new()
	views.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sheet.add_child(views)
	for label_text in ["FRENTE", "PERFIL DIREITO", "COSTAS"]:
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		views.add_child(column)
		var label := Label.new()
		label.text = label_text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(label)
		var preview := Control.new()
		preview.set_script(Preview)
		preview.custom_minimum_size = Vector2(128, 128)
		preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
		column.add_child(preview)
		preview.resized.connect(preview.queue_redraw)
		previews.append(preview)
	var guides := CheckButton.new()
	guides.text = "Mostrar quadro 128 × 128 e apoio dos pés"
	guides.button_pressed = true
	guides.toggled.connect(_set_guides)
	sheet.add_child(guides)
	details = Label.new()
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.custom_minimum_size.y = 100
	sheet.add_child(details)

func _on_item_selected(index: int) -> void:
	select_character(str(character_list.get_item_metadata(index)))

func select_character(id: String) -> bool:
	if not lookup.has(id):
		return false
	var entry: Dictionary = lookup[id]
	selected_character_id = str(entry["character_id"])
	heading.text = str(entry.get("display_name", selected_character_id))
	var path := "res://" + str(entry["image"])
	if not texture_cache.has(path):
		texture_cache[path] = load(path) as Texture2D
	var texture: Texture2D = texture_cache[path]
	if texture == null:
		return false
	var edge_count := 0
	for index in range(3):
		var frame: Dictionary = entry["frames"][index]
		var rect: Array = frame["content_rect"]
		previews[index].call("set_source", texture,
			Rect2(float(rect[0]), float(rect[1]), float(rect[2]), float(rect[3])),
			float(entry.get("preview_body_height_px", 72)))
		if bool(frame.get("source_edge_touch", false)):
			edge_count += 1
	details.text = "Traje: %s • Origem: %s\nArte estática candidata; caminhada e combate ainda não animados.\nRevisar contorno, identidade, acessórios e direitos antes de promover. Células com contato na borda: %d.\nA escala exibida serve à revisão; os PNGs originais não foram normalizados ou alterados." % [
		str(entry.get("appearance_variant", "civil")).to_upper(), str(entry["atlas_id"]), edge_count]
	return true

func _set_guides(enabled: bool) -> void:
	for preview in previews:
		preview.set("show_guides", enabled)
		preview.queue_redraw()
