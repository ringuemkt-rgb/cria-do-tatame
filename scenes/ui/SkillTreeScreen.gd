extends Control

const RulesScript = preload("res://src/progression/SkillTreeRulesV1.gd")
const VisualTheme = preload("res://src/ui/CriaVisualTheme.gd")
const HUB_SCENE := "res://scenes/hubs/TerreiroDaLuta.tscn"

var rules: RefCounted
var path_id := "pressure"
var selected_skill := ""
var header: Label
var points_label: Label
var status_label: Label
var paths_box: VBoxContainer
var nodes_box: VBoxContainer
var details: Label
var unlock_btn: Button
var _transitioning := false

func _ready() -> void:
	rules = RulesScript.new()
	_build_ui()
	if not rules.is_valid():
		status_label.text = "ERRO: contrato da árvore indisponível."
		unlock_btn.disabled = true
		return
	_choose_path(path_id)

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("0b0b0d")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 18)
	layout.add_child(top)
	header = Label.new()
	header.text = "FORJA DE HABILIDADES"
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	VisualTheme.style_heading(header, 27, VisualTheme.HONOR)
	top.add_child(header)
	points_label = Label.new()
	points_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	points_label.add_theme_font_size_override("font_size", 18)
	points_label.add_theme_color_override("font_color", VisualTheme.CYAN)
	top.add_child(points_label)
	var back := Button.new()
	back.text = "VOLTAR AO TERREIRO"
	back.custom_minimum_size = Vector2(180, 52)
	VisualTheme.apply_action_button(back, VisualTheme.RIVER)
	back.pressed.connect(_back_to_hub)
	top.add_child(back)
	var sub := Label.new()
	sub.text = "5 CAMINHOS • 51 NÓS • DESBLOQUEIO SEQUENCIAL • EFEITOS DE ATRIBUTO PENDENTES DE BALANCEAMENTO"
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", VisualTheme.OFF_WHITE)
	layout.add_child(sub)
	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	layout.add_child(content)
	var selector := PanelContainer.new()
	selector.custom_minimum_size = Vector2(202, 0)
	selector.add_theme_stylebox_override("panel", VisualTheme.panel_style(0.96, VisualTheme.GOLD, 1, 9))
	content.add_child(selector)
	paths_box = VBoxContainer.new()
	paths_box.add_theme_constant_override("separation", 8)
	selector.add_child(paths_box)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	nodes_box = VBoxContainer.new()
	nodes_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nodes_box.add_theme_constant_override("separation", 8)
	scroll.add_child(nodes_box)
	var detail_panel := PanelContainer.new()
	detail_panel.custom_minimum_size = Vector2(320, 0)
	detail_panel.add_theme_stylebox_override("panel", VisualTheme.panel_style(0.94, VisualTheme.RIVER, 2, 9))
	content.add_child(detail_panel)
	var detail_col := VBoxContainer.new()
	detail_col.add_theme_constant_override("separation", 18)
	detail_panel.add_child(detail_col)
	var title := Label.new()
	title.text = "DETALHES DA HABILIDADE"
	VisualTheme.style_heading(title, 18, VisualTheme.HONOR)
	detail_col.add_child(title)
	details = Label.new()
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details.add_theme_color_override("font_color", VisualTheme.OFF_WHITE)
	details.add_theme_font_size_override("font_size", 16)
	detail_col.add_child(details)
	unlock_btn = Button.new()
	unlock_btn.text = "DESBLOQUEAR"
	unlock_btn.custom_minimum_size = Vector2(0, 60)
	VisualTheme.apply_primary_button(unlock_btn)
	unlock_btn.pressed.connect(_purchase_selected)
	detail_col.add_child(unlock_btn)
	status_label = Label.new()
	status_label.text = "Escolha um caminho. O progresso é salvo com o personagem."
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_color_override("font_color", VisualTheme.HONOR)
	layout.add_child(status_label)

func _choose_path(new_path_id: String) -> void:
	path_id = new_path_id
	selected_skill = ""
	for raw in rules.list_paths():
		if str(raw.get("id", "")) == path_id:
			var ids: Array = raw.get("nodes", [])
			if not ids.is_empty():
				selected_skill = str(ids[0])
			break
	_refresh()

