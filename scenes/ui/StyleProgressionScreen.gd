extends Control

const HUB_SCENE := "res://scenes/hubs/TerreiroDaLuta.tscn"
const VisualTheme = preload("res://src/ui/CriaVisualTheme.gd")
const FighterStyleSystemScript = preload("res://src/career/FighterStyleSystem.gd")

var style_system: RefCounted
var selected_style_id := "pressao"
var style_buttons: Dictionary = {}
var node_buttons: Dictionary = {}

@onready var style_grid: GridContainer = $Margin/Layout/Body/StylesPanel/Layout/StyleGrid
@onready var branches: HBoxContainer = $Margin/Layout/Body/TreePanel/Layout/Scroll/Branches
@onready var points_label: Label = $Margin/Layout/TopBar/Points
@onready var active_label: Label = $Margin/Layout/TopBar/Active
@onready var style_name: Label = $Margin/Layout/Body/DetailPanel/Layout/StyleName
@onready var archetype_label: Label = $Margin/Layout/Body/DetailPanel/Layout/Archetype
@onready var affinity_label: Label = $Margin/Layout/Body/DetailPanel/Layout/Affinity
@onready var requirements_label: Label = $Margin/Layout/Body/DetailPanel/Layout/Requirements
@onready var signatures_label: Label = $Margin/Layout/Body/DetailPanel/Layout/Signatures
@onready var status_label: Label = $Margin/Layout/Body/DetailPanel/Layout/Status
@onready var activate_button: Button = $Margin/Layout/Body/DetailPanel/Layout/Activate
@onready var feedback_label: Label = $Margin/Layout/Body/DetailPanel/Layout/Feedback

func _ready() -> void:
	style_system = FighterStyleSystemScript.new()
	selected_style_id = str(style_system.call("get_active_style_id"))
	_style_screen()
	$Margin/Layout/TopBar/Back.pressed.connect(_on_back_pressed)
	activate_button.pressed.connect(_on_activate_pressed)
	_build_style_buttons()
	_build_skill_tree()
	_refresh()

func _style_screen() -> void:
	$Margin/Layout/Body/StylesPanel.add_theme_stylebox_override("panel", VisualTheme.panel_style(0.96, VisualTheme.GOLD, 2, 6))
	$Margin/Layout/Body/TreePanel.add_theme_stylebox_override("panel", VisualTheme.panel_style(0.96, VisualTheme.RIVER, 2, 6))
	$Margin/Layout/Body/DetailPanel.add_theme_stylebox_override("panel", VisualTheme.panel_style(0.96, VisualTheme.GOLD, 2, 6))
	VisualTheme.style_heading($Margin/Layout/TopBar/Title, 28, VisualTheme.HONOR)
	VisualTheme.style_heading($Margin/Layout/Body/StylesPanel/Layout/Title, 15, VisualTheme.HONOR)
	VisualTheme.style_heading($Margin/Layout/Body/TreePanel/Layout/Title, 17, VisualTheme.CYAN)
	VisualTheme.style_heading(style_name, 23, VisualTheme.HONOR)
	VisualTheme.style_tactical_text(points_label, VisualTheme.CYAN, 14)
	VisualTheme.style_tactical_text(active_label, VisualTheme.HONOR, 14)
	VisualTheme.style_tactical_text($Margin/Layout/Body/StylesPanel/Layout/Hint, Color("c8bfa6"), 10)
	VisualTheme.style_tactical_text($Margin/Layout/Footer, Color("c8bfa6"), 11)
	for label in [archetype_label, affinity_label, requirements_label, signatures_label, status_label, feedback_label]:
		VisualTheme.style_tactical_text(label, VisualTheme.OFF_WHITE, 12)
	VisualTheme.apply_primary_button($Margin/Layout/TopBar/Back)
	VisualTheme.apply_primary_button(activate_button)

func _build_style_buttons() -> void:
	for child in style_grid.get_children():
		child.queue_free()
	style_buttons.clear()
	for style_value in style_system.call("list_styles"):
		var style: Dictionary = style_value
		var style_id := str(style.get("id", ""))
		var button := Button.new()
		button.custom_minimum_size = Vector2(120, 66)
		button.text = str(style.get("name", style_id)).to_upper()
		button.tooltip_text = str(style.get("archetype", ""))
		VisualTheme.apply_action_button(button, Color(str(style.get("color", "#B8860B"))))
		button.pressed.connect(_select_style.bind(style_id))
		style_grid.add_child(button)
		style_buttons[style_id] = button

func _build_skill_tree() -> void:
	for child in branches.get_children():
		child.queue_free()
	node_buttons.clear()
	for branch_value in style_system.call("list_branches"):
		var branch: Dictionary = branch_value
		var accent := Color(str(branch.get("color", "#B8860B")))
		var column := VBoxContainer.new()
		column.custom_minimum_size = Vector2(150, 0)
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var title := Label.new()
		title.text = str(branch.get("name", branch.get("id", ""))).to_upper()
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		VisualTheme.style_heading(title, 14, accent)
		column.add_child(title)
		for node_value in branch.get("nodes", []):
			var node: Dictionary = node_value
			var node_id := str(node.get("id", ""))
			var button := Button.new()
			button.custom_minimum_size = Vector2(0, 72)
			VisualTheme.apply_action_button(button, accent)
			button.pressed.connect(_purchase_node.bind(node_id))
			column.add_child(button)
			node_buttons[node_id] = button
		branches.add_child(column)

