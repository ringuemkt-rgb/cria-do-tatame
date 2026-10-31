extends SceneTree

const Rules = preload("res://src/progression/SkillTreeRulesV1.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("[SkillDeckSmoke] " + message)

func _run() -> void:
	await process_frame
	var world := root.get_node_or_null("WorldState")
	var deck := root.get_node_or_null("DeckManager")
	_check(world != null and deck != null, "existing WorldState and DeckManager autoloads")
	if world == null or deck == null:
		_finish()
		return
	var original_world: Dictionary = world.call("to_dict")
	var original_deck: Dictionary = deck.call("to_dict")
	var rules = Rules.new()
	_check(rules.is_valid(), "skill tree contract and full graph load")
	_check(rules.list_paths().size() == 5, "five canonical paths available")
	_check(rules.nodes.size() == 51, "51 canonical nodes available")
	world.call("reset_new_game")
	world.set("skill_points", 12)
	world.call("_sync_aliases")
	_check(not rules.evaluate("invented_skill", [], 10).get("ok", false), "unknown skill rejected")
	_check(str(rules.evaluate("controle_de_base", [], 12).get("error", "")) == "requires_previous", "skill cannot skip prerequisite")
	_check(str(rules.evaluate("postura_pesada", [], 0).get("error", "")) == "insufficient_skill_points", "skill cannot be purchased with zero points")
	var root_unlock: Dictionary = rules.purchase("postura_pesada", world, deck)
	_check(bool(root_unlock.get("ok", false)), "first path node spends one point")
	_check(int(world.get("skill_points")) == 11, "skill points are debited once")
	_check(world.get("unlocked_skills").has("postura_pesada"), "skill persisted in WorldState list")
	_check(str(rules.purchase("postura_pesada", world, deck).get("error", "")) == "already_unlocked", "double purchase rejected")
	_check(int(world.get("skill_points")) == 11, "duplicate cannot debit points")
	var next_result: Dictionary = rules.purchase("controle_de_base", world, deck)
	_check(bool(next_result.get("ok", false)), "next sequential skill purchasable")
	for id in ["controle_isolado", "quebra_de_postura_finalizacao", "caca_ao_pescoco", "ataque_de_braco"]:
		_check(bool(rules.purchase(id, world, deck).get("ok", false)), "finalization path progression: " + id)
	_check(bool(deck.get("cards")["card_mata_leao_01"].get("unlocked", false)), "skill unlocks Mata Leao through DeckManager")
	_check(bool(deck.get("cards")["card_chave_braco_01"].get("unlocked", false)), "skill unlocks Chave de Braco through DeckManager")
	_check(int(world.get("skill_points")) == 6, "two pressure and four finish skills spend six points")
	var deck_before: Array = deck.get("active_deck").duplicate()
	var denied: Dictionary = deck.call("equip_card", "card_chave_braco_01", "active")
	_check(str(denied.get("error", "")) == "deck_full", "tapping full deck cannot silently delete a slot")
	_check(deck.get("active_deck") == deck_before, "equip failure is transactionally immutable")
	var replace: Dictionary = deck.call("equip_card", "card_chave_braco_01", "active", 2)
	_check(bool(replace.get("ok", false)), "replace an occupied active card")
	_check(deck.get("active_deck").size() == 5, "replacing full deck preserves five slots")
	var replaced: Array = deck.get("active_deck").duplicate()
	var swap: Dictionary = deck.call("equip_card", str(replaced[0]), "active", 3)
	_check(bool(swap.get("ok", false)), "move/swapping a card within full deck")
	_check(deck.get("active_deck").size() == 5, "swap does not lose an equipped card")
	var before_invalid: Array = deck.get("active_deck").duplicate()
	_check(not bool(deck.call("equip_card", "card_mata_leao_01", "active", 999).get("ok", false)), "invalid slot rejected")
	_check(deck.get("active_deck") == before_invalid, "invalid slot cannot mutate deck")
	_check(bool(deck.call("unequip_card", "active", 0).get("ok", false)), "touch-screen removal operation available")
	_check(deck.get("active_deck").size() == 4, "unequip changes active count")
	while deck.get("active_deck").size() > 1:
		deck.call("unequip_card", "active", 0)
	_check(str(deck.call("unequip_card", "active", 0).get("error", "")) == "last_active_card", "last active card cannot be removed")
	var persisted: Dictionary = world.call("to_dict")
	var persisted_deck: Dictionary = deck.call("to_dict")
	world.call("reset_new_game")
	deck.call("configure_from_data", original_deck)
	world.call("load_from_dict", persisted)
	deck.call("load_from_dict", persisted_deck)
	_check(world.get("unlocked_skills").has("ataque_de_braco"), "skill unlock survives serialization")
	_check(deck.get("cards")["card_chave_braco_01"].get("unlocked", false), "unlocked technique survives serialization")
	_check(int(world.get("skill_points")) == 6, "remaining skill points survive serialization")
	for scene_path in ["res://scenes/ui/SkillTreeScreen.tscn", "res://scenes/ui/DeckBuilder.tscn", "res://scenes/hubs/TerreiroDaLuta.tscn"]:
		var packed: PackedScene = load(scene_path)
		_check(packed != null, "UI PackedScene loads " + scene_path)
		if packed != null:
			var instance := packed.instantiate()
			root.add_child(instance)
			await process_frame
			if scene_path.ends_with("SkillTreeScreen.tscn"):
				var ui: Control = instance as Control
				var tabs: TabContainer = ui.get("mobile_tabs") as TabContainer
				var desktop: HBoxContainer = ui.get("content_desktop") as HBoxContainer
				var top_mobile: VBoxContainer = ui.get("top_compact") as VBoxContainer
				var paths: PanelContainer = ui.get("path_panel") as PanelContainer
				var nodes: ScrollContainer = ui.get("node_scroll") as ScrollContainer
				var detail: PanelContainer = ui.get("detail_panel") as PanelContainer
				var back: Button = ui.get("back_button") as Button
				var unlock: Button = ui.get("unlock_btn") as Button
				_check(tabs != null and desktop != null and paths != null and nodes != null and detail != null, "skill tree responsive controls exist")
				for viewport in [Vector2(360, 800), Vector2(640, 360), Vector2(854, 480)]:
					ui.call("_apply_responsive_layout_for_size", viewport)
					_check(tabs.visible and not desktop.visible and top_mobile.visible, "skill tree mobile layout at %s" % viewport)
					_check(paths.get_parent() == tabs and nodes.get_parent() == tabs and detail.get_parent() == tabs, "same three panels move to mobile tabs at %s" % viewport)
					_check(tabs.get_tab_count() == 3 and tabs.get_tab_title(0) == "CAMINHOS" and tabs.get_tab_title(2) == "DETALHES", "mobile path, skill and detail tabs at %s" % viewport)
					_check(paths.custom_minimum_size.x == 0.0 and detail.custom_minimum_size.x == 0.0, "fixed desktop widths removed at %s" % viewport)
					_check(back.custom_minimum_size.y >= 48.0 and unlock.custom_minimum_size.y >= 48.0, "touch targets remain reachable at %s" % viewport)
					_check(nodes.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "node list scrolls vertically at %s" % viewport)
				var first_path: Dictionary = rules.list_paths()[0]
				ui.call("_choose_path", str(first_path["id"]))
				_check(tabs.current_tab == 1, "choosing a path opens skill nodes on mobile")
				var first_nodes: Array = rules.list_nodes(str(first_path["id"]))
				ui.call("_select_skill", str(first_nodes[0]["id"]))
				_check(tabs.current_tab == 2, "selecting a skill opens details and unlock action on mobile")
				ui.call("_apply_responsive_layout_for_size", Vector2(1280, 720))
				_check(desktop.visible and not tabs.visible and not top_mobile.visible, "desktop layout restored")
				_check(paths.get_parent() == desktop and nodes.get_parent() == desktop and detail.get_parent() == desktop, "same panels return to desktop without duplicates")
				_check(paths.custom_minimum_size.x == 202.0 and detail.custom_minimum_size.x == 320.0, "desktop panel widths restored")
			if scene_path.ends_with("TerreiroDaLuta.tscn"):
				_check(instance.has_node("Panel/ProgressionLinks/SkillsBtn"), "hub exposes skill tree")
				_check(instance.has_node("Panel/ProgressionLinks/MapBtn"), "hub exposes world atlas")
			instance.queue_free()
			await process_frame
	world.call("load_from_dict", original_world)
	deck.call("load_from_dict", original_deck)
	_finish()

func _finish() -> void:
	print("[SkillDeckSmoke] checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
