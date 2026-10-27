extends SceneTree

# Regression for duplicate Android travel taps. No real save is written.
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("[TravelUI] " + message)

func _run() -> void:
	await process_frame
	var scene: PackedScene = load("res://scenes/world/WorldMapScreen.tscn")
	var stub: Script = load("res://tests/helpers/WorldMapTravelScreenStub.gd")
	_check(scene != null and stub != null, "real atlas scene and test subclass load")
	if scene == null or stub == null:
		_finish()
		return
	var world_map: Node = root.get_node_or_null("WorldMapManager")
	var world: Node = root.get_node_or_null("WorldState")
	var registry: Node = root.get_node_or_null("DataRegistry")
	_check(world_map != null and world != null and registry != null, "canonical world autoloads available")
	if world_map == null or world == null or registry == null:
		_finish()
		return
	var money_before := int(world.get("money"))
	var log_before := world_map.get("travel_log").size()
	var hub_before := str(world_map.get("current_hub"))
	var screen: Control = scene.instantiate()
	screen.set_script(stub)
	root.add_child(screen)
	await process_frame
	var zambi: Button = screen.get_node("HUD/RightPanel/Zambiapunga")
	var camamu: Button = screen.get_node("HUD/RightPanel/Camamu")
	var back: Button = screen.get_node("HUD/RightPanel/Back")
	var salvador: Button = screen.get_node("HUD/RightPanel/Salvador")

	# The map can inspect Salvador/Itacaré, but never route to them.
	screen.call("_on_travel_pressed", "salvador")
	screen.call("_on_travel_pressed", "itacare")
	_check(screen.get("travel_calls").is_empty(), "external locations never invoke travel authority")
	_check(not bool(screen.get("_travel_pending")), "external location does not lock controls")
	_check(salvador.disabled, "Salvador stays context-only")

	# A failed attempt must leave the player free to retry.
	zambi.pressed.emit()
	_check(screen.get("travel_calls").size() == 1, "failed trip invokes travel exactly once")
	_check(not bool(screen.get("_travel_pending")), "failed trip releases transaction guard")
	_check(not zambi.disabled and not camamu.disabled and not back.disabled, "failed trip restores buttons")
	_check(str(screen.get_node("HUD/LeftPanel/Message").text).contains("recusada"), "failed trip explains refusal")

	# A broken destination scene must be rejected before a charge or save.
	var original_registry: Dictionary = registry.get("hubs_dense").duplicate(true)
	var modified: Dictionary = original_registry.duplicate(true)
	var hubs: Dictionary = modified.get("hubs", {}).duplicate(true)
	var target: Dictionary = hubs.get("zambiapunga", {}).duplicate(true)
	target["entry_scene"] = "res://scenes/hubs/__nonexistent_travel_qa__.tscn"
	hubs["zambiapunga"] = target
	modified["hubs"] = hubs
	registry.set("hubs_dense", modified)
	zambi.pressed.emit()
	_check(screen.get("travel_calls").size() == 1, "missing destination scene is rejected before commit")
	_check(not bool(screen.get("_travel_pending")), "missing destination does not lock UI")
	_check(str(screen.get_node("HUD/LeftPanel/Message").text).contains("Nenhum valor debitado"), "missing destination gives safe feedback")
	registry.set("hubs_dense", original_registry)

	# The first successful tap owns the transition. All subsequent button
	# signals, including synthetic/double taps, must not request travel again.
	screen.set("should_succeed", true)
	zambi.pressed.emit()
	zambi.pressed.emit()
	camamu.pressed.emit()
	screen.call("_on_travel_pressed", "itubera")
	_check(screen.get("travel_calls").size() == 2, "rapid multi-destination taps commit only one trip")
	_check(str(screen.get("travel_calls")[-1]) == "zambiapunga", "first selected regional destination wins")
	_check(bool(screen.get("_travel_pending")), "successful trip holds transaction guard")
	_check(zambi.disabled and camamu.disabled and back.disabled, "travel and back buttons lock during transition")
	_check(salvador.disabled, "context-only Salvador remains disabled")
	_check(int(world.get("money")) == money_before, "test never charges currency")
	_check(world_map.get("travel_log").size() == log_before, "test never writes travel history")
	_check(str(world_map.get("current_hub")) == hub_before, "test never changes world location")

	# Destroy the screen before its delayed scene transition. The production
	# guard must not access a freed scene or navigate unexpectedly.
	screen.queue_free()
	await process_frame
	await create_timer(0.6).timeout
	_finish()

func _finish() -> void:
	print("[TravelUI] checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
