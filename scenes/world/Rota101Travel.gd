extends Control
class_name Rota101Travel

const SimulationScript = preload("res://src/world/Rota101Simulation.gd")
const WORLD_MAP_SCENE := "res://scenes/world/WorldMapScreen.tscn"

@onready var route_label: Label = $HUD/Top/Route
@onready var speed_label: Label = $HUD/Top/Speed
@onready var vehicle_label: Label = $HUD/Top/Vehicle
@onready var condition_label: Label = $HUD/Top/Condition
@onready var progress_bar: ProgressBar = $HUD/Top/Progress
@onready var message_label: Label = $HUD/Message
@onready var result_panel: PanelContainer = $HUD/ResultPanel
@onready var result_label: Label = $HUD/ResultPanel/Margin/VBox/Result
@onready var continue_button: Button = $HUD/ResultPanel/Margin/VBox/Continue
@onready var pause_button: Button = $HUD/Controls/Pause
@onready var auto_accelerate: CheckButton = $HUD/Accessibility/AutoAccelerate
@onready var lane_assist: CheckButton = $HUD/Accessibility/LaneAssist
@onready var reduced_shake: CheckButton = $HUD/Accessibility/ReducedShake

var simulation = SimulationScript.new()
var plan: Dictionary = {}
var commit_result: Dictionary = {}
var _running := false
var _paused := false
var _committed := false
var _left_held := false
var _right_held := false
var _accelerate_held := false
var _brake_held := false
var _horn_pending := false
var _shake_time := 0.0

func _ready() -> void:
	_bind_controls()
	result_panel.visible = false
	auto_accelerate.button_pressed = false
	lane_assist.button_pressed = false
	reduced_shake.button_pressed = false
	plan = WorldMapManager.get_pending_travel_plan()
	if plan.is_empty():
		_fail_before_start("Nenhuma viagem preparada. Voltando ao mapa.")
		return
	if str(plan.get("mode", "")) != "rota_101" and str(plan.get("minigame", "")) != "rota_101":
		_fail_before_start("Esta rota não usa ROTA 101.")
		return
	var init_result: Dictionary = simulation.initialize(plan)
	if not bool(init_result.get("ok", false)):
		_fail_before_start("ROTA 101 indisponível: %s" % ", ".join(init_result.get("errors", [])))
		return
	_running = true
	route_label.text = "%s → %s" % [str(plan.get("origin_node", "ORIGEM")).replace("_", " ").to_upper(), str(plan.get("destination_node", "DESTINO")).replace("_", " ").to_upper()]
	vehicle_label.text = str(plan.get("vehicle_id", "kombi_terreiro")).replace("_", " ").to_upper()
	message_label.text = "Dirija limpo. Velocidade não dá bônus; chegar inteiro dá."
	_update_hud(simulation.get_snapshot())
	queue_redraw()

func _process(delta: float) -> void:
	if not _running or _paused:
		return
	var input_state := _read_input_state()
	var result: Dictionary = simulation.step(input_state, delta)
	_horn_pending = false
	_update_hud(result.get("snapshot", {}))
	if bool(result.get("finished", false)):
		_finish_route(result.get("outcome", {}))
	queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				_horn_pending = true
			KEY_P:
				_toggle_pause()

func _draw() -> void:
	var bounds := Rect2(Vector2.ZERO, size)
	draw_rect(bounds, Color("07131a"))
	var horizon_y := size.y * 0.28
	var bottom_y := size.y * 0.93
	_draw_sky_and_land(horizon_y, bottom_y)
	_draw_road(horizon_y, bottom_y)
	_draw_hazards(horizon_y, bottom_y)
	_draw_kombi(bottom_y)

func _draw_sky_and_land(horizon_y: float, bottom_y: float) -> void:
	draw_rect(Rect2(0.0, 0.0, size.x, horizon_y), Color("173743"))
	draw_circle(Vector2(size.x * 0.78, horizon_y * 0.34), 34.0, Color("d9b95e"))
	var ridge := PackedVector2Array([
		Vector2(0.0, horizon_y),
		Vector2(size.x * 0.14, horizon_y * 0.72),
		Vector2(size.x * 0.30, horizon_y * 0.91),
		Vector2(size.x * 0.47, horizon_y * 0.62),
		Vector2(size.x * 0.67, horizon_y * 0.88),
		Vector2(size.x * 0.84, horizon_y * 0.68),
		Vector2(size.x, horizon_y),
		Vector2(size.x, bottom_y),
		Vector2(0.0, bottom_y)
	])
	draw_colored_polygon(ridge, Color("173b2c"))

