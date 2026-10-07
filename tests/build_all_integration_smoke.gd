extends SceneTree

var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures.append(label)

func _run() -> void:
	await process_frame
	var world = root.get_node("WorldState")
	var manager = root.get_node("CriaLiveInteractionManager")
	var save = root.get_node("SaveManager")
	world.reset_new_game()
	var service = load("res://src/social/CriaLiveService.gd").new()
	check(service is RefCounted and not service is Node, "social service has no scene lifecycle")
	var atlas = load("res://src/world/MapAtlasPresenter.gd").new()
	atlas.load_defs()
	check(atlas.moon_index(0, 4) == 4, "moon phase is deterministic")
	check(not atlas.node_unlocked({"lock": {"tipo": "unknown"}}), "unknown visual lock fails closed")
	check(not atlas._compound_ok(["unknown_requirement"]), "unknown compound lock fails closed")
	var map_scene = load("res://scenes/world/WorldMapScreen.tscn").instantiate()
	root.add_child(map_scene)
	await process_frame
	var layer = map_scene.get_node("WorldMapLifeLayer")
	check(layer.open_page("02"), "Itubera page opens")
	var snapshot: Dictionary = layer.get_atlas_snapshot()
	check(snapshot.get("page") == "02", "map consumes atlas presenter")
	check(snapshot.get("nodes", []).size() > 0, "atlas nodes reach map")
	check(not snapshot.get("shipping", true), "atlas is not promoted by integration")
	check(map_scene.get_node("HUD/LeftPanel/Status").text.contains(str(snapshot["moon"]["label"])), "moon reaches visible status")
	map_scene.queue_free()
	await process_frame
	var state: Dictionary = manager.get_v1_state()
	state["profile"]["followers"] = 600
	manager.v1_state = state
	world.modify_reputation("hype", 40.0)
	var posted: Dictionary = manager.publish_v1_post({"type": "treino", "tone": "humilde", "caption": "Base e paciencia.", "clip_quality": 0.9})
	check(posted.get("ok", false), "existing manager publishes through service")
	var signed: Dictionary = manager.sign_v1_sponsor("academia_suplementos", 3)
	check(signed.get("ok", false), "eligible sponsor can be signed")
	var before_money: int = world.money
	var before_hype: float = world.get_reputation("hype")
	manager._on_week_completed(world.week)
	check(world.money == before_money + 40, "payout mutates canonical money once")
	check(is_equal_approx(world.get_reputation("hype"), before_hype * 0.9), "weekly decay reaches canonical reputation")
	manager._on_week_completed(world.week)
	check(world.money == before_money + 40, "duplicate weekly event cannot double-pay")
	var before_save: Dictionary = manager.get_v1_state()
	check(save.save_game(97), "social integration saves")
	manager.reset()
	check(save.load_game(97), "social integration reloads")
	# JSON roundtrip converts numeric Variant types; compare serialized values.
	check(JSON.stringify(manager.get_v1_state()) == JSON.stringify(before_save), "social state survives save/reload")
	check(world.money == before_money + 40, "money survives save/reload")
	manager._on_week_completed(world.week)
	check(world.money == before_money + 40, "reload cannot duplicate sponsor payout")
	if failures.is_empty():
		print("BUILD_ALL_INTEGRATION_SMOKE PASS checks=%d" % checks)
		quit(0)
	else:
		for label in failures:
			push_error("BUILD_ALL_INTEGRATION_SMOKE: " + label)
		quit(1)
