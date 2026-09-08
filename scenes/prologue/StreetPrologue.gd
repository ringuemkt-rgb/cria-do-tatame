extends Control
## Replayable origin prototype. Reads the narrative authority; never writes campaign state.
const MENU_SCENE := "res://scenes/main_menu/MainMenu.tscn"
const SOURCE := "res://data/narrative/acts_v3.json"

var stages: Array = []
var stage_index := 0
var deliveries := 0
var street_brl := 0
var stamina := 100.0
var cart := Vector2(40, 90)
var target_x := 750.0
var touch_direction := Vector2.ZERO
var training_step := 0
var choice_id := ""
var stage_done := false
var title_label: Label
var body_label: Label
var status_label: Label
var action_box: VBoxContainer
var field: Control
var cart_rect: ColorRect
var target_rect: ColorRect
var next_button: Button
var obstacles := [Rect2(230, 0, 70, 105), Rect2(480, 80, 70, 100)]

func _ready() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SOURCE))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("[StreetPrologue] Narrative data unavailable")
		return
	stages = parsed.get("prologue", {}).get("stages", [])
	var background := ColorRect.new()
	background.color = Color("0b0b0d")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var scroll := ScrollContainer.new()
	margin.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	scroll.add_child(column)
	title_label = _label(column, 28)
	body_label = _label(column, 22)
	status_label = _label(column, 20)
	field = Control.new()
	field.custom_minimum_size = Vector2(800, 180)
	column.add_child(field)
	for area in obstacles:
		var stall := ColorRect.new()
		stall.position = area.position
		stall.size = area.size
		stall.color = Color("785139")
		field.add_child(stall)
	cart_rect = ColorRect.new()
	cart_rect.size = Vector2(24, 24)
	cart_rect.color = Color("ede6d6")
	field.add_child(cart_rect)
	target_rect = ColorRect.new()
	target_rect.size = Vector2(30, 180)
	target_rect.color = Color("4a6741")
	field.add_child(target_rect)
	action_box = VBoxContainer.new()
	column.add_child(action_box)
	next_button = _button(column, "Continuar", _next_stage)
	_button(column, "Voltar ao menu", func(): get_tree().change_scene_to_file(MENU_SCENE))
	show_stage()

func _label(parent: Node, font_size: int) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("ede6d6"))
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 54
	button.add_theme_font_size_override("font_size", 22)
	parent.add_child(button)
	button.pressed.connect(callback)
	return button

func show_stage() -> void:
	for child in action_box.get_children():
		action_box.remove_child(child)
		child.queue_free()
	touch_direction = Vector2.ZERO
	if stage_index >= stages.size():
		title_label.text = "CRIA DO TATAME — O Carro de Mão"
		body_label.text = "Coro: O carro carregava compra. Agora carrega uma história.\nAnos depois, o Terreiro continua sendo casa."
		status_label.text = "Memória concluída. Seu save da campanha foi preservado."
		field.visible = false
		next_button.visible = false
		_button(action_box, "Rever a memória", restart)
		return
	var stage: Dictionary = stages[stage_index]
	title_label.text = "%s — %s" % [stage.id, stage.title]
	body_label.text = str(stage.text)
	status_label.text = ""
	field.visible = stage_index == 0
	next_button.visible = true
	stage_done = stage.get("mode", "") == "dialogue"
	next_button.disabled = not stage_done
	match str(stage.get("mode", "")):
		"delivery":
			body_label.text += "\nSetas ou botões: leve o carro branco até a faixa verde. As bancas marrons bloqueiam o caminho. Sem prazo neste protótipo."
			var row := HBoxContainer.new()
			action_box.add_child(row)
			for item in [["Esquerda", Vector2.LEFT], ["Cima", Vector2.UP], ["Baixo", Vector2.DOWN], ["Direita", Vector2.RIGHT]]:
				var direction: Vector2 = item[1]
				var button := _button(row, str(item[0]), func(): pass)
				button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				button.button_down.connect(func(): touch_direction = direction)
				button.button_up.connect(func(): touch_direction = Vector2.ZERO)
		"choice", "reading":
			for choice in stage.get("choices", []):
				_button(action_box, str(choice.label), select_choice.bind(str(choice.id)))
		"training":
			training_step = 0
			_button(action_box, str(stage.steps[0]), train_next)

func _process(delta: float) -> void:
	if stages.is_empty() or stage_index != 0 or field == null:
		return
	var direction := touch_direction
	if direction == Vector2.ZERO:
		direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	move_cart(direction, delta)
	cart_rect.position = cart - Vector2(12, 12)
	target_rect.position.x = target_x - 15
	status_label.text = "Entregas %d/3 • Rua R$%d • Gás %d/100" % [deliveries, street_brl, int(stamina)]
	next_button.disabled = not stage_done

func move_cart(direction: Vector2, delta: float) -> void:
	if stage_index != 0 or stage_done:
		return
	var dt := clampf(delta, 0.0, 0.05)
	if direction.length_squared() == 0:
		stamina = minf(100.0, stamina + 24 * dt)
		return
	var candidate := cart + direction.normalized() * (100.0 if stamina > 0 else 45.0) * dt
	candidate.x = clampf(candidate.x, 15, 785)
	candidate.y = clampf(candidate.y, 15, 165)
	for obstacle in obstacles:
		if obstacle.grow(12).has_point(candidate):
			return
	cart = candidate
	stamina = maxf(0.0, stamina - 5 * dt)
	if absf(cart.x - target_x) < 18:
		deliveries += 1
		street_brl += int(stages[0].get("reward_brl_per_delivery", 2))
		target_x = 40.0 if target_x > 400 else 750.0
		stage_done = deliveries >= 3

func select_choice(id: String) -> void:
	if stage_done or stage_index >= stages.size():
		return
	var stage: Dictionary = stages[stage_index]
	for choice in stage.get("choices", []):
		if str(choice.id) != id:
			continue
		choice_id = id
		if stage.mode == "reading":
			stage_done = bool(choice.get("correct", false))
			status_label.text = "Boa leitura. Controle abre caminhos." if stage_done else "O caminho segue fechado. Observe antes de insistir."
		else:
			stage_done = true
			status_label.text = str(choice.consequence)
		next_button.disabled = not stage_done
		return

func train_next() -> void:
	if stage_index >= stages.size() or str(stages[stage_index].get("mode", "")) != "training" or stage_done:
		return
	var steps: Array = stages[stage_index].steps
	training_step += 1
	stage_done = training_step >= steps.size()
	status_label.text = "Você solta a pegada. Joaquim confia em você." if stage_done else str(steps[training_step])
	var button := action_box.get_child(0) as Button
	button.text = "Roda concluída" if stage_done else str(steps[training_step])
	button.disabled = stage_done
	next_button.disabled = not stage_done

func _next_stage() -> void:
	if not stage_done:
		return
	stage_index += 1
	show_stage()

func restart() -> void:
	stage_index = 0
	deliveries = 0
	street_brl = 0
	stamina = 100.0
	cart = Vector2(40, 90)
	target_x = 750
	choice_id = ""
	show_stage()
