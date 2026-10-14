extends SceneTree

var received := ""

func _init() -> void:
	call_deferred("_run")

func _receive(id) -> void:
	received = str(id)

func _run() -> void:
	await process_frame
	var hud = load("res://scenes/ui/CombatDeckHUD.tscn").instantiate()
	root.add_child(hud)
	await process_frame
	SignalBus.combat_v2_defense_selected.connect(_receive)
	hud.set_actions_enabled(false)
	hud.open_defense_window([{"id": "sprawl", "name": "Sprawl"}], 0.7)
	hud._on_card_pressed(0)
	var ok: bool = received == "sprawl"
	SignalBus.combat_v2_defense_selected.disconnect(_receive)
	hud.queue_free()
	print("[CombatHudDefenseTouch] PASS" if ok else "[CombatHudDefenseTouch] FAIL")
	quit(0 if ok else 1)
