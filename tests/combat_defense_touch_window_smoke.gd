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

	# The real HUD must keep six selectable cards at mobile landscape and
	# switch to a 3x2 grid on portrait without changing card IDs or signals.
	var panel := hud.get_node("Panel") as Panel
	var grid := hud.get_node("Panel/Layout/Cards") as GridContainer
	_check(grid != null, "combat cards use a responsive GridContainer")
	if grid == null:
		bus.disconnect("combat_v2_defense_selected", on_choice)
		hud.queue_free()
		_finish()
		return
	hud.call("_apply_responsive_layout_for_size", Vector2(360, 800))
	_check(grid.columns == 3, "portrait phone uses three columns and two rows")
	_check(is_equal_approx(panel.anchor_left, 0.02) and is_equal_approx(panel.anchor_right, 0.98), "portrait HUD uses wide safe horizontal anchors")
	_check(is_equal_approx(panel.offset_bottom, -12.0) and panel.offset_top <= -200.0, "portrait HUD keeps a bottom inset and two-row height")
	for slot in range(1, 7):
		var target := hud.get_node("Panel/Layout/Cards/Card%d" % slot) as Button
		_check(target.custom_minimum_size.x >= 48.0 and target.custom_minimum_size.y >= 68.0, "slot %d has minimum mobile touch target" % slot)
		_check(target.clip_text, "slot %d clips oversized technique labels" % slot)
	hud.call("_apply_responsive_layout_for_size", Vector2(640, 360))
	_check(grid.columns == 3, "small landscape viewport also uses two rows")
	hud.call("_apply_responsive_layout_for_size", Vector2(854, 480))
	_check(grid.columns == 6, "standard Android landscape shows all six cards in one row")
	_check(is_equal_approx(panel.offset_bottom, -12.0), "landscape HUD respects bottom inset")
	hud.call("_apply_responsive_layout_for_size", Vector2(1280, 720))
	_check(grid.columns == 6 and is_equal_approx(panel.anchor_left, 0.49), "desktop HUD restores original placement")

	# A legacy deck refresh must respect a locked turn and must not replace
	# the V2 technique hand once combat switches modes.
	var legacy_card: Dictionary = {"id": "legacy_card_qa", "name": "Legacy QA", "activation_cost": {}, "level": 1}
	var legacy_button := hud.get_node("Panel/Layout/Cards/Card1") as Button
	hud.call("_on_hand_changed", [legacy_card], "")
	_check(not legacy_button.disabled, "legacy card is usable on an unlocked turn")
	hud.call("set_actions_enabled", false)
	hud.call("_on_hand_changed", [legacy_card], "")
	_check(legacy_button.disabled, "legacy hand refresh cannot visually unlock the AI turn")
	hud.call("set_actions_enabled", true)
	hud.call("_on_hand_changed", [legacy_card], "")
	_check(not legacy_button.disabled, "legacy hand is restored when the turn unlocks")
	# V2 card labels expose canonical costs without changing the authoritative
	# CombatManager affordability gate or the selected technique ID.
	var cost_label: String = str(hud.call("_format_v2_card_label", "tech_qa", {
		"nome": "Passagem de guarda", "cost": {"gas": 12, "focus": 3, "moral": 1}
	}))
	_check(cost_label == "Passagem de guarda\nG12 F3 M1", "V2 card displays gas, focus and moral costs")
	_check(str(hud.call("_format_v2_card_label", "tech_qa", {"name": "Raspagem", "custo": {"gas": 5, "foco": 2}})) == "Raspagem\nG5 F2", "legacy cost aliases are shown without changing technique IDs")
	_check(str(hud.call("_format_v2_card_label", "tech_qa", {"name": "Movimento"})) == "Movimento", "zero-cost card does not display invented costs")
	_check(str(hud.call("_format_v2_card_label", "tech_qa", {"name": "Registro nulo", "cost": null})) == "Registro nulo", "null cost payload cannot crash combat HUD")
	_check(str(hud.call("_format_v2_card_label", "tech_qa", {"name": "Registro legado", "cost": "invalid", "gas_cost": 4})) == "Registro legado\nG4", "malformed cost payload uses known legacy field without inventing rules")
	_check(str(hud.call("_format_v2_card_label", "tech_qa", {"name": "Registro vazio", "cost": []})) == "Registro vazio", "array cost payload cannot crash combat HUD")
	_check(str(hud.call("_format_v2_card_label", "tech_qa", {"name": "Custo textual", "cost": {"gas": "12", "focus": "invalid"}})) == "Custo textual", "textual cost values cannot be advertised as numeric")
	_check(str(hud.call("_format_v2_card_label", "tech_qa", {"name": "Custo negativo", "cost": {"gas": -5, "focus": 3}})) == "Custo negativo\\nF3".replace("\\n", "\n"), "negative costs are hidden without suppressing valid focus")
	_check(str(hud.call("_format_v2_card_label", "tech_qa", {"name": "Custo infinito", "cost": {"gas": INF, "focus": NAN, "moral": 2}})) == "Custo infinito\\nM2".replace("\\n", "\n"), "nonfinite costs cannot appear in combat HUD")
	hud.call("_on_v2_hand_changed", ["v2_technique_qa"])
	_check(str(legacy_button.get_meta("card_id", "")) == "v2_technique_qa", "V2 technique binds to HUD")
	hud.call("_on_hand_changed", [legacy_card], "")
	_check(str(legacy_button.get_meta("card_id", "")) == "v2_technique_qa", "late legacy hand cannot replace V2 technique")
	_check(hud.get("v2_hand") == ["v2_technique_qa"], "V2 hand remains authoritative")

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
	hud.call("set_defense_window_remaining", 0.5)
	_check(str(hud.get_node("Panel/Layout/Header/Clash").text) == "DEFESA ENVIADA", "submitted feedback survives countdown update")
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

	# The V2 hand exposes six buttons; keyboard actions 4-6 must be bound
	# and use the same guarded path as native touch, including defense locks.
	for slot in range(4, 7):
		var action := StringName("deck_card_%d" % slot)
		_check(InputMap.has_action(action), "shortcut for card %d registered" % slot)
		var bound := false
		for input_event in InputMap.action_get_events(action):
			if input_event is InputEventKey and input_event.physical_keycode == KEY_1 + slot - 1:
				bound = true
		_check(bound, "card %d has physical number-key binding" % slot)
		var six_options: Array = []
		for option_slot in range(1, 7):
			six_options.append({"id": "defense_slot_%d" % option_slot, "name": "Base"})
		hud.call("open_defense_window", six_options, 1.0)
		var before := selected.size()
		var shortcut := InputEventAction.new()
		shortcut.action = action
		shortcut.pressed = true
		hud.call("_unhandled_input", shortcut)
		_check(selected.size() == before + 1 and selected[-1] == "defense_slot_%d" % slot, "slot %d selects the matching defense" % slot)
		hud.call("_unhandled_input", shortcut)
		_check(selected.size() == before + 1, "slot %d cannot submit twice in one reaction" % slot)
		hud.call("close_defense_window")

	# Empty and disabled slots must never become actions through shortcuts.
	hud.call("open_defense_window", [{"id": "only_one", "name": "Frame"}], 1.0)
	var before_invalid := selected.size()
	var missing_shortcut := InputEventAction.new()
	missing_shortcut.action = "deck_card_6"
	missing_shortcut.pressed = true
	hud.call("_unhandled_input", missing_shortcut)
	_check(selected.size() == before_invalid, "unavailable sixth defense shortcut is ignored")
	hud.call("close_defense_window")

	# At the reported deadline the HUD must not allow a stale touch or
	# keyboard input. The arena independently validates the same deadline.
	var before_expiry := selected.size()
	hud.call("open_defense_window", [{"id": "expired_at_open", "name": "Frame"}], 0.0)
	_check(first.disabled and bool(hud.get("_defense_choice_submitted")), "zero-duration reaction is locked immediately")
	_check(str(hud.get_node("Panel/Layout/Header/Clash").text) == "JANELA ENCERRADA", "expired reaction has explicit feedback")
	first.pressed.emit()
	var expired_key := InputEventAction.new()
	expired_key.action = "deck_card_1"
	expired_key.pressed = true
	hud.call("_unhandled_input", expired_key)
	_check(selected.size() == before_expiry, "expired-at-open touch and keyboard cannot submit a defense")
	hud.call("close_defense_window")

	hud.call("open_defense_window", [{"id": "expired_on_tick", "name": "Base"}], 0.4)
	_check(not first.disabled, "fresh reaction opens a valid touch target")
	hud.call("set_defense_window_remaining", 0.0)
	_check(first.disabled and bool(hud.get("_defense_choice_submitted")), "countdown expiration locks defense controls")
	_check(str(hud.get_node("Panel/Layout/Header/Clash").text) == "JANELA ENCERRADA", "countdown expiration is announced")
	hud.call("set_defense_window_remaining", 0.2)
	_check(first.disabled, "late positive countdown update cannot reopen expired window")
	first.pressed.emit()
	hud.call("_unhandled_input", expired_key)
	_check(selected.size() == before_expiry, "expired countdown rejects both input paths")
	hud.call("close_defense_window")

	hud.call("open_defense_window", [{"id": "fresh_after_timeout", "name": "Frame"}], 0.5)
	_check(not first.disabled and not bool(hud.get("_defense_choice_submitted")), "new AI attack resets expired HUD state")
	first.pressed.emit()
	_check(selected.size() == before_expiry + 1 and selected[-1] == "fresh_after_timeout", "new reaction accepts exactly one defense")
	hud.call("set_defense_window_remaining", 0.0)
	_check(str(hud.get_node("Panel/Layout/Header/Clash").text) == "DEFESA ENVIADA", "timeout update does not erase submitted feedback")
	hud.call("close_defense_window")

	# The arena is the final consumer of the shared defense signal. A stale or
	# synthetic SignalBus event must not commit a choice absent from this attack.
	# Instantiate without adding to the tree: no combat start, save or scene swap.
	var arena_script := load("res://scenes/combat/CombatArenaBase.gd") as Script
	_check(arena_script != null, "combat arena script loads for defense signal guard")
	var combat_manager: Node = root.get_node_or_null("CombatManager")
	_check(combat_manager != null, "canonical CombatManager autoload exists for arena signal guard")
	if arena_script != null and combat_manager != null:
		var arena := arena_script.new() as Control
		var previous_running: bool = bool(combat_manager.get("is_running"))
		combat_manager.set("is_running", true)
		arena.set("_defense_window_open", true)
		arena.set("_defense_elapsed", 0.2)
		arena.call("_configure_defense_options", [
			{"id": "defense_allowed", "name": "Frame"},
			{"id": "", "name": "Empty"},
			"malformed_option"
		], 1.0)
		var allowed: Dictionary = arena.get("_defense_allowed_ids")
		_check(allowed.size() == 1 and allowed.has("defense_allowed"), "arena accepts only nonempty dictionary option IDs")
		arena.call("_on_v2_defense_selected", "forged_option")
		_check(str(arena.get("_selected_defense")) == "" and bool(arena.get("_defense_window_open")), "forged defense signal is rejected without closing reaction")
		arena.call("_on_v2_defense_selected", "")
		_check(str(arena.get("_selected_defense")) == "", "empty defense signal is rejected")
		arena.set("_defense_elapsed", 1.0)
		arena.call("_on_v2_defense_selected", "defense_allowed")
		_check(str(arena.get("_selected_defense")) == "" and bool(arena.get("_defense_window_open")), "expired defense signal cannot commit")
		arena.set("_defense_elapsed", 0.2)
		arena.call("_on_v2_defense_selected", "defense_allowed")
		_check(str(arena.get("_selected_defense")) == "defense_allowed" and not bool(arena.get("_defense_window_open")), "offered defense commits once before deadline")
		arena.call("_on_v2_defense_selected", "forged_option")
		_check(str(arena.get("_selected_defense")) == "defense_allowed", "late second signal cannot replace accepted defense")
		arena.set("_selected_defense", "")
		arena.set("_defense_window_open", true)
		combat_manager.set("is_running", false)
		arena.call("_on_v2_defense_selected", "defense_allowed")
		_check(str(arena.get("_selected_defense")) == "", "finished combat rejects a valid-looking defense signal")
		combat_manager.set("is_running", previous_running)
		arena.free()
	bus.disconnect("combat_v2_defense_selected", on_choice)
	hud.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	print("[DefenseTouch] checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