func _select_style(style_id: String) -> void:
	selected_style_id = style_id
	feedback_label.text = "Revise requisitos e tecnicas antes de ativar."
	_refresh()

func _purchase_node(node_id: String) -> void:
	var result: Dictionary = style_system.call("purchase_node", node_id)
	if bool(result.get("ok", false)):
		feedback_label.text = "Habilidade evoluida para nivel %d." % int(result.get("level", 0))
		SaveManager.save_game(1)
	else:
		feedback_label.text = _error_text(str(result.get("error", "purchase_failed")))
	_refresh()

func _on_activate_pressed() -> void:
	var result: Dictionary = style_system.call("set_active_style", selected_style_id)
	if bool(result.get("ok", false)):
		feedback_label.text = "Estilo ativo. O proximo combate usara esta leitura."
		SaveManager.save_game(1)
	else:
		feedback_label.text = _error_text(str(result.get("error", "style_failed")))
	_refresh()

func _refresh() -> void:
	var active_id := str(style_system.call("get_active_style_id"))
	points_label.text = "PONTOS: %d" % WorldState.skill_points
	active_label.text = "ATIVO: %s" % active_id.to_upper()
	for style_id_value in style_buttons.keys():
		var style_id := str(style_id_value)
		var button: Button = style_buttons[style_id]
		var style: Dictionary = DataRegistry.get_fighter_style(style_id)
		var unlocked := bool(style_system.call("is_style_unlocked", style_id))
		var suffix := "BLOQUEADO"
		if style_id == active_id:
			suffix = "ATIVO"
		elif unlocked:
			suffix = "LIBERADO"
		button.text = "%s\n%s" % [str(style.get("name", style_id)).to_upper(), suffix]
		button.disabled = false
	_refresh_nodes()
	_refresh_detail()

func _refresh_nodes() -> void:
	for node_id_value in node_buttons.keys():
		var node_id := str(node_id_value)
		var node: Dictionary = DataRegistry.get_skill_tree_node(node_id)
		var level := int(style_system.call("get_node_level", node_id))
		var max_level := int(node.get("max_level", 10))
		var cost := int(node.get("cost_per_level", 1))
		var button: Button = node_buttons[node_id]
		button.text = "%s\nNIVEL %d/%d • CUSTO %d" % [str(node.get("name", node_id)).to_upper(), level, max_level, cost]
		button.disabled = level >= max_level or WorldState.skill_points < cost

func _refresh_detail() -> void:
	var style := DataRegistry.get_fighter_style(selected_style_id)
	if style.is_empty():
		return
	var accent := Color(str(style.get("color", "#B8860B")))
	VisualTheme.style_heading(style_name, 23, accent)
	style_name.text = str(style.get("name", selected_style_id)).to_upper()
	archetype_label.text = str(style.get("archetype", ""))
	affinity_label.text = "AFINIDADE NARRATIVA: %s" % str(style.get("faction_affinity", "NEUTRA"))
	var requirement_lines := []
	var requirements: Dictionary = style.get("requirements", {})
	for branch_value in requirements.keys():
		var branch_id := str(branch_value)
		requirement_lines.append("%s %d/%d" % [branch_id.to_upper(), int(style_system.call("get_branch_points", branch_id)), int(requirements[branch_value])])
	requirements_label.text = "REQUISITOS\n%s" % " • ".join(requirement_lines)
	var signature_names := []
	for technique_id_value in style.get("signature_techniques", []):
		var technique: Dictionary = DataRegistry.get_technique(str(technique_id_value))
		signature_names.append(str(technique.get("nome", technique_id_value)))
	signatures_label.text = "ASSINATURAS\n%s" % " • ".join(signature_names)
	var unlocked := bool(style_system.call("is_style_unlocked", selected_style_id))
	var is_active := selected_style_id == str(style_system.call("get_active_style_id"))
	status_label.text = "EVOLUA OS RAMOS PARA LIBERAR"
	if is_active:
		status_label.text = "ESTILO ATIVO"
	elif unlocked:
		status_label.text = "PRONTO PARA ATIVAR"
	activate_button.disabled = not unlocked or is_active

func _error_text(error: String) -> String:
	match error:
		"insufficient_skill_points": return "Pontos de habilidade insuficientes."
		"node_maxed": return "Esta habilidade ja atingiu o nivel maximo."
		"style_locked": return "Este estilo ainda esta bloqueado pelos requisitos."
		"style_not_found", "node_not_found": return "Dado de progressao nao encontrado."
	return "Nao foi possivel concluir a evolucao."

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(HUB_SCENE)
