extends SceneTree

const CombatSimulationEngineScript = preload("res://src/combat/CombatManager.gd")
const DaviAIControllerScript = preload("res://src/combat/DaviAIController.gd")
const TechniqueClashResolverScript = preload("res://src/combat/TechniqueClashResolver.gd")

const REQUIRED_SCENES := [
	"res://scenes/main_menu/MainMenu.tscn",
	"res://scenes/hubs/TerreiroDaLuta.tscn",
	"res://scenes/combat/CombatArenaBase.tscn",
	"res://scenes/result/ResultScreen.tscn",
	"res://scenes/ui/CriaLiveUI.tscn",
	"res://scenes/ui/DeckBuilder.tscn",
	"res://scenes/ui/CombatDeckHUD.tscn"
]

var failures: Array[String] = []
var checks: int = 0
var signal_bus: Node
var data_registry: Node
var deck_manager: Node
var local_ai_manager: Node
var world_state: Node
var save_manager: Node
var combat_manager: Node
var career_loop: Node
var game_flow_manager: Node
var audio_manager: Node
var cria_live_manager: Node

var _local_ai_expected_request_id: int = -1
var _local_ai_received: bool = false
var _local_ai_text: String = ""
var _local_ai_source: String = ""

func _initialize() -> void:
	call_deferred("_run")

