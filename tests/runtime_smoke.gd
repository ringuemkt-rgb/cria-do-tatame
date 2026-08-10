extends SceneTree

const CombatSimulationEngineScript = preload("res://src/combat/CombatManager.gd")
const DaviAIControllerScript = preload("res://src/combat/DaviAIController.gd")
const TechniqueClashResolverScript = preload("res://src/combat/TechniqueClashResolver.gd")
const GroundGraphRulesScript = preload("res://src/combat/GroundGraphRules.gd")
const SubmissionExchangeScript = preload("res://src/combat/SubmissionExchange.gd")
const GroundStaminaRulesScript = preload("res://src/combat/GroundStaminaRules.gd")
const FighterStyleSystemScript = preload("res://src/career/FighterStyleSystem.gd")

const REQUIRED_SCENES := [
	"res://scenes/main_menu/MainMenu.tscn",
	"res://scenes/hubs/TerreiroDaLuta.tscn",
	"res://scenes/combat/CombatArenaBase.tscn",
	"res://scenes/result/ResultScreen.tscn",
	"res://scenes/ui/CriaLiveUI.tscn",
	"res://scenes/ui/DeckBuilder.tscn",
	"res://scenes/ui/CombatDeckHUD.tscn",
	"res://scenes/ui/StyleProgressionScreen.tscn",
	"res://scenes/ui/SubmissionHUD.tscn"
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
	_test_fighter_style_runtime()
	_test_ground_submission_data()
	_test_ground_stamina_data()
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
	var fighter_styles: Dictionary = data_registry.get("fighter_styles")
	var skill_tree_v2: Dictionary = data_registry.get("skill_tree_v2")
	var ground_graph: Dictionary = data_registry.get("ground_graph")
	var submissions_anatomy: Dictionary = data_registry.get("submissions_anatomy")
	var submission_exchange: Dictionary = data_registry.get("submission_exchange")
	_assert(not ruan.is_empty(), "Ruan Macacao nao foi carregado")
	_assert(not arena.is_empty(), "Terreiro da Luta nao foi carregado")
	_assert(techniques.size() >= 10, "Catalogo principal possui menos de 10 tecnicas")
	_assert(not local_ai_config.is_empty(), "Configuracao da IA local nao foi carregada")
	_assert(not dialogue_fallbacks.is_empty(), "Dialogos offline de fallback nao foram carregados")
	_assert(animation_catalog.get("entries", []).size() >= 31, "Catalogo de animacoes nao foi carregado")
	_assert(arena_animation_flow.get("fight_flow", []).size() >= 10, "Fluxo animado das arenas nao foi carregado")
	_assert(combat_deck.get("cards", []).size() == 10, "Deck inicial nao possui 10 cartas")
	_assert(fighter_styles.get("styles", []).size() == 8, "Roda de estilos nao possui oito estilos")
	_assert(skill_tree_v2.get("branches", []).size() == 4, "Arvore V2 nao possui quatro ramos")
	_assert(ground_graph.get("edges", []).size() == techniques.size(), "Grafo de solo nao cobre todas as tecnicas")
	_assert(submissions_anatomy.get("records", []).size() == 12, "Catalogo anatomico nao possui 12 registros")
	_assert(submission_exchange.get("simulation", "") == "turn_based_deterministic", "Troca de finalizacao nao e deterministica")
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

func _test_fighter_style_runtime() -> void:
	if world_state == null or data_registry == null:
		return
	var before: Dictionary = world_state.call("to_dict").duplicate(true)
	world_state.set("skill_points", 2)
	world_state.set("story_flags", {})
	world_state.call("_sync_aliases")
	var styles: RefCounted = FighterStyleSystemScript.new()
	_assert(str(styles.call("get_active_style_id")) == "pressao", "Estilo inicial nao preservou a identidade Pressao")
	var purchase: Dictionary = styles.call("purchase_node", "guarda_inteligente")
	_assert(bool(purchase.get("ok", false)), "Compra de habilidade falhou")
	_assert(int(styles.call("get_node_level", "guarda_inteligente")) == 1, "Nivel da habilidade nao foi persistido no estado")
	var modifiers: Dictionary = styles.call("get_combat_modifiers")
	_assert(float(modifiers.get("starting_resources", {}).get("guard", 0.0)) >= 1.0, "Arvore nao alimentou modificadores de combate")
	world_state.call("load_from_dict", before)

func _test_ground_submission_data() -> void:
	if data_registry == null:
		return
	var graph: RefCounted = GroundGraphRulesScript.new()
	graph.call("configure", data_registry.get("ground_graph"))
	var edge: Dictionary = graph.call("get_edge", "chave_braco")
	_assert(str(edge.get("from", "")) == "PLAYER_TOP_MOUNT", "Grafo perdeu a entrada da chave de braco")
	var validation: Dictionary = graph.call(
		"validate_technique_transition",
		data_registry.call("get_technique", "chave_braco"),
		"PLAYER_TOP_MOUNT"
	)
	_assert(bool(validation.get("ok", false)), "Grafo recusou uma transicao canonica")

	var exchange: Node = SubmissionExchangeScript.new()
	root.add_child(exchange)
	exchange.call("configure", data_registry.get("submission_exchange"), data_registry.get("submissions_anatomy"))
	var started: Dictionary = exchange.call(
		"start_exchange",
		"chave_braco",
		"ruan_macacao",
		"davi_relampago",
		"PLAYER_TOP_MOUNT",
		0.5,
		{"arena_id": "terreiro_da_luta", "uniform": "gi", "age_division": "adult", "belt": "branca"}
	)
	_assert(bool(started.get("ok", false)), "Troca de finalizacao nao iniciou")
	var defense_actions: Array = exchange.call("get_available_actions", "davi_relampago")
	var has_tap := false
	for action_value in defense_actions:
		if typeof(action_value) == TYPE_DICTIONARY and str(action_value.get("id", "")) == "submission_tap":
			has_tap = true
	_assert(has_tap, "Defensor nao recebeu tap prioritario")
	var tap: Dictionary = exchange.call("apply_action", "davi_relampago", "submission_tap")
	_assert(str(tap.get("outcome", "")) == "tap", "Tap nao encerrou a troca imediatamente")
	_assert(not bool(exchange.get("active")), "Troca continuou ativa depois do tap")
	exchange.queue_free()

func _test_ground_stamina_data() -> void:
	if data_registry == null:
		return
	var rules: RefCounted = GroundStaminaRulesScript.new()
	rules.call("configure", data_registry.get("ground_stamina"))
	var technique: Dictionary = data_registry.call("get_technique", "chave_braco")
	var decorated: Dictionary = rules.call("decorate_technique", technique, "PLAYER_TOP_MOUNT")
	var original_cost: Dictionary = technique.get("cost", {})
	var decorated_cost: Dictionary = decorated.get("cost", {})
	_assert(
		float(decorated_cost.get("gas", 0.0)) > float(original_cost.get("gas", 0.0)),
		"Stamina de solo nao adicionou sobretaxa posicional"
	)
	var fresh: Dictionary = rules.call("get_fatigue_profile", 100.0)
	var exhausted: Dictionary = rules.call("get_fatigue_profile", 10.0)
	_assert(str(fresh.get("id", "")) == "fresh", "Gas cheio nao retornou faixa fresh")
	_assert(float(exhausted.get("submission_effectiveness", 1.0)) == 0.60, "Fadiga extrema nao aplicou o limite seguro")

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

	# Setup de finalizacao abre a troca controle x escape sem reduzir vida.
	var submission_state_machine: Node = combat_manager.get("state_machine")
	submission_state_machine.call("forcar_estado", submission_state_machine.call("estado_por_nome", "PLAYER_TOP_MOUNT"))
	var submission_fighters: Dictionary = combat_manager.get("fighters")
	submission_fighters["ruan_macacao"]["gas"] = 100.0
	submission_fighters["ruan_macacao"]["focus"] = 100.0
	submission_fighters["ruan_macacao"]["grip"] = 100.0
	submission_fighters["ruan_macacao"]["control"] = 100.0
	submission_fighters["davi_relampago"]["focus"] = 0.0
	submission_fighters["davi_relampago"]["guard"] = 0.0
	submission_fighters["davi_relampago"]["health"] = 100.0
	combat_manager.set("fighters", submission_fighters)
	var setup: Dictionary = data_registry.call("get_technique", "chave_braco").duplicate(true)
	setup["base_chance"] = 0.95
	setup["chance_sucesso"] = 0.95
	_seed_runtime_resolver_for_success(0.95)
	var setup_result: Dictionary = combat_manager.call("execute_technique", "ruan_macacao", "davi_relampago", setup)
	_assert(bool(setup_result.get("success", false)), "Setup de finalizacao falhou no smoke deterministico")
	_assert(bool(combat_manager.get("submission_exchange").get("active")), "Setup nao abriu SubmissionExchange")
	var after_setup: Dictionary = combat_manager.get("fighters")
	_assert(is_equal_approx(float(after_setup["davi_relampago"].get("health", 0.0)), 100.0), "Setup de finalizacao aplicou dano direto")
	var release: Dictionary = combat_manager.call("apply_player_action", "submission_release")
	_assert(str(release.get("outcome", "")) == "release", "Soltura segura nao resolveu a troca")
	_assert(str(combat_manager.call("get_current_state_name")) == "PLAYER_TOP_MOUNT", "Soltura nao recuperou a posicao de origem")

	# Tap integrado tem prioridade, encerra a troca e registra o vencedor sem dano.
	_seed_runtime_resolver_for_success(0.95)
	var second_setup: Dictionary = combat_manager.call("execute_technique", "ruan_macacao", "davi_relampago", setup)
	_assert(bool(second_setup.get("success", false)), "Segundo setup de finalizacao falhou")
	var integrated_tap: Dictionary = combat_manager.call("apply_opponent_action", "submission_tap")
	_assert(str(integrated_tap.get("outcome", "")) == "tap", "Tap integrado nao teve prioridade")
	_assert(not bool(combat_manager.get("is_running")), "Combate continuou ativo depois do tap")
	var tap_result: Dictionary = world_state.get("last_combat_result")
	_assert(str(tap_result.get("winner", "")) == "ruan_macacao", "Tap nao registrou o atacante como vencedor")
	_assert(str(tap_result.get("submission_outcome", "")) == "tap", "Resultado final perdeu o outcome de tap")

	# Regressao P0: uma finalizacao bem-sucedida precisa encerrar antes do RESET.
	combat_manager.call("start_combat", "terreiro_da_luta", "ruan_macacao", "davi_relampago")
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
