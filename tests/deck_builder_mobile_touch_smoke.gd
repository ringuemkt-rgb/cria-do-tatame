extends SceneTree

# Pure UI regression: never writes a save or changes the deck.
# Native Android touch, cutouts and scroll inertia still require physical QA.
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("[DeckMobileTouch] " + message)

func _run() -> void:
	await process_frame
	var deck: Node = root.get_node_or_null("DeckManager")
	_check(deck != null, "existing DeckManager authority")
	if deck == null:
		_finish()
		return
	var original: Dictionary = deck.call("to_dict")
	var packed: PackedScene = load("res://scenes/ui/DeckBuilder.tscn")
	_check(packed != null, "deck builder PackedScene loads")
	if packed == null:
		_finish()
		return
	var screen: Control = packed.instantiate() as Control
	root.add_child(screen)
	await process_frame
	var scroll: ScrollContainer = screen.get_node("Margin/Scroll") as ScrollContainer
	var body: BoxContainer = screen.get_node("Margin/Scroll/Layout/Body") as BoxContainer
	var collection: GridContainer = screen.get_node("Margin/Scroll/Layout/Body/CollectionPanel/Collection/Scroll/CollectionGrid") as GridContainer
	var active: GridContainer = screen.get_node("Margin/Scroll/Layout/Body/GiPanel/Gi/ActiveSlots") as GridContainer
	var passive: GridContainer = screen.get_node("Margin/Scroll/Layout/Body/GiPanel/Gi/PassiveSlots") as GridContainer
	var actions: GridContainer = screen.get_node("Margin/Scroll/Layout/Actions") as GridContainer
	var gi_panel: PanelContainer = screen.get_node("Margin/Scroll/Layout/Body/GiPanel") as PanelContainer
	_check(scroll != null and scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "entire deck can scroll vertically without horizontal clipping")
	_check(active.get_child_count() == 5 and passive.get_child_count() == 3, "all five active and three passive slots exist")
	for viewport in [Vector2(360, 800), Vector2(640, 360), Vector2(854, 480)]:
		screen.call("_apply_responsive_layout_for_size", viewport)
		_check(body.orientation == BoxContainer.VERTICAL, "compact deck stacks collection and Gi at %s" % viewport)
		_check(collection.columns == 1 and active.columns == 3 and passive.columns == 3, "compact deck wraps cards and equipped slots at %s" % viewport)
		_check(actions.columns == 2 and gi_panel.custom_minimum_size.x == 0.0, "compact actions and Gi panel fit portrait widths at %s" % viewport)
		for slot in active.get_children():
			var slot_control: Control = slot as Control
			_check(slot_control != null and slot_control.custom_minimum_size.x >= 96.0, "active touch slot has compact minimum width")
		for button in actions.get_children():
			var action_button: Button = button as Button
			_check(action_button != null and action_button.custom_minimum_size.x >= 136.0 and action_button.custom_minimum_size.y >= 52.0, "action button retains mobile touch target")
	# Rebuild once in compact mode to verify actual slot and removal sizes.
	screen.call("_refresh_all")
	await process_frame # Flush queue_free from the prior layout before inspecting slots.
	for slot in active.get_children():
		var slot_control: Control = slot as Control
		_check(slot_control != null and slot_control.custom_minimum_size.y >= 100.0, "compact equipped slot has readable height")
		for child in slot.get_children():
			for button in child.get_children():
				if button is Button:
					var remove_button: Button = button as Button
					_check(remove_button.custom_minimum_size.y >= 48.0, "remove button has 48 px mobile touch target")
	screen.call("_apply_responsive_layout_for_size", Vector2(1280, 720))
	_check(body.orientation == BoxContainer.HORIZONTAL, "desktop keeps side-by-side deck panels")
	_check(collection.columns == 2 and active.columns == 5, "desktop restores two-column collection and five-card row")
	_check(actions.columns == 4 and gi_panel.custom_minimum_size.x == 720.0, "desktop restores four actions and Gi width")
	_check(deck.call("to_dict") == original, "layout and smoke do not mutate deck state")
	screen.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	print("[DeckMobileTouch] checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