func _assert(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("[RuntimeSmoke] " + message)

func _run() -> void:
	await process_frame
	_resolve_autoloads()
	if audio_manager != null:
		audio_manager.set("enabled", false)
	_test_autoloads()
	_test_data_registry()
	_test_combat_deck()
	await _test_local_ai_fallback()
	await _test_scene_loading()
	_test_save_roundtrip()
	_test_combat_domain()
	_test_opponent_ai_turn()
	_test_cria_live_single_post_contract()
	_test_campaign_progression()
	_finish()

func _resolve_autoloads() -> void:
	signal_bus = root.get_node_or_null("SignalBus")
	data_registry = root.get_node_or_null("DataRegistry")
	deck_manager = root.get_node_or_null("DeckManager")
	local_ai_manager = root.get_node_or_null("LocalAIManager")
	world_state = root.get_node_or_null("WorldState")
	save_manager = root.get_node_or_null("SaveManager")
	combat_manager = root.get_node_or_null("CombatManager")
	career_loop = root.get_node_or_null("CareerLoop")
	game_flow_manager = root.get_node_or_null("GameFlowManager")
	audio_manager = root.get_node_or_null("AudioManager")
	cria_live_manager = root.get_node_or_null("CriaLiveManager")

func _test_autoloads() -> void:
	var nodes: Dictionary = {
		"SignalBus": signal_bus,
		"DataRegistry": data_registry,
		"DeckManager": deck_manager,
		"LocalAIManager": local_ai_manager,
		"WorldState": world_state,
		"SaveManager": save_manager,
		"CombatManager": combat_manager,
		"CareerLoop": career_loop,
		"GameFlowManager": game_flow_manager,
		"AudioManager": audio_manager,
		"CriaLiveManager": cria_live_manager
	}
	for singleton_value in nodes.keys():
		var singleton_name: String = str(singleton_value)
		_assert(nodes[singleton_name] != null, "Autoload ausente: %s" % singleton_name)

func _test_data_registry() -> void:
	if data_registry == null:
		return
	var validation_report: Dictionary = data_registry.get("validation_report")
	_assert(bool(validation_report.get("ok", false)), "DataRegistry reportou erros: %s" % str(validation_report.get("errors", [])))
	var ruan: Dictionary = data_registry.call("get_character", "ruan_macacao")
	var arena: Dictionary = data_registry.call("get_arena", "terreiro_da_luta")
	var techniques: Dictionary = data_registry.get("techniques")
	var local_ai_config: Dictionary = data_registry.get("local_ai_config")
	var dialogue_fallbacks: Dictionary = data_registry.get("ai_dialogue_fallbacks")
	var animation_catalog: Dictionary = data_registry.get("character_animation_catalog")
	var arena_animation_flow: Dictionary = data_registry.get("arena_animation_flow")
	var combat_deck: Dictionary = data_registry.get("combat_deck")
	_assert(not ruan.is_empty(), "Ruan Macacao nao foi carregado")
	_assert(not arena.is_empty(), "Terreiro da Luta nao foi carregado")
	_assert(techniques.size() >= 10, "Catalogo principal possui menos de 10 tecnicas")
	_assert(not local_ai_config.is_empty(), "Configuracao da IA local nao foi carregada")
	_assert(not dialogue_fallbacks.is_empty(), "Dialogos offline de fallback nao foram carregados")
	_assert(animation_catalog.get("entries", []).size() >= 31, "Catalogo de animacoes nao foi carregado")
	_assert(arena_animation_flow.get("fight_flow", []).size() >= 10, "Fluxo animado das arenas nao foi carregado")
	_assert(combat_deck.get("cards", []).size() == 10, "Deck inicial nao possui 10 cartas")
	var ruan_idle: Dictionary = data_registry.call("get_character_animation", "ruan_macacao", "idle")
	_assert(not ruan_idle.is_empty(), "Animacao idle de Ruan nao foi registrada")
	_assert(ResourceLoader.exists("res://" + str(ruan_idle.get("manifest", "")).get_base_dir().path_join("sprite_sheet.png")), "Atlas idle de Ruan nao existe")
	for character_id in ["cassio_molho", "kenzo_kuroi", "leoa_quilombola", "oni_da_lapa"]:
		var rival_idle: Dictionary = data_registry.call("get_character_animation", character_id, "idle")
		_assert(not rival_idle.is_empty(), "Animacao idle ausente para %s" % character_id)
	_assert(not bool(local_ai_config.get("runtime_policy", {}).get("combat_llm_allowed", true)), "LLM foi permitido no combate por engano")
	_assert(bool(local_ai_config.get("runtime_policy", {}).get("fallback_required", false)), "Fallback offline nao esta marcado como obrigatorio")

func _test_combat_deck() -> void:
	if deck_manager == null or data_registry == null:
		return
	deck_manager.call("configure_from_data", data_registry.get("combat_deck"))
	var hand: Array = deck_manager.call("get_hand")
	_assert(hand.size() == 3, "Mao inicial do deck nao possui 3 cartas")
	var techniques: Dictionary = data_registry.get("techniques")
	for card_value in deck_manager.call("get_collection"):
		var card: Dictionary = card_value
		_assert(techniques.has(str(card.get("technique_id", ""))), "Carta referencia tecnica inexistente: %s" % str(card.get("id", "")))
		_assert(int(card.get("level", 0)) <= 2 or not bool(card.get("unlocked", false)), "Faixa branca equipou carta acima de Nv.2")
	var resolver: Node = TechniqueClashResolverScript.new()
	root.add_child(resolver)
	var clash: Dictionary = resolver.call(
		"resolve_clash",
		{"id": "attack", "level": 3, "base_power": 14},
		{"id": "defense", "level": 1, "base_power": 8},
		{"control": 70, "focus": 65, "grip": 70},
		{"guard": 45, "focus": 40, "control": 40},
		data_registry.call("get_technique", "chave_braco"),
		{"state": "PLAYER_TOP_MOUNT", "input_quality": 0.8, "defense_timing": 0.4}
	)
	_assert(bool(clash.get("enabled", false)), "Clash de cartas nao foi ativado")
	_assert(int(clash.get("level_gap", 0)) == 2, "Clash calculou diferenca de nivel incorreta")
	_assert(not bool(clash.get("instant_finish", true)), "Clash permitiu finalizacao automatica insegura")
	_assert(float(clash.get("chance_modifier", 1.0)) <= 0.35, "Clash excedeu teto de bonus")
	resolver.queue_free()

func _test_local_ai_fallback() -> void:
	if local_ai_manager == null:
		return
	_assert(not bool(local_ai_manager.call("is_network_backend_enabled")), "IA local iniciou com rede habilitada")
	var direct_fallback := str(local_ai_manager.call("get_fallback_dialogue", "mestre_dende", "treino", "smoke"))
	_assert(direct_fallback.length() > 10, "Fallback direto de Mestre Dende esta vazio")
	_local_ai_received = false
	_local_ai_text = ""
	_local_ai_source = ""
	if not local_ai_manager.dialogue_ready.is_connected(_on_local_ai_test_ready):
		local_ai_manager.dialogue_ready.connect(_on_local_ai_test_ready)
	_local_ai_expected_request_id = int(local_ai_manager.call(
		"request_dialogue",
		"mestre_dende",
		"Mestre, por que minha passagem falhou?",
		{"category": "treino", "location": "terreiro_da_luta"}
	))
	await process_frame
	_assert(_local_ai_received, "IA local desligada nao entregou fallback assíncrono")
	_assert(_local_ai_text.length() > 10, "Fallback assíncrono retornou texto vazio")
	_assert(_local_ai_source == "fallback_offline", "IA local desligada retornou fonte inesperada: %s" % _local_ai_source)
	if local_ai_manager.dialogue_ready.is_connected(_on_local_ai_test_ready):
		local_ai_manager.dialogue_ready.disconnect(_on_local_ai_test_ready)

func _on_local_ai_test_ready(request_id: int, npc_id: String, text: String, source: String) -> void:
	if request_id != _local_ai_expected_request_id or npc_id != "mestre_dende":
		return
	_local_ai_received = true
	_local_ai_text = text
	_local_ai_source = source

func _test_scene_loading() -> void:
	for scene_path in REQUIRED_SCENES:
		_assert(ResourceLoader.exists(scene_path), "Cena nao existe: %s" % scene_path)
		var resource: Resource = load(scene_path)
		_assert(resource is PackedScene, "Recurso nao e PackedScene: %s" % scene_path)
		if not (resource is PackedScene):
			continue
		var instance: Node = (resource as PackedScene).instantiate()
		_assert(instance != null, "Falha ao instanciar: %s" % scene_path)
		if instance == null:
			continue
		root.add_child(instance)
		await process_frame
		_assert(is_instance_valid(instance), "Instancia foi invalidada durante _ready: %s" % scene_path)
		instance.queue_free()
		await process_frame
	if combat_manager != null and bool(combat_manager.get("is_running")):
		combat_manager.set("is_running", false)
		var state_machine: Node = combat_manager.get("state_machine")
		if state_machine != null:
			state_machine.call("reset")

func _test_save_roundtrip() -> void:
	if save_manager == null or world_state == null:
		return
	const SLOT := 9876
	world_state.call("reset_new_game")
	world_state.set("money", 321)
	world_state.set("energy", 77.0)
	world_state.call("_sync_aliases")
	_assert(bool(save_manager.call("save_game", SLOT)), "SaveManager falhou ao salvar slot de teste")
	var slot_path: String = str(save_manager.call("get_slot_path", SLOT))
	_assert(not FileAccess.file_exists(slot_path + ".tmp"), "Save atomico deixou arquivo temporario")
	_assert(not FileAccess.file_exists(slot_path + ".bak"), "Save atomico deixou backup residual")
	world_state.set("money", 0)
	world_state.set("energy", 1.0)
	_assert(bool(save_manager.call("load_game", SLOT)), "SaveManager falhou ao carregar slot de teste")
	_assert(int(world_state.get("money")) == 321, "Roundtrip de save nao restaurou dinheiro")
	_assert(is_equal_approx(float(world_state.get("energy")), 77.0), "Roundtrip de save nao restaurou energia")
	save_manager.call("delete_save", SLOT)

func _test_combat_domain() -> void:
	if combat_manager == null:
		return
	var start_result: Dictionary = combat_manager.call("start_combat", "terreiro_da_luta", "ruan_macacao", "davi_relampago")
	_assert(bool(start_result.get("ok", false)), "CombatManager nao iniciou combate")
	_assert(str(combat_manager.call("get_current_state_name")) == "PLAYER_STANDING_NEUTRAL", "Combate nao iniciou em pe")
	var available: Array = combat_manager.call("get_available_techniques")
	_assert(not available.is_empty(), "Nenhuma tecnica disponivel no estado inicial")
	var missing: Dictionary = combat_manager.call("apply_player_action", "tecnica_inexistente")
	_assert(str(missing.get("error", "")) == "technique_not_found", "Tecnica inexistente nao retornou erro seguro")

	var engine: Node = CombatSimulationEngineScript.new()
	root.add_child(engine)
	engine.call(
		"setup",
		{"gas": 70, "focus": 60, "grip": 95, "guard": 100, "control": 55, "moral": 60},
		{"gas": 70, "focus": 50, "grip": 50, "guard": 50, "grip_integrity": 100, "control": 50, "moral": 50}
	)
	var technique: Dictionary = {
		"id": "smoke_grip",
		"entry_state": "distancia_media",
		"exit_state": "disputa_pegada",
		"base_chance": 0.9,
		"cost": {"gas": 2, "focus": 1},
		"effects": {"self_control_bonus": 5, "opponent_grip_reduction": 8}
	}
	var simulation: Dictionary = engine.call("use_technique", technique)
	_assert(not simulation.has("error"), "CombatSimulationEngine retornou erro")
	var resolver: Node = engine.get("technique_resolver")
	var normalized: Dictionary = resolver.call("_efeitos", technique, true)
	var applied: Dictionary = resolver.call(
		"aplicar_resultado",
		{"gas": 70, "focus": 60, "guard": 100, "control": 55, "moral": 60},
		{"gas": 70, "focus": 50, "guard": 50, "grip_integrity": 100, "control": 50},
		{"success": true, "cost": {"gas": 0, "focus": 0, "moral": 0}, "effects": normalized}
	)
	var defender: Dictionary = applied.get("defender", {})
	_assert(is_equal_approx(float(defender.get("grip_integrity", 100)), 92.0), "Reducao de grip foi aplicada com sinal incorreto")
	engine.queue_free()

	# Regressao P0: uma finalizacao bem-sucedida precisa encerrar antes do RESET.
	var state_machine: Node = combat_manager.get("state_machine")
	state_machine.call("forcar_estado", state_machine.call("estado_por_nome", "PLAYER_SUBMISSION_ATTACK"))
	var fighters: Dictionary = combat_manager.get("fighters")
	fighters["ruan_macacao"]["control"] = 100.0
	fighters["davi_relampago"]["health"] = 60.0
	combat_manager.set("fighters", fighters)
	var finisher: Dictionary = data_registry.call("get_technique", "encerramento_tecnico").duplicate(true)
	finisher["base_chance"] = 0.95
	finisher["chance_sucesso"] = 0.95
	_seed_runtime_resolver_for_success(0.95)
	combat_manager.call("execute_technique", "ruan_macacao", "davi_relampago", finisher)
	_assert(not bool(combat_manager.get("is_running")), "Finalizacao tecnica nao encerrou o combate")
	var final_result: Dictionary = world_state.get("last_combat_result")
	_assert(str(final_result.get("winner", "")) == "ruan_macacao", "Finalizacao nao registrou Ruan como vencedor")
	_assert(str(final_result.get("state_from", "")) == "PLAYER_SUBMISSION_ATTACK", "Finalizacao perdeu o estado de origem antes do encerramento")

func _test_opponent_ai_turn() -> void:
	if combat_manager == null or data_registry == null:
		return
	combat_manager.call("start_combat", "terreiro_da_luta", "ruan_macacao", "davi_relampago")
	_assert(str(combat_manager.call("get_actor_state_name", "davi_relampago")) == "PLAYER_STANDING_NEUTRAL", "Estado inicial do rival nao foi espelhado corretamente")
	var available: Array = combat_manager.call("get_available_techniques", "davi_relampago")
	_assert(not available.is_empty(), "Davi nao recebeu tecnicas disponiveis")

	var ai: Node = DaviAIControllerScript.new()
	root.add_child(ai)
	ai.call("setup", "davi_relampago", "normal")
	ai.call("record_player_action", "grip_de_ferro")
	ai.call("record_player_action", "grip_de_ferro")
	var chosen: Dictionary = ai.call("choose_technique", combat_manager)
	_assert(not chosen.is_empty(), "IA de Davi nao escolheu tecnica")
	_assert(bool(chosen.get("affordable", false)), "IA escolheu tecnica sem recursos")

	_seed_runtime_resolver_for_success(0.95)
	var result: Dictionary = combat_manager.call("apply_opponent_action", "grip_de_ferro")
	_assert(str(result.get("actor_id", "")) == "davi_relampago", "Acao rival foi atribuida ao ator errado")
	_assert(str(result.get("actor_state_from", "")) == "PLAYER_STANDING_NEUTRAL", "Resolver rival recebeu perspectiva posicional errada")
	if bool(result.get("success", false)):
		_assert(str(combat_manager.call("get_current_state_name")) == "PLAYER_BOTTOM_CLINCH", "Entrada de Davi nao virou clinch por baixo para Ruan")
		_assert(str(result.get("actor_state_to", "")) == "PLAYER_TOP_CLINCH", "Estado de saida do rival nao foi preservado na perspectiva do ator")
	ai.queue_free()
	combat_manager.set("is_running", false)
	combat_manager.get("state_machine").call("reset")

func _seed_runtime_resolver_for_success(chance: float) -> void:
	var runtime_resolver: Node = combat_manager.get("technique_resolver")
	var rng: RandomNumberGenerator = runtime_resolver.get("rng")
	var deterministic_seed := 0
	for seed_value in range(1000):
		rng.seed = seed_value
		if rng.randf() <= chance:
			deterministic_seed = seed_value
			break
	rng.seed = deterministic_seed

func _test_cria_live_single_post_contract() -> void:
	if signal_bus == null or cria_live_manager == null:
		return
	var before: int = cria_live_manager.call("get_feed").size()
	var result := {"winner": "ruan_macacao", "method": "smoke_duplicate_guard", "technical": true}
	signal_bus.combat_finished.emit(result)
	signal_bus.combat_ended.emit(result)
	var after: int = cria_live_manager.call("get_feed").size()
	_assert(after == before + 1, "Cria Live gerou mais de uma postagem para o mesmo combate")

func _test_campaign_progression() -> void:
	if combat_manager == null or world_state == null or career_loop == null:
		return
	combat_manager.call("start_combat", "terreiro_da_luta", "ruan_macacao", "davi_relampago")
	var money_before: int = int(world_state.get("money"))
	var wins_before: int = int(world_state.get("fights_won"))
	combat_manager.call("finish_combat", {"winner": "ruan_macacao", "method": "controle_posicional", "technical": true})
	_assert(not bool(combat_manager.get("is_running")), "Combate continuou ativo apos finish_combat")
	_assert(int(world_state.get("money")) == money_before + 200, "Recompensa de combate nao foi aplicada")
	_assert(int(world_state.get("fights_won")) == wins_before + 1, "Vitoria nao foi registrada no WorldState")
	var last_combat_result: Dictionary = world_state.get("last_combat_result")
	_assert(str(last_combat_result.get("winner", "")) == "ruan_macacao", "Resultado final nao foi persistido no WorldState")
	var day_before: int = int(world_state.get("day_index"))
	var week_before: int = int(world_state.get("week"))
	career_loop.call("advance_day")
	var day_after: int = int(world_state.get("day_index"))
	var week_after: int = int(world_state.get("week"))
	_assert(day_after != day_before or week_after != week_before, "CareerLoop nao avancou o calendario")

func _finish() -> void:
	print("[RuntimeSmoke] checks=%d failures=%d" % [checks, failures.size()])
	if failures.is_empty():
		print("[RuntimeSmoke] PASS")
		quit(0)
	else:
		for failure in failures:
			print("[RuntimeSmoke] FAIL: " + failure)
		quit(1)
