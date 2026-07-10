extends SceneTree

const REQUIRED_SCENES := [
	"res://scenes/main_menu/MainMenu.tscn",
	"res://scenes/hubs/TerreiroDaLuta.tscn",
	"res://scenes/combat/CombatArenaBase.tscn",
	"res://scenes/result/ResultScreen.tscn",
	"res://scenes/ui/CriaLiveUI.tscn"
]

var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _assert(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("[RuntimeSmoke] " + message)

func _run() -> void:
	await process_frame
	_test_autoloads()
	_test_data_registry()
	await _test_scene_loading()
	_test_save_roundtrip()
	_test_combat_domain()
	_finish()

func _test_autoloads() -> void:
	for singleton_name in [
		"SignalBus",
		"DataRegistry",
		"WorldState",
		"SaveManager",
		"CombatManager",
		"CareerLoop",
		"GameFlowManager",
		"AudioManager"
	]:
		_assert(root.has_node(singleton_name), "Autoload ausente: %s" % singleton_name)

func _test_data_registry() -> void:
	_assert(DataRegistry.validation_report.get("ok", false), "DataRegistry reportou erros: %s" % str(DataRegistry.validation_report.get("errors", [])))
	_assert(not DataRegistry.get_character("ruan_macacao").is_empty(), "Ruan Macacao nao foi carregado")
	_assert(not DataRegistry.get_arena("terreiro_da_luta").is_empty(), "Terreiro da Luta nao foi carregado")
	_assert(DataRegistry.techniques.size() >= 10, "Catalogo principal possui menos de 10 tecnicas")

func _test_scene_loading() -> void:
	for scene_path in REQUIRED_SCENES:
		_assert(ResourceLoader.exists(scene_path), "Cena nao existe: %s" % scene_path)
		var resource := load(scene_path)
		_assert(resource is PackedScene, "Recurso nao e PackedScene: %s" % scene_path)
		if not resource is PackedScene:
			continue
		var instance := (resource as PackedScene).instantiate()
		_assert(instance != null, "Falha ao instanciar: %s" % scene_path)
		if instance == null:
			continue
		root.add_child(instance)
		await process_frame
		_assert(is_instance_valid(instance), "Instancia foi invalidada durante _ready: %s" % scene_path)
		instance.queue_free()
		await process_frame
	if CombatManager.is_running:
		CombatManager.is_running = false
		CombatManager.phase = CombatManager.CombatPhase.RESET
		if CombatManager.state_machine != null:
			CombatManager.state_machine.reset()

func _test_save_roundtrip() -> void:
	const SLOT := 9876
	WorldState.reset_new_game()
	WorldState.money = 321
	WorldState.energy = 77.0
	WorldState._sync_aliases()
	_assert(SaveManager.save_game(SLOT), "SaveManager falhou ao salvar slot de teste")
	WorldState.money = 0
	WorldState.energy = 1.0
	_assert(SaveManager.load_game(SLOT), "SaveManager falhou ao carregar slot de teste")
	_assert(WorldState.money == 321, "Roundtrip de save nao restaurou dinheiro")
	_assert(is_equal_approx(WorldState.energy, 77.0), "Roundtrip de save nao restaurou energia")
	SaveManager.delete_save(SLOT)

func _test_combat_domain() -> void:
	var start_result: Dictionary = CombatManager.start_combat("terreiro_da_luta", "ruan_macacao", "davi_relampago")
	_assert(start_result.get("ok", false), "CombatManager nao iniciou combate")
	_assert(CombatManager.get_current_state_name() == "PLAYER_STANDING_NEUTRAL", "Combate nao iniciou em pe")
	var available := CombatManager.get_available_techniques()
	_assert(not available.is_empty(), "Nenhuma tecnica disponivel no estado inicial")
	var missing: Dictionary = CombatManager.apply_player_action("tecnica_inexistente")
	_assert(missing.get("error", "") == "technique_not_found", "Tecnica inexistente nao retornou erro seguro")

	var engine := CombatSimulationEngine.new()
	root.add_child(engine)
	engine.setup(
		{"gas": 70, "focus": 60, "grip": 95, "guard": 100, "control": 55, "moral": 60},
		{"gas": 70, "focus": 50, "grip": 50, "guard": 50, "grip_integrity": 100, "control": 50, "moral": 50}
	)
	var technique := {
		"id": "smoke_grip",
		"entry_state": "distancia_media",
		"exit_state": "disputa_pegada",
		"base_chance": 0.9,
		"cost": {"gas": 2, "focus": 1},
		"effects": {"self_control_bonus": 5, "opponent_grip_reduction": 8}
	}
	var simulation: Dictionary = engine.use_technique(technique)
	_assert(not simulation.has("error"), "CombatSimulationEngine retornou erro")
	var normalized: Dictionary = engine.technique_resolver._efeitos(technique, true)
	var applied: Dictionary = engine.technique_resolver.aplicar_resultado(
		engine.player_stats,
		engine.opponent_stats,
		{"success": true, "cost": {"gas": 0, "focus": 0, "moral": 0}, "effects": normalized}
	)
	_assert(is_equal_approx(float(applied.get("defender", {}).get("grip_integrity", 100)), 92.0), "Reducao de grip foi aplicada com sinal incorreto")
	engine.queue_free()
	CombatManager.is_running = false

func _finish() -> void:
	print("[RuntimeSmoke] checks=%d failures=%d" % [checks, failures.size()])
	if failures.is_empty():
		print("[RuntimeSmoke] PASS")
		quit(0)
	else:
		for failure in failures:
			print("[RuntimeSmoke] FAIL: " + failure)
		quit(1)
