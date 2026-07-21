extends PanelContainer
class_name NPCPresencePanel

const VisualTheme = preload("res://src/ui/CriaVisualTheme.gd")

const CHARACTER_ALIASES := {
	"cassio_molho_oliveira": "cassio_molho"
}

const PORTRAIT_PATHS := {
	"mestre_dende": "res://assets/graphics/characters/mestre_dende/portrait/dialogue_portrait_v01.png",
	"tinker_bell": "res://assets/graphics/characters/tinker_bell/portrait/dialogue_portrait_v01.png",
	"davi_relampago": "res://assets/graphics/characters/davi_relampago/portrait/dialogue_portrait_v01.png",
	"cassio_molho": "res://assets/graphics/characters/cassio_molho/portrait/dialogue_portrait_v01.png",
	"leoa_quilombola": "res://assets/graphics/characters/leoa_quilombola/portrait/dialogue_portrait_v01.png"
}

var hub_id: String = "itubera"
var _list: VBoxContainer


func configure(target_hub_id: String) -> void:
	hub_id = target_hub_id


func _ready() -> void:
	name = "NPCPresencePanel"
	z_index = 6
	mouse_filter = Control.MOUSE_FILTER_STOP
	anchor_left = 0.015
	anchor_top = 0.16
	anchor_right = 0.215
	anchor_bottom = 0.94
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	custom_minimum_size = Vector2(248.0, 330.0)
	add_theme_stylebox_override("panel", VisualTheme.panel_style(0.92, VisualTheme.GOLD, 2, 12))
	_build_content()
	if not SignalBus.npc_routine_changed.is_connected(_on_routine_changed):
		SignalBus.npc_routine_changed.connect(_on_routine_changed)
	if not SignalBus.day_advanced.is_connected(_on_day_advanced):
		SignalBus.day_advanced.connect(_on_day_advanced)
	_refresh()


func _build_content() -> void:
	var root := VBoxContainer.new()
	root.name = "Content"
	root.add_theme_constant_override("separation", 8)
	add_child(root)
	var title := Label.new()
	title.name = "Title"
	title.text = "PESSOAS NO TERRITÓRIO"
	VisualTheme.style_heading(title, 16, VisualTheme.HONOR)
	root.add_child(title)
	var context := Label.new()
	context.name = "Context"
	context.text = "Rotinas mudam com horário e clima"
	context.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	context.add_theme_color_override("font_color", Color("9fb3c8"))
	context.add_theme_font_size_override("font_size", 11)
	root.add_child(context)
	var separator := HSeparator.new()
	root.add_child(separator)
	_list = VBoxContainer.new()
	_list.name = "NPCList"
	_list.add_theme_constant_override("separation", 7)
	root.add_child(_list)


func _refresh() -> void:
	if _list == null:
		return
	for child in _list.get_children():
		child.queue_free()
	var hub: Dictionary = WorldMapManager.get_hub_data(hub_id)
	var pool: Array = hub.get("npc_pool", [])
	for npc_id_value in pool.slice(0, mini(5, pool.size())):
		_list.add_child(_make_npc_row(str(npc_id_value)))
	if pool.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Nenhum contato visível agora."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_list.add_child(empty_label)


func _make_npc_row(raw_npc_id: String) -> Control:
	var canonical_id: String = str(CHARACTER_ALIASES.get(raw_npc_id, raw_npc_id))
	var character: Dictionary = DataRegistry.get_character(canonical_id)
	var routine: Dictionary = WorldDirectorManager.npc_states.get(raw_npc_id, {})
	if routine.is_empty():
		routine = WorldDirectorManager.npc_states.get(canonical_id, {})
	var available: bool = bool(routine.get("available", true))
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0.0, 54.0)
	row.add_theme_constant_override("separation", 8)
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(48.0, 48.0)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.modulate = Color.WHITE if available else Color(0.55, 0.58, 0.62, 0.72)
	var portrait_path: String = str(PORTRAIT_PATHS.get(canonical_id, ""))
	if not portrait_path.is_empty() and ResourceLoader.exists(portrait_path):
		var portrait_resource: Resource = load(portrait_path)
		if portrait_resource is Texture2D:
			portrait.texture = portrait_resource as Texture2D
	row.add_child(portrait)
	var text_stack := VBoxContainer.new()
	text_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_stack.add_theme_constant_override("separation", 1)
	var name_label := Label.new()
	name_label.text = str(character.get("name", _humanize(raw_npc_id)))
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.add_theme_color_override("font_color", VisualTheme.OFF_WHITE if available else Color("858b94"))
	name_label.add_theme_font_size_override("font_size", 13)
	text_stack.add_child(name_label)
	var state_label := Label.new()
	var activity: String = str(routine.get("activity", "circulando_no_territorio"))
	state_label.text = ("DISPONÍVEL • " if available else "OCUPADO • ") + _humanize(activity)
	state_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	state_label.add_theme_color_override("font_color", VisualTheme.CYAN if available else Color("a66a6a"))
	state_label.add_theme_font_size_override("font_size", 10)
	text_stack.add_child(state_label)
	row.add_child(text_stack)
	return row


func _humanize(value: String) -> String:
	return value.replace("_", " ").capitalize()


func _on_routine_changed(_npc_id, _routine) -> void:
	_refresh()


func _on_day_advanced(_day, _week) -> void:
	_refresh()
