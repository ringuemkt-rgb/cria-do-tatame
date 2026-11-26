extends SceneTree

# A malformed defense option must never become a selectable touch/keyboard ID.
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("[DefenseIdTypes] " + message)

func _run() -> void:
	await process_frame
	var scene := load("res://scenes/ui/CombatDeckHUD.tscn") as PackedScene
	_check(scene != null, "HUD scene loads")
	if scene == null:
		_finish()
		return
	var hud := scene.instantiate()
	root.add_child(hud)
	await process_frame
	var bus := root.get_node_or_null("SignalBus")
	_check(bus != null, "canonical SignalBus exists")
	if bus == null:
		hud.queue_free()
		_finish()
		return
	var choices: Array[String] = []
	var listener: Callable = func(id): choices.append(str(id))
	bus.combat_v2_defense_selected.connect(listener)
	hud.call("set_actions_enabled", false)
	hud.call("open_defense_window", [
		{"id": null, "name": "Null"},
		{"id": 42, "name": "Number"},
		{"id": ["forged"], "name": "Array"},
		{"id": "   ", "name": "Whitespace"},
		{"id": "valid_frame", "name": "Frame"},
		{"id": {"nested": true}, "name": "Dictionary"}
	], 1.0)
	for slot in [1, 2, 3, 4, 6]:
		var button := hud.get_node("Panel/Layout/Cards/Card%d" % slot) as Button
		_check(button.disabled, "malformed slot %d disabled" % slot)
		_check(str(button.get_meta("card_id", "")) == "", "malformed slot %d has no action ID" % slot)
		button.pressed.emit()
		hud.call("_on_card_pressed", slot - 1)
		var shortcut := InputEventAction.new()
		shortcut.action = "deck_card_%d" % slot
		shortcut.pressed = true
		hud.call("_unhandled_input", shortcut)
	_check(choices.is_empty(), "malformed options cannot emit defense")
	var valid := hud.get_node("Panel/Layout/Cards/Card5") as Button
	_check(not valid.disabled and str(valid.get_meta("card_id", "")) == "valid_frame", "valid fifth slot retains its position")
	valid.pressed.emit()
	_check(choices == ["valid_frame"], "valid option emits exactly once")
	valid.pressed.emit()
	_check(choices.size() == 1, "double tap cannot submit twice")
	hud.call("close_defense_window")
	bus.combat_v2_defense_selected.disconnect(listener)
	hud.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	print("[DefenseIdTypes] checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
