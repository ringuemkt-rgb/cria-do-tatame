extends SceneTree

## Programmatic UI-and-arena smoke: no human screenshot or Android device claim.
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("[UniversalExhibitionScene] " + message)

func _select_id(picker: OptionButton, fighter_id: String) -> bool:
	for index in range(picker.item_count):
		if str(picker.get_item_metadata(index)) == fighter_id:
			picker.select(index)
			return true
	return false

func _run() -> void:
	await process_frame
	var menu_scene: PackedScene = load("res://scenes/combat/ExhibitionSelection.tscn")
	_check(menu_scene != null, "scene resource loads")
	if menu_scene == null:
		_report()
		return
	var menu = menu_scene.instantiate()
	root.add_child(menu)
	await process_frame
	_check(menu.player_select != null and menu.opponent_select != null, "dynamic roster selects created")
	_check(menu.player_select.item_count == 17, "all 17 fighters accessible to player control")
	_check(menu.opponent_select.item_count == 17, "all 17 fighters accessible as AI opponents")
	_check(_select_id(menu.player_select, "leoa"), "Leoa selectable")
	_check(_select_id(menu.opponent_select, "leoa"), "Leoa selectable as opponent")
	menu._on_start()
	_check(menu.status.text.contains("same_fighter"), "selection prevents same fighter")
	_check(root.get_node("CombatManager").get_pending_exhibition_match().is_empty(), "invalid pair creates no pending fight")
	_check(_select_id(menu.opponent_select, "jacare_do_mangue"), "Jacare selectable as opponent")
	menu._on_start()
	await process_frame
	await process_frame
	var arena = current_scene
	_check(arena != null, "selected fight changed to real arena scene")
	if arena != null:
		var cm = root.get_node("CombatManager")
		_check(bool(cm.is_running), "existing CombatManager owns active fight")
		_check(bool(cm.is_exhibition), "active fight is isolated exhibition")
		_check(str(cm.player_id) == "leoa" and str(cm.opponent_id) == "jacare_do_mangue", "arena launched actual selected IDs")
		_check(arena.pair_timeline != null and arena.pair_timeline.is_ready(), "paired motion bound to selected fighters")
		_check(str(arena.ruan_placeholder.fighter_id) == "leoa", "player visual is selected Leoa")
		_check(str(arena.davi_placeholder.fighter_id) == "jacare_do_mangue", "opponent visual is selected Jacare")
		_check(arena.get_node("Panel/Title").text.contains("LEOA") or arena.get_node("Panel/Title").text.contains("LEOA".capitalize()), "title reflects selected pair")
		_check(arena.get_node("Panel/Title").text.contains("JACARÉ"), "title reflects opponent identity")
		var hud = arena.get_node("CombatHUD")
		_check(hud.get_node("TopBar/PlayerName").text.contains("LEOA"), "combat HUD names selected player")
		_check(hud.get_node("TopBar/OpponentName").text.contains("JACARÉ"), "combat HUD names selected opponent")
		hud._on_resources_changed("leoa", {"health": 100, "gas": 23, "guard": 100, "focus": 60, "moral": 55})
		var selected_gas: ProgressBar = hud.get_node("TopBar/PlayerPanel/PlayerGas")
		_check(is_equal_approx(selected_gas.value, 23.0), "player resource bar follows selected fighter ID")
		cm.is_running = false
		arena.queue_free()
	menu.queue_free()
	await process_frame
	_report()

func _report() -> void:
	if failures.is_empty():
		print("[UniversalExhibitionScene] PASS checks=%d" % checks)
		quit(0)
	else:
		print("[UniversalExhibitionScene] FAIL checks=%d failures=%d" % [checks, failures.size()])
		quit(1)
