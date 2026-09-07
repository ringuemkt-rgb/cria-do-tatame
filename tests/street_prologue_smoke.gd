extends SceneTree

var failures := 0
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	await process_frame
	var world := root.get_node("WorldState")
	var before := JSON.stringify(world.to_dict())
	var scene = load("res://scenes/prologue/StreetPrologue.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	check(scene.stages.size() == 5, "Five origin stages load")
	scene._next_stage()
	check(scene.stage_index == 0, "Cannot skip unfinished deliveries")
	scene.cart = Vector2(215, 40)
	scene.move_cart(Vector2.RIGHT, 0.05)
	check(scene.cart.x == 215, "Stall collision blocks movement")
	for endpoint in [740.0, 50.0, 740.0]:
		scene.cart = Vector2(endpoint, 150)
		scene.move_cart(Vector2.RIGHT if endpoint > 400 else Vector2.LEFT, 0.05)
	check(scene.deliveries == 3 and scene.street_brl == 6, "Three deliveries pay six street reais")
	scene.move_cart(Vector2.RIGHT, 0.05)
	check(scene.street_brl == 6, "Completed delivery cannot repay")
	scene._next_stage()
	scene.select_choice("recuar")
	check(scene.stage_done, "Retreat resolves narrative consequence")
	scene._next_stage()
	check(scene.stage_index == 2 and scene.stage_done, "Dende intervention available")
	scene._next_stage()
	for i in range(5):
		scene.train_next()
	check(scene.stage_done, "Training sequence ends in respected tap")
	scene._next_stage()
	scene.select_choice("forcar")
	check(not scene.stage_done, "Reading rejects repeated force")
	scene.select_choice("ler")
	scene._next_stage()
	check(scene.stage_index == 5, "Memory reaches ending")
	scene.restart()
	check(scene.street_brl == 0 and scene.stage_index == 0, "Replay clears local rewards")
	check(JSON.stringify(world.to_dict()) == before, "Memory preserves campaign state")
	scene.queue_free()
	await process_frame
	print("STREET_PROLOGUE_SMOKE failures=", failures)
	quit(1 if failures else 0)