func _draw_road(horizon_y: float, bottom_y: float) -> void:
	var center := size.x * 0.5
	var top_half := size.x * 0.07
	var bottom_half := size.x * 0.37
	var shoulder := PackedVector2Array([
		Vector2(center - top_half - 18.0, horizon_y),
		Vector2(center + top_half + 18.0, horizon_y),
		Vector2(center + bottom_half + 42.0, bottom_y),
		Vector2(center - bottom_half - 42.0, bottom_y)
	])
	draw_colored_polygon(shoulder, Color("a78556"))
	var road := PackedVector2Array([
		Vector2(center - top_half, horizon_y),
		Vector2(center + top_half, horizon_y),
		Vector2(center + bottom_half, bottom_y),
		Vector2(center - bottom_half, bottom_y)
	])
	draw_colored_polygon(road, Color("292d30"))
	var snapshot := simulation.get_snapshot()
	var progress := float(snapshot.get("state", {}).get("progress", 0.0))
	for lane_sign in [-0.33, 0.33]:
		for index in range(14):
			var phase := fmod(float(index) / 14.0 + progress * 11.0, 1.0)
			var depth_a := phase
			var depth_b := minf(1.0, phase + 0.035 + phase * 0.035)
			var a := _road_point(lane_sign, depth_a, horizon_y, bottom_y, top_half, bottom_half)
			var b := _road_point(lane_sign, depth_b, horizon_y, bottom_y, top_half, bottom_half)
			draw_line(a, b, Color("eadb9a"), maxf(1.0, 1.0 + depth_a * 5.0))

func _draw_hazards(horizon_y: float, bottom_y: float) -> void:
	if simulation.state.is_empty():
		return
	var progress := float(simulation.state.get("progress", 0.0))
	var view_distance := 0.30
	var top_half := size.x * 0.07
	var bottom_half := size.x * 0.37
	for hazard_value in simulation.hazards:
		if typeof(hazard_value) != TYPE_DICTIONARY:
			continue
		var hazard: Dictionary = hazard_value
		if bool(hazard.get("handled", false)):
			continue
		var ahead := float(hazard.get("progress", 0.0)) - progress
		if ahead < 0.0 or ahead > view_distance:
			continue
		var depth := clampf(1.0 - ahead / view_distance, 0.0, 1.0)
		var lane := float(hazard.get("lane", 0.0))
		var point := _road_point(lane, pow(depth, 1.45), horizon_y, bottom_y, top_half, bottom_half)
		var radius := lerpf(4.0, 32.0, depth)
		var color := Color("d7b64c") if bool(hazard.get("poi", false)) else Color("c34d3f")
		draw_circle(point, radius, Color(0.03, 0.05, 0.05, 0.9))
		draw_arc(point, radius, 0.0, TAU, 20, color, maxf(2.0, radius * 0.13))
		if depth > 0.50:
			draw_string(ThemeDB.fallback_font, point + Vector2(radius + 6.0, 5.0), str(hazard.get("id", "evento")).get_slice("_", 0).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(12 + depth * 5.0), color)

func _draw_kombi(bottom_y: float) -> void:
	if simulation.state.is_empty():
		return
	var lateral := float(simulation.state.get("lateral", 0.0))
	var x := size.x * 0.5 + lateral * size.x * 0.27
	var y := bottom_y - 70.0
	var shake := Vector2.ZERO
	if not reduced_shake.button_pressed and _shake_time > 0.0:
		shake = Vector2(sin(_shake_time * 47.0), cos(_shake_time * 53.0)) * 2.5
	var body := Rect2(Vector2(x - 62.0, y - 38.0) + shake, Vector2(124.0, 72.0))
	draw_rect(body, Color("e8e3d6"))
	draw_rect(Rect2(body.position + Vector2(0.0, 34.0), Vector2(body.size.x, 38.0)), Color("2e6a80"))
	draw_rect(Rect2(body.position + Vector2(20.0, 9.0), Vector2(84.0, 24.0)), Color("183441"))
	draw_circle(body.position + Vector2(24.0, 72.0), 14.0, Color("101214"))
	draw_circle(body.position + Vector2(100.0, 72.0), 14.0, Color("101214"))
	draw_string(ThemeDB.fallback_font, body.position + Vector2(37.0, 61.0), "CRIA", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color("f2ead0"))

func _road_point(lane: float, depth: float, horizon_y: float, bottom_y: float, top_half: float, bottom_half: float) -> Vector2:
	var eased := clampf(depth, 0.0, 1.0)
	var y := lerpf(horizon_y, bottom_y, eased)
	var half_width := lerpf(top_half, bottom_half, eased)
	return Vector2(size.x * 0.5 + lane * half_width * 0.85, y)

