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
	var on_choice: Callable = func(id): selected.append(str(id))
	SignalBus.combat_v2_defense_selected.connect(on_choice)

	hud.call("set_actions_enabled", false)
	hud.call("open_defense_window", [
		{"id": "defesa_frame_qa", "name": "Frame"},
		{"id": "", "name": "Invalid"}
	], 1.15)
	var first := hud.get_node("Panel/Layout/Cards/Card1") as Button
	var second := hud.get_node("Panel/Layout/Cards/Card2") as Button
	_check(not first.disabled, "valid defense remains touch-enabled during AI lock")
	_check(second.disabled, "empty defense ID is disabled")
	_check(str(first.get_meta("card_id", "")) == "defesa_frame_qa", "defense ID bound to button")
	# A deck update must not replace reaction buttons before the window closes.
	hud.call("_on_hand_changed", [], "")
	_check(str(first.get_meta("card_id", "")) == "defesa_frame_qa", "defense survives ordinary hand refresh")
	first.pressed.emit()
	_check(selected.size() == 1 and selected[0] == "defesa_frame_qa", "touch press emits defense selection")
	second.pressed.emit()
	_check(selected.size() == 1, "disabled option cannot emit a selection")
	hud.call("close_defense_window")
	first.pressed.emit()
	_check(selected.size() == 1, "closed defense window cannot emit another defense")
	SignalBus.combat_v2_defense_selected.disconnect(on_choice)
	hud.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	print("[DefenseTouch] checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
