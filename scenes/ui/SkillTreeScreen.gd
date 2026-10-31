extends Control

const RulesScript = preload("res://src/progression/SkillTreeRulesV1.gd")
const VisualTheme = preload("res://src/ui/CriaVisualTheme.gd")
const HUB_SCENE := "res://scenes/hubs/TerreiroDaLuta.tscn"

var rules
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
var _compact_layout := false
var top_desktop: HBoxContainer
var top_compact: VBoxContainer
var content_desktop: HBoxContainer
var mobile_tabs: TabContainer
var path_panel: PanelContainer
var node_scroll: ScrollContainer
var detail_panel: PanelContainer
var back_button: Button

func _ready() -> void:
	rules = RulesScript.new()
	_build_ui()
	_apply_responsive_layout()
	get_viewport().size_changed.connect(_apply_responsive_layout)
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
	top_desktop = HBoxContainer.new()
	top_desktop.add_theme_constant_override("separation", 18)
	layout.add_child(top_desktop)
	top_compact = VBoxContainer.new()
	top_compact.add_theme_constant_override("separation", 6)
	top_compact.visible = false
	layout.add_child(top_compact)
	header = Label.new()
	header.text = "FORJA DE HABILIDADES"
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	VisualTheme.style_heading(header, 27, VisualTheme.HONOR)
	top_desktop.add_child(header)
	points_label = Label.new()
	points_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	points_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	points_label.add_theme_font_size_override("font_size", 18)
	points_label.add_theme_color_override("font_color", VisualTheme.CYAN)
	top_desktop.add_child(points_label)
	back_button = Button.new()
	back_button.text = "VOLTAR AO TERREIRO"
	back_button.custom_minimum_size = Vector2(180, 52)
	VisualTheme.apply_action_button(back_button, VisualTheme.RIVER)
	back_button.pressed.connect(_back_to_hub)
	top_desktop.add_child(back_button)
	var sub := Label.new()
	sub.text = "5 CAMINHOS • 51 NÓS • DESBLOQUEIO SEQUENCIAL • EFEITOS DE ATRIBUTO PENDENTES DE BALANCEAMENTO"
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", VisualTheme.OFF_WHITE)
	layout.add_child(sub)
	content_desktop = HBoxContainer.new()
	content_desktop.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_desktop.add_theme_constant_override("separation", 12)
	layout.add_child(content_desktop)
	mobile_tabs = TabContainer.new()
	mobile_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mobile_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mobile_tabs.visible = false
	layout.add_child(mobile_tabs)
	path_panel = PanelContainer.new()
	path_panel.name = "CAMINHOS"
	path_panel.custom_minimum_size = Vector2(202, 0)
	path_panel.add_theme_stylebox_override("panel", VisualTheme.panel_style(0.96, VisualTheme.GOLD, 1, 9))
	content_desktop.add_child(path_panel)
	paths_box = VBoxContainer.new()
	paths_box.add_theme_constant_override("separation", 8)
	path_panel.add_child(paths_box)
	node_scroll = ScrollContainer.new()
	node_scroll.name = "HABILIDADES"
	node_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	node_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_desktop.add_child(node_scroll)
	nodes_box = VBoxContainer.new()
	nodes_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nodes_box.add_theme_constant_override("separation", 8)
	node_scroll.add_child(nodes_box)
	detail_panel = PanelContainer.new()
	detail_panel.name = "DETALHES"
	detail_panel.custom_minimum_size = Vector2(320, 0)
	detail_panel.add_theme_stylebox_override("panel", VisualTheme.panel_style(0.94, VisualTheme.RIVER, 2, 9))
	content_desktop.add_child(detail_panel)
	var detail_col := VBoxContainer.new()
	detail_col.add_theme_constant_override("separation", 18)
	detail_panel.add_child(detail_col)
	var title := Label.new()
	title.text = "DETALHES DA HABILIDADE"
	VisualTheme.style_heading(title, 18, VisualTheme.HONOR)
	detail_col.add_child(title)
	var detail_scroll := ScrollContainer.new()
	detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_col.add_child(detail_scroll)
	details = Label.new()
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_color_override("font_color", VisualTheme.OFF_WHITE)
	details.add_theme_font_size_override("font_size", 16)
	detail_scroll.add_child(details)
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

# Mobile uses three tabs instead of squeezing 202px + 320px panels around
# the node list. The SAME controls move between layouts; no duplicated state.
func _apply_responsive_layout() -> void:
	_apply_responsive_layout_for_size(get_viewport().get_visible_rect().size)

func _apply_responsive_layout_for_size(viewport_size: Vector2) -> void:
	_compact_layout = viewport_size.x < 980.0
	var margin: MarginContainer = get_child(1) as MarginContainer
	var padding := 12 if _compact_layout else 24
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, padding)
	var top_target: Container = top_compact if _compact_layout else top_desktop
	for control in [header, points_label, back_button]:
		if control.get_parent() != top_target:
			control.reparent(top_target, false)
	top_desktop.visible = not _compact_layout
	top_compact.visible = _compact_layout
	header.add_theme_font_size_override("font_size", 22 if _compact_layout else 27)
	points_label.add_theme_font_size_override("font_size", 15 if _compact_layout else 18)
	back_button.custom_minimum_size = Vector2(0, 48) if _compact_layout else Vector2(180, 52)
	var panel_target: Container = mobile_tabs if _compact_layout else content_desktop
	for panel in [path_panel, node_scroll, detail_panel]:
		if panel.get_parent() != panel_target:
			panel.reparent(panel_target, false)
		if not _compact_layout:
			panel.visible = true
	content_desktop.visible = not _compact_layout
	mobile_tabs.visible = _compact_layout
	path_panel.custom_minimum_size = Vector2.ZERO if _compact_layout else Vector2(202, 0)
	detail_panel.custom_minimum_size = Vector2.ZERO if _compact_layout else Vector2(320, 0)
	if _compact_layout:
		mobile_tabs.current_tab = clampi(mobile_tabs.current_tab, 0, 2)

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
	if _compact_layout:
		mobile_tabs.current_tab = 1

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
		btn.clip_text = true
		btn.tooltip_text = btn.text
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
		btn.clip_text = true
		btn.tooltip_text = label
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
	if _compact_layout:
		mobile_tabs.current_tab = 2

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
	var requirement_text: String = "Início do caminho" if requirement == "" else str(rules.display_name(requirement))
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
	if not SaveManager.save_game(1):
		_transitioning = false
		status_label.text = "Falha ao salvar. Permanecendo na árvore de habilidades."
		return
	var err := get_tree().change_scene_to_file(HUB_SCENE)
	if err != OK:
		_transitioning = false
		status_label.text = "Não foi possível voltar ao Terreiro."

func _clear(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()