func _read_input_state() -> Dictionary:
	var steer := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) or _left_held:
		steer -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) or _right_held:
		steer += 1.0
	var throttle := 1.0 if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) or _accelerate_held else 0.0
	var brake := 1.0 if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) or _brake_held else 0.0
	return {
		"steer": steer,
		"throttle": throttle,
		"brake": brake,
		"horn": _horn_pending,
		"auto_accelerate": auto_accelerate.button_pressed,
		"lane_assist": lane_assist.button_pressed
	}

func _update_hud(snapshot: Dictionary) -> void:
	var runtime_state: Dictionary = snapshot.get("state", {})
	var speed := float(runtime_state.get("speed_kmh", 0.0))
	var progress := clampf(float(runtime_state.get("progress", 0.0)), 0.0, 1.0)
	var condition_start := maxf(1.0, float(runtime_state.get("initial_condition", 100.0)))
	var condition := maxf(0.0, condition_start - float(runtime_state.get("condition_loss", 0.0)))
	speed_label.text = "%03d km/h" % int(round(speed))
	condition_label.text = "KOMBI %d%% • LIMPEZA %d" % [int(round(condition / condition_start * 100.0)), int(round(float(runtime_state.get("clean_score", 100.0))))]
	progress_bar.value = progress * 100.0
	_shake_time = float(runtime_state.get("elapsed_seconds", 0.0)) if int(runtime_state.get("collisions", 0)) > 0 else 0.0

func _finish_route(outcome: Dictionary) -> void:
	if _committed:
		return
	_running = false
	_committed = true
	commit_result = WorldMapManager.commit_travel_outcome(str(plan.get("plan_id", "")), outcome)
	result_panel.visible = true
	if bool(commit_result.get("ok", false)):
		var success := bool(commit_result.get("travel_success", false))
		var entry: Dictionary = commit_result.get("travel_entry", {})
		result_label.text = "%s\nCondução %d • Danos %d • Chegada %s" % [
			"CHEGAMOS" if success else "A KOMBI PAROU",
			int(round(float(outcome.get("clean_score", 0.0)))),
			int(outcome.get("hard_damage_delta", 0)),
			str(entry.get("arrival_condition", "steady")).to_upper()
		]
		message_label.text = "Resultado comprometido no mundo e salvo uma única vez."
	else:
		result_label.text = "ERRO DE COMMIT\n%s" % str(commit_result.get("error", "desconhecido"))
		message_label.text = "O mundo não foi avançado novamente."
	continue_button.grab_focus()

func _fail_before_start(message: String) -> void:
	_running = false
	message_label.text = message
	result_panel.visible = true
	result_label.text = "VIAGEM NÃO INICIADA"
	continue_button.grab_focus()

func _continue_after_result() -> void:
	if bool(commit_result.get("ok", false)) and bool(commit_result.get("travel_success", false)):
		var destination_hub := str(commit_result.get("travel_entry", {}).get("destination_hub", ""))
		if destination_hub != "":
			var hub: Dictionary = WorldMapManager.get_hub_data(destination_hub)
			var scene_path := str(hub.get("entry_scene", ""))
			if scene_path != "" and ResourceLoader.exists(scene_path):
				get_tree().change_scene_to_file(scene_path)
				return
	get_tree().change_scene_to_file(WORLD_MAP_SCENE)

func _toggle_pause() -> void:
	_paused = not _paused
	pause_button.text = "CONTINUAR" if _paused else "PAUSA"
	message_label.text = "PAUSADO" if _paused else "Dirija limpo. Velocidade não dá bônus; chegar inteiro dá."

func _bind_controls() -> void:
	_bind_hold_button($HUD/Controls/Left, func(value: bool): _left_held = value)
	_bind_hold_button($HUD/Controls/Right, func(value: bool): _right_held = value)
	_bind_hold_button($HUD/Controls/Accelerate, func(value: bool): _accelerate_held = value)
	_bind_hold_button($HUD/Controls/Brake, func(value: bool): _brake_held = value)
	$HUD/Controls/Horn.pressed.connect(func(): _horn_pending = true)
	pause_button.pressed.connect(_toggle_pause)
	continue_button.pressed.connect(_continue_after_result)

func _bind_hold_button(button: Button, setter: Callable) -> void:
	button.button_down.connect(func(): setter.call(true))
	button.button_up.connect(func(): setter.call(false))
