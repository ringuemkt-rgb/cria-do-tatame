extends SceneTree

const CombatSimulationEngineScript = preload("res://src/combat/CombatManager.gd")

const REQUIRED_SCENES := [
	"res://scenes/main_menu/MainMenu.tscn",
	"res://scenes/hubs/TerreiroDaLuta.tscn",
	"res://scenes/combat/CombatArenaBase.tscn",
	"res://scenes/result/ResultScreen.tscn",
	"res://scenes/ui/CriaLiveUI.tscn"
]

var failures: Array[String] = []
var checks: int = 0
var signal_bus: Node
var data_registry: Node
var world_state: Node
var save_manager: Node
var combat_manager: Node
var career_loop: Node
var game_flow_manager: Node
var audio_manager: Node

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
	_test_autoloads()
	_test_data_registry()
	await _test_scene_loading()
	_test_save_roundtrip()
	_test_combat_domain()
	_finish()

func _resolve_autoloads() -> void:
	signal_bus = root.get_node_or_null("SignalBus")
	data_registry = root.get_node_or_null("DataRegistry")
	world_state = root.get_node_or_null("WorldState")
	save_manager = root.get_node_or_null("SaveManager")
	combat_manager = root.get_node_or_null("CombatManager")
	career_loop = root.get_node_or_null("CareerLoop")
	game_flow_manager = root.get_node_or_null("GameFlowManager")
	audio_manager = root.get_node_or_null("AudioManager")

func _test_autoloads() -> void:
	var nodes: Dictionary = {
		"SignalBus": signal_bus,
		"DataRegistry": data_registry,
		"WorldState": world_state,
		"SaveManager": save_manager,
		"CombatManager": combat_manager,
		"CareerLoop": career_loop,
		"GameFlowManager": game_flow_manager,
		"AudioManager": audio_manager
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
	_assert(not ruan.is_empty(), "Ruan Macacao nao foi carregado")
	_assert(not arena.is_empty(), "Terreiro da Luta nao foi carregado")
	_assert(techniques.size() >= 10, "Catalogo principal possui menos de 10 tecnicas")

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
	var player_stats: Dictionary = engine.get("player_stats")
	var opponent_stats: Dictionary = engine.get("opponent_stats")
	var applied: Dictionary = resolver.call(
		"aplicar_resultado",
		player_stats,
		opponent_stats,
		{"success": true, "cost": {"gas": 0, "focus": 0, "moral": 0}, "effects": normalized}
	)
	var defender: Dictionary = applied.get("defender", {})
	_assert(is_equal_approx(float(defender.get("grip_integrity", 100)), 92.0), "Reducao de grip foi aplicada com sinal incorreto")
	engine.queue_free()
	combat_manager.set("is_running", false)

func _finish() -> void:
	print("[RuntimeSmoke] checks=%d failures=%d" % [checks, failures.size()])
	if failures.is_empty():
		print("[RuntimeSmoke] PASS")
		quit(0)
	else:
		for failure in failures:
			print("[RuntimeSmoke] FAIL: " + failure)
		quit(1)
