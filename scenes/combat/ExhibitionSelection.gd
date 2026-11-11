extends Control

## Local exhibition only: no career rewards, no unlocks and no save mutations.
const COMBAT_SCENE := "res://scenes/combat/CombatArenaBase.tscn"
const RETURN_SCENE := "res://scenes/combat/PreFightHub.tscn"
const ProfilesScript = preload("res://src/combat/FighterCombatProfileRegistryV1.gd")

var profiles
var player_select: OptionButton
var opponent_select: OptionButton
var status: Label

func _ready() -> void:
	profiles = ProfilesScript.new()
	_create_interface()
	if not profiles.ready():
		status.text = "Cadastro inválido: " + ", ".join(profiles.errors())
		return
	_populate_fighters()

func _create_interface() -> void:
	var background := ColorRect.new()
	background.color = Color("#0B0B0D")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var layout := VBoxContainer.new()
	layout.name = "Layout"
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 36.0
	layout.offset_top = 26.0
	layout.offset_right = -36.0
	layout.offset_bottom = -26.0
	layout.add_theme_constant_override("separation", 16)
	add_child(layout)

	var heading := Label.new()
	heading.text = "EXIBIÇÃO LIVRE • ELENCO COMPLETO"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 26)
	heading.add_theme_color_override("font_color", Color("#C9971C"))
	layout.add_child(heading)

	var note := Label.new()
	note.text = "Escolha qualquer dupla do elenco canônico. Atributos e animações ainda são prévias; a carreira não é alterada."
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(note)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	layout.add_child(row)
	for index in range(2):
		var panel := VBoxContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(panel)
		var title := Label.new()
		title.text = "PERSONAGEM JOGADOR" if index == 0 else "ADVERSÁRIO CONTROLADO PELA IA"
		panel.add_child(title)
		var picker := OptionButton.new()
		picker.custom_minimum_size = Vector2(100, 62)
		picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_child(picker)
		if index == 0:
			player_select = picker
		else:
			opponent_select = picker

	status = Label.new()
	status.name = "Status"
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.text = "Preparando cadastro..."
	layout.add_child(status)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 20)
	layout.add_child(footer)
	var back := Button.new()
	back.text = "VOLTAR"
	back.custom_minimum_size = Vector2(170, 64)
	back.pressed.connect(_on_back)
	footer.add_child(back)
	var start := Button.new()
	start.name = "Start"
	start.text = "INICIAR CONFRONTO"
	start.custom_minimum_size = Vector2(280, 64)
	start.pressed.connect(_on_start)
	footer.add_child(start)

func _populate_fighters() -> void:
	player_select.clear()
	opponent_select.clear()
	var names := profiles.fighter_ids()
	for id in names:
		var entry: Dictionary = profiles.profile(id)
		var label := str(entry.get("display_name", id))
		player_select.add_item(label)
		player_select.set_item_metadata(player_select.item_count - 1, id)
		opponent_select.add_item(label)
		opponent_select.set_item_metadata(opponent_select.item_count - 1, id)
	if names.size() >= 2:
		player_select.select(0)
		opponent_select.select(1)
	status.text = "%d lutadores registrados • preparação de luta não autoriza conteúdo final." % names.size()

func _on_start() -> void:
	if profiles == null or not profiles.ready() or player_select.selected < 0 or opponent_select.selected < 0:
		status.text = "O elenco ainda não está disponível."
		return
	var first := str(player_select.get_item_metadata(player_select.selected))
	var second := str(opponent_select.get_item_metadata(opponent_select.selected))
	var plan: Dictionary = CombatManager.prepare_exhibition_match(first, second, "arena_do_dique")
	if not bool(plan.get("ok", false)):
		status.text = "Confronto bloqueado: " + str(plan.get("error", "desconhecido"))
		return
	var result: Error = get_tree().change_scene_to_file(COMBAT_SCENE)
	if result != OK:
		CombatManager.cancel_exhibition_match()
		status.text = "Não foi possível abrir a luta: " + error_string(result)

func _on_back() -> void:
	CombatManager.cancel_exhibition_match()
	get_tree().change_scene_to_file(RETURN_SCENE)
