extends SceneTree

var failures: Array[String] = []
var checks := 0
var combat_manager: Node
var faction_director: Node
var cria_live_manager: Node
var training_manager: Node
var world_director: Node
var world_state: Node

func _initialize() -> void:
	call_deferred("_run")

func _assert(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("[Epic16VisualSmoke] " + message)

func _run() -> void:
	await process_frame
	var audio_manager := root.get_node_or_null("AudioManager")
	combat_manager = root.get_node_or_null("CombatManager")
	faction_director = root.get_node_or_null("FactionDirectorManager")
	cria_live_manager = root.get_node_or_null("CriaLiveManager")
	training_manager = root.get_node_or_null("TrainingManager")
	world_director = root.get_node_or_null("WorldDirectorManager")
	world_state = root.get_node_or_null("WorldState")
	if audio_manager != null:
		audio_manager.set("enabled", false)
	for required in [combat_manager, faction_director, cria_live_manager, training_manager, world_director, world_state]:
		_assert(required != null, "Autoload visual obrigatório ausente")
	if failures.size() > 0:
		_finish()
		return
	await _test_combat_hud_transition()
	await _test_territory_map_transition()
	await _test_cria_live_feed_transition()
	await _test_skill_tree_transition()
	await _test_time_and_tide_transition()
	_finish()

func _instantiate_scene(path: String) -> Node:
	var packed := load(path) as PackedScene
	_assert(packed != null, "Cena não carregou: %s" % path)
	if packed == null:
		return null
	var instance := packed.instantiate()
	root.add_child(instance)
	await process_frame
	return instance

func _test_combat_hud_transition() -> void:
	var combat_scene := await _instantiate_scene("res://scenes/combat/CombatArenaBase.tscn")
	if combat_scene == null:
		return
	var hud := combat_scene.get_node_or_null("CombatHUDv2")
	_assert(hud != null, "CombatArenaBase não consumiu CombatHUDv2")
	if hud != null:
		_assert(hud.get_node("StandPhaseHUD").visible, "HUD não iniciou na fase em pé")
		combat_manager.call("_apply_state_transition", "PLAYER_TOP_GUARD")
		_assert(hud.get_node("GroundPhaseHUD").visible, "Takedown não abriu a fase solo")
		_assert(str(hud.get_node("GroundPhaseHUD/GroundFrame/GroundLayout/PositionRow/PositionLabel").text) == "POR CIMA DA GUARDA", "Posição de solo não chegou ao HUD")
		combat_manager.call("_apply_state_transition", "PLAYER_STANDING_NEUTRAL")
		_assert(hud.get_node("StandPhaseHUD").visible, "Stand-up não restaurou a fase em pé")
	combat_scene.queue_free()
	await process_frame
	combat_manager.set("is_running", false)

func _test_territory_map_transition() -> void:
	faction_director.call("reset_director")
	var map_ui := await _instantiate_scene("res://scenes/world/world_map_ui.tscn")
	if map_ui == null:
		return
	var territory_before: Dictionary = faction_director.call("get_territory", "colonia_nishimura")
	var control_before := float(territory_before.get("control", 0.0))
	var button: Button = map_ui.get_node("MapPanel/MapCanvas/MapNodes/Itubera")
	var color_before: Color = (button.get_theme_stylebox("normal") as StyleBoxFlat).bg_color
	combat_manager.call("start_combat", "ferro_velho_da_lapa", "ruan_macacao", "davi_relampago", {
		"clandestine": true,
		"territory_id": "colonia_nishimura",
		"municipality_id": "itubera"
	})
	combat_manager.call("finish_combat", {"winner": "ruan_macacao", "loser": "davi_relampago", "method": "controle_posicional", "technical": true})
	await process_frame
	var territory_after: Dictionary = faction_director.call("get_territory", "colonia_nishimura")
	var color_after: Color = (button.get_theme_stylebox("normal") as StyleBoxFlat).bg_color
	_assert(is_equal_approx(float(territory_after.get("control", 0.0)), control_before - 10.0), "Vitória clandestina não reduziu 10 de controle territorial")
	_assert(str(map_ui.get("last_territory_id")) == "colonia_nishimura", "Mapa não recebeu territory_changed")
	_assert(str(map_ui.get("last_municipality_id")) == "itubera", "Território não foi roteado ao nó de Ituberá")
	_assert(color_before != color_after, "Cor do nó não reagiu à mudança territorial")
	var control_after_win := float(territory_after.get("control", 0.0))
	combat_manager.call("start_combat", "arena_do_dique", "ruan_macacao", "davi_relampago", {
		"clandestine": false,
		"territory_id": "colonia_nishimura",
		"municipality_id": "itubera"
	})
	combat_manager.call("finish_combat", {"winner": "ruan_macacao", "loser": "davi_relampago", "method": "pontos"})
	_assert(is_equal_approx(float(faction_director.call("get_territory", "colonia_nishimura").get("control", 0.0)), control_after_win), "Luta oficial alterou território clandestino")
	combat_manager.call("start_combat", "ferro_velho_da_lapa", "ruan_macacao", "davi_relampago", {
		"clandestine": true,
		"territory_id": "colonia_nishimura",
		"municipality_id": "itubera"
	})
	combat_manager.call("finish_combat", {"winner": "davi_relampago", "loser": "ruan_macacao", "method": "pontos"})
	_assert(is_equal_approx(float(faction_director.call("get_territory", "colonia_nishimura").get("control", 0.0)), control_after_win), "Derrota clandestina aplicou bônus de vitória")
	map_ui.queue_free()
	await process_frame

func _test_cria_live_feed_transition() -> void:
	var cria_live := await _instantiate_scene("res://scenes/social/crialive_v2.tscn")
	if cria_live == null:
		return
	var marker := "SMOKE EPIC 16.1 NO FEED"
	var post: Dictionary = cria_live_manager.call("create_post", marker, "treino", "tinker", {"source_event": "epic16_smoke"})
	await process_frame
	var rendered := str(cria_live.get_node("Columns/FeedPanel/Layout/Post1/Text").text)
	_assert(rendered.contains(marker), "post_published não atualizou o feed v2")
	_assert(str(cria_live.get("last_published_post_id")) == str(post.get("id", "")), "Feed v2 não registrou o post publicado")
	cria_live.queue_free()
	await process_frame

func _test_skill_tree_transition() -> void:
	training_manager.call("reset")
	world_state.call("reset_new_game")
	world_state.set("energy", 100.0)
	var skill_tree := await _instantiate_scene("res://scenes/hubs/skill_tree_v2.tscn")
	if skill_tree == null:
		return
	var tier_two: Button = skill_tree.get_node("TreeFrame/Branches/TecnicaBranch/Layout/TecnicaTier2")
	_assert(tier_two.disabled, "Tier II deveria iniciar bloqueado")
	var mastery: Dictionary = training_manager.get("mastery")
	mastery["grip_de_ferro"] = 99.0
	training_manager.set("mastery", mastery)
	var result: Dictionary = training_manager.call("run_technical_training", "grip_de_ferro", 1)
	await process_frame
	_assert(int(result.get("level", 0)) == 2, "Technique XP não alcançou nível II")
	_assert(not tier_two.disabled, "technique_leveled_up não desbloqueou o nó")
	_assert(str(tier_two.get_meta("unlocked_by_technique", "")) == "grip_de_ferro", "Nó desbloqueado perdeu a técnica de origem")
	skill_tree.queue_free()
	await process_frame

func _test_time_and_tide_transition() -> void:
	world_director.call("reset_world")
	var map_ui := await _instantiate_scene("res://scenes/world/world_map_ui.tscn")
	if map_ui == null:
		return
	world_director.call("advance_time_block")
	world_director.call("advance_time_block")
	await process_frame
	_assert(str(map_ui.get("last_time_block")) == "noite", "time_advanced não atualizou o mapa para noite")
	_assert(str(map_ui.get("last_tide_state")) != "", "tide_changed não atualizou o estado da maré")
	_assert(float(map_ui.get("last_tide_level")) > 0.0, "Nível visual da maré não foi atualizado")
	_assert(is_equal_approx(float(map_ui.get_node("TideOverlay/Layout/TideMeter").value), float(map_ui.get("last_tide_level")) * 100.0), "Medidor de maré divergiu do runtime")
	map_ui.queue_free()
	await process_frame

func _finish() -> void:
	if failures.is_empty():
		print("[Epic16VisualSmoke] OK - %d verificações" % checks)
		quit(0)
	else:
		print("[Epic16VisualSmoke] FALHOU - %d de %d verificações" % [failures.size(), checks])
		for failure in failures:
			print(" - " + failure)
		quit(1)
