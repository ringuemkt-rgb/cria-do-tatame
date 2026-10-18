extends Control

const MANIFEST := "res://production/grappling_gifs_v1/manifest.json"
var clips: Array = []
var selected_id := ""
var pose_index := 0
var elapsed := 0.0
var playing := false
var active_clip: Dictionary = {}
var source_texture: Texture2D
var preview: TextureRect
var caption: Label
var details: RichTextLabel
var clip_list: ItemList

func _ready() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Missing grappling review manifest")
		return
	clips = parsed.get("clips", [])
	_build_ui()
	for clip in clips:
		clip_list.add_item(str(clip["name"]))
	clip_list.item_selected.connect(func(index: int): select_clip(str(clips[index]["id"])))
	if not clips.is_empty():
		clip_list.select(0)
		select_clip(str(clips[0]["id"]))

func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)
	var column := VBoxContainer.new()
	margin.add_child(column)
	var title := Label.new()
	title.text = "CRIA DO TATAME • ANIMÁTICOS NO-GI PARA REVISÃO"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("c9971c"))
	column.add_child(title)
	var warning := Label.new()
	warning.text = "13 prévias • 6 poses cada • Redesenho e revisão técnica pendentes • Sem vínculo ao combate"
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(warning)
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(row)
	clip_list = ItemList.new()
	clip_list.custom_minimum_size.x = 275
	clip_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(clip_list)
	var stage := VBoxContainer.new()
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(stage)
	preview = TextureRect.new()
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.custom_minimum_size = Vector2(256, 256)
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.add_child(preview)
	caption = Label.new()
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stage.add_child(caption)
	var buttons := HBoxContainer.new()
	stage.add_child(buttons)
	for text_value in ["Reproduzir", "Pausar", "Próxima pose", "Reiniciar"]:
		var button := Button.new()
		button.text = text_value
		buttons.add_child(button)
		match text_value:
			"Reproduzir": button.pressed.connect(func(): playing = true)
			"Pausar": button.pressed.connect(func(): playing = false)
			"Próxima pose": button.pressed.connect(func(): playing = false; advance_pose())
			"Reiniciar": button.pressed.connect(restart)
	details = RichTextLabel.new()
	details.custom_minimum_size.y = 155
	stage.add_child(details)

func select_clip(id: String) -> bool:
	for clip in clips:
		if str(clip["id"]) != id:
			continue
		var texture := load("res://" + str(clip["source_image"])) as Texture2D
		if texture == null:
			return false
		active_clip = clip
		selected_id = id
		source_texture = texture
		restart()
		details.text = "REDESENHO NECESSÁRIO • Revisão biomecânica pendente\n" + "\n".join(clip["visual_observations"])
		return true
	return false

func restart() -> void:
	pose_index = 0
	elapsed = 0.0
	playing = false
	_update_pose()

func _process(delta: float) -> void:
	advance_time(delta)

func advance_time(delta: float) -> void:
	if not playing or active_clip.is_empty() or delta < 0.0:
		return
	elapsed += delta
	while playing and elapsed >= float(active_clip["duration_ms"][pose_index]) / 1000.0:
		elapsed -= float(active_clip["duration_ms"][pose_index]) / 1000.0
		if pose_index == 5:
			playing = false
			elapsed = 0.0
		else:
			pose_index += 1
	_update_pose()

func advance_pose() -> void:
	pose_index = mini(pose_index + 1, 5)
	elapsed = 0.0
	_update_pose()

func _update_pose() -> void:
	if active_clip.is_empty():
		return
	var rect: Array = active_clip["frame_rects"][pose_index]
	var region := AtlasTexture.new()
	region.atlas = source_texture
	region.region = Rect2(float(rect[0]), float(rect[1]), float(rect[2]), float(rect[3]))
	preview.texture = region
	var labels := ["Preparação", "Entrada", "Encaixe planejado", "Estabilização planejada", "Resposta / soltura", "Recuperação"]
	if str(active_clip["family"]) == "combat_flow":
		labels = ["Em pé", "Queda", "Passagem planejada", "Montada", "Chave de braço", "Soltura"]
	caption.text = "%s • Pose %d/6 • %s" % [str(active_clip["name"]), pose_index + 1, str(labels[pose_index])]
