extends SceneTree

# The AI turn locks attacks, but must not lock the player's timed defense.
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("[DefenseTouch] " + message)

func _run() -> void:
	await process_frame
	var packed := load("res://scenes/ui/CombatDeckHUD.tscn") as PackedScene
	_check(packed != null, "CombatDeckHUD scene loads")
	if packed == null:
		_finish()
		return
	var hud: Node = packed.instantiate()
	root.add_child(hud)
	await process_frame
	var selected: Array[String] = []
	var bus: Node = root.get_node_or_null("SignalBus")
	_check(bus != null, "canonical SignalBus autoload exists")
	if bus == null:
		hud.queue_free()
		_finish()
		return
	var on_choice: Callable = func(id): selected.append(str(id))
	bus.connect("combat_v2_defense_selected", on_choice)

	hud.call("set_actions_enabled", false)
	hud.call("open_defense_window", [
		{"id": "defesa_frame_qa", "name": "Frame"},
		{"id": "", "name": "Invalid"},
		{"id": "defesa_base_qa", "name": "Base"},
		"malformed_option"
	], 1.15)
	var first := hud.get_node("Panel/Layout/Cards/Card1") as Button
	var second := hud.get_node("Panel/Layout/Cards/Card2") as Button
	var third := hud.get_node("Panel/Layout/Cards/Card3") as Button
	var fourth := hud.get_node("Panel/Layout/Cards/Card4") as Button
	_check(not first.disabled, "valid defense remains touch-enabled during AI lock")
	_check(second.disabled, "empty defense ID is disabled")
	_check(not third.disabled, "second valid defense available before selection")
	_check(fourth.disabled, "malformed defense option fails closed")
	_check(str(first.get_meta("card_id", "")) == "defesa_frame_qa", "defense ID bound to button")
	# A deck update must not replace reaction buttons before the window closes.
	hud.call("_on_hand_changed", [], "")
	_check(str(first.get_meta("card_id", "")) == "defesa_frame_qa", "defense survives ordinary hand refresh")
	first.pressed.emit()
	_check(selected.size() == 1 and selected[0] == "defesa_frame_qa", "first press emits one defense")
	_check(first.disabled and third.disabled, "all defense buttons lock after selection")
	first.pressed.emit()
	third.pressed.emit()
	hud.call("_on_card_pressed", 2)
	_check(selected.size() == 1, "queued double tap and second option cannot emit again")
	second.pressed.emit()
	_check(selected.size() == 1, "invalid option cannot emit a selection")
	hud.call("close_defense_window")
	first.pressed.emit()
	_check(selected.size() == 1, "closed defense window cannot emit another defense")
	# A distinct AI attack must be able to open a fresh reaction window.
	hud.call("open_defense_window", [{"id": "defesa_esquiva_qa", "name": "Esquiva"}], 0.9)
	_check(not first.disabled, "new defense window re-enables its valid option")
	first.pressed.emit()
	_check(selected.size() == 2 and selected[1] == "defesa_esquiva_qa", "new window emits exactly one new defense")
	hud.call("close_defense_window")
	bus.disconnect("combat_v2_defense_selected", on_choice)
	hud.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	print("[DefenseTouch] checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