func _refresh() -> void:
	if not rules.is_valid():
		return
	points_label.text = "PONTOS: %d  •  FAIXA: %s" % [int(WorldState.skill_points), str(WorldState.belt).to_upper()]
	_clear(paths_box)
	for raw in rules.list_paths():
		var item: Dictionary = raw
		var id := str(item.get("id", ""))
		var btn := Button.new()
		btn.text = str(item.get("display_name", id)).to_upper()
		btn.custom_minimum_size = Vector2(0, 56)
		VisualTheme.apply_action_button(btn, Color(str(item.get("color", "#c9971c"))))
		btn.modulate = Color.WHITE if id == path_id else Color(0.80, 0.80, 0.80)
		btn.pressed.connect(_choose_path.bind(id))
		paths_box.add_child(btn)
	_clear(nodes_box)
	for raw in rules.list_nodes(path_id):
		var node: Dictionary = raw
		var id := str(node["id"])
		var owned := WorldState.unlocked_skills.has(id)
		var permitted: Dictionary = rules.evaluate(id, WorldState.unlocked_skills, WorldState.skill_points)
		var marker := "✓ " if owned else ("+ " if bool(permitted.get("ok", false)) else "🔒 ")
		var label := "%s%02d. %s" % [marker, int(node["index"]) + 1, rules.display_name(id)]
		if bool(node.get("capstone", false)):
			label += "  ★"
		var btn := Button.new()
		btn.text = label
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 54)
		VisualTheme.apply_action_button(btn, Color(str(node["color"])))
		if id == selected_skill:
			btn.modulate = Color("ffd86e")
		elif not owned and not bool(permitted.get("ok", false)):
			btn.modulate = Color(0.62, 0.62, 0.62)
		btn.pressed.connect(_select_skill.bind(id))
		nodes_box.add_child(btn)
	_show_selected()

func _select_skill(id: String) -> void:
	selected_skill = id
	_refresh()

func _show_selected() -> void:
	var node: Dictionary = rules.get_node(selected_skill)
	if node.is_empty():
		details.text = "Nenhuma habilidade selecionada."
		unlock_btn.disabled = true
		return
	var owned := WorldState.unlocked_skills.has(selected_skill)
	var result: Dictionary = rules.evaluate(selected_skill, WorldState.unlocked_skills, WorldState.skill_points)
	var reward := str(node.get("card_reward", ""))
	var effect := "Carta de técnica: %s" % reward if reward != "" else "Progresso registrado; bônus numérico ainda não está balanceado."
	var requirement := str(node.get("requires", ""))
	var requirement_text := "Início do caminho" if requirement == "" else rules.display_name(requirement)
	var state := "DESBLOQUEADA" if owned else ("DISPONÍVEL" if result.get("ok", false) else "BLOQUEADA")
	details.text = "%s\n\nCAMINHO: %s\nESTADO: %s\nPRÉ-REQUISITO: %s\nCUSTO PROVISÓRIO: %d PONTO\n\nRECOMPENSA\n%s\n\nO combate não recebe atributos inventados. Pontos e desbloqueios persistem no save." % [
		rules.display_name(selected_skill).to_upper(),
		str(node.get("path_name", "")),
		state, requirement_text, int(rules.policy.get("cost_per_node", 1)), effect
	]
	unlock_btn.disabled = not bool(result.get("ok", false))
	unlock_btn.text = "JÁ DESBLOQUEADA" if owned else ("DESBLOQUEAR • 1 PONTO" if bool(result.get("ok", false)) else "INDISPONÍVEL")

func _purchase_selected() -> void:
	var result: Dictionary = rules.purchase(selected_skill, WorldState, DeckManager)
	if bool(result.get("ok", false)):
		var saved := SaveManager.save_game(1)
		status_label.text = "Habilidade desbloqueada e salva." if saved else "Habilidade desbloqueada; falha ao gravar save."
	else:
		status_label.text = "Não desbloqueada: %s" % str(result.get("error", "erro")).replace("_", " ")
	_refresh()

func _back_to_hub() -> void:
	if _transitioning:
		return
	_transitioning = true
	SaveManager.save_game(1)
	var err := get_tree().change_scene_to_file(HUB_SCENE)
	if err != OK:
		_transitioning = false
		status_label.text = "Não foi possível voltar ao Terreiro."

func _clear(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()
