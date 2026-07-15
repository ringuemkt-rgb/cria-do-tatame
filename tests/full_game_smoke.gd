extends SceneTree

const REQUIRED_AUTOLOADS: Array[String] = [
	"SignalBus", "DataRegistry", "LocalAIManager", "WorldState", "WorldDirectorManager",
	"NFTManager", "SaveManager", "CombatManager", "CareerLoop", "ReputationMatrix",
	"CriaLiveManager", "AudioManager", "TinkerBondManager", "MissionManager",
	"StorySceneDirector", "FactionManager", "FactionDirectorManager", "FactionAIPlanBridge",
	"WorldMapManager", "GearManager", "TrainingManager", "HubActivityManager",
	"CriaLiveInteractionManager", "GameFlowManager", "CutsceneRuntime"
]

var failures: Array[String] = []
var checks: int = 0
var loaded_scene_count: int = 0

var registry: Node
var local_ai: Node
var world_state: Node
var world_director: Node
var nft_manager: Node
var save_manager: Node
var combat_manager: Node
var faction_director: Node
var world_map: Node
var hub_activity: Node
var cria_live: Node
var audio_manager: Node

func _initialize() -> void:
	call_deferred("_run")

func _assert(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		return
	failures.append(message)
	push_error("[FullGameSmoke] " + message)

func _run() -> void:
	await process_frame
	_resolve_autoloads()
	_disable_audio()
	_test_autoloads()
	_test_data_registry()
	_test_all_scenes_load()
	_test_offline_policy()
	_test_world_director()
	_test_faction_director()
	_test_hub_travel_and_activities()
	_test_cria_live()
	_test_combat_catalog()
	_test_save_roundtrip()
	_finish()

func _resolve_autoloads() -> void:
	registry = root.get_node_or_null("DataRegistry")
	local_ai = root.get_node_or_null("LocalAIManager")
	world_state = root.get_node_or_null("WorldState")
	world_director = root.get_node_or_null("WorldDirectorManager")
	nft_manager = root.get_node_or_null("NFTManager")
	save_manager = root.get_node_or_null("SaveManager")
	combat_manager = root.get_node_or_null("CombatManager")
	faction_director = root.get_node_or_null("FactionDirectorManager")
	world_map = root.get_node_or_null("WorldMapManager")
	hub_activity = root.get_node_or_null("HubActivityManager")
	cria_live = root.get_node_or_null("CriaLiveManager")
	audio_manager = root.get_node_or_null("AudioManager")

func _disable_audio() -> void:
	if audio_manager != null:
		audio_manager.set("enabled", false)

func _test_autoloads() -> void:
	for singleton_name in REQUIRED_AUTOLOADS:
		_assert(root.get_node_or_null(singleton_name) != null, "Autoload ausente: %s" % singleton_name)

func _test_data_registry() -> void:
	if registry == null:
		return
	var report: Dictionary = registry.get("validation_report")
	_assert(bool(report.get("ok", false)), "DataRegistry inválido: %s" % str(report.get("errors", [])))
	_assert(not registry.get("characters").is_empty(), "Catálogo de personagens vazio")
	_assert(not registry.get("techniques").is_empty(), "Catálogo de técnicas vazio")
	_assert(not registry.get("arenas").is_empty(), "Catálogo de arenas vazio")
	_assert(not registry.get("story_missions").is_empty(), "Missões narrativas não carregadas")
	_assert(not registry.get("faction_drama_bible").is_empty(), "Bíblia de facções não carregada")
	_assert(not registry.get("complete_game_flow").is_empty(), "Fluxo completo não carregado")
	var hubs: Dictionary = registry.get("hubs_dense").get("hubs", {})
	_assert(hubs.size() == 4, "Mapa denso não carregou quatro hubs")
	for hub_id_value in hubs.keys():
		var hub: Dictionary = hubs[hub_id_value]
		var scene_path: String = str(hub.get("entry_scene", ""))
		_assert(ResourceLoader.exists(scene_path), "Hub sem cena de entrada: %s -> %s" % [hub_id_value, scene_path])
		for activity_id_value in hub.get("activities", []):
			var activity = hub_activity.call("get_activity", str(activity_id_value)) if hub_activity != null else {}
			_assert(typeof(activity) == TYPE_DICTIONARY and not activity.is_empty(), "Hub referencia atividade inexistente: %s" % activity_id_value)

func _collect_scene_paths(directory: String, output: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(directory)
	if dir == null:
		_assert(false, "Diretório de cenas inacessível: %s" % directory)
		return
	dir.list_dir_begin()
	var item: String = dir.get_next()
	while item != "":
		if item != "." and item != "..":
			var full_path: String = directory.path_join(item)
			if dir.current_is_dir():
				_collect_scene_paths(full_path, output)
			elif item.ends_with(".tscn"):
				output.append(full_path)
		item = dir.get_next()
	dir.list_dir_end()

func _test_all_scenes_load() -> void:
	var scene_paths: Array[String] = []
	_collect_scene_paths("res://scenes", scene_paths)
	scene_paths.sort()
	_assert(scene_paths.size() >= 8, "Poucas cenas encontradas: %s" % scene_paths.size())
	for scene_path in scene_paths:
		_assert(ResourceLoader.exists(scene_path), "Cena não existe para ResourceLoader: %s" % scene_path)
		var resource: Resource = load(scene_path)
		_assert(resource is PackedScene, "Recurso não é PackedScene: %s" % scene_path)
		if not (resource is PackedScene):
			continue
		var instance: Node = (resource as PackedScene).instantiate()
		_assert(instance != null, "Falha ao instanciar cena: %s" % scene_path)
		if instance != null:
			loaded_scene_count += 1
			instance.free()
	_assert(loaded_scene_count == scene_paths.size(), "Nem todas as cenas foram instanciadas: %s/%s" % [loaded_scene_count, scene_paths.size()])

func _test_offline_policy() -> void:
	if local_ai != null and local_ai.has_method("is_network_backend_enabled"):
		_assert(not bool(local_ai.call("is_network_backend_enabled")), "IA local iniciou com rede ativa")
	if world_director != null and world_director.has_method("is_ai_proxy_enabled"):
		_assert(not bool(world_director.call("is_ai_proxy_enabled")), "World Director iniciou com proxy remoto ativo")
	if nft_manager != null:
		_assert(str(nft_manager.get("_backend_url")) == "", "NFTManager iniciou com backend remoto ativo")
		var catalog: Dictionary = nft_manager.get("catalog")
		for item_value in catalog.get("items", []):
			var asset_path: String = str(item_value.get("asset_path", ""))
			_assert(ResourceLoader.exists(asset_path), "Colecionável sem asset importável: %s" % asset_path)

func _test_world_director() -> void:
	if world_director == null:
		return
	world_director.call("reset_world")
	var before: Dictionary = world_director.call("get_snapshot")
	_assert(not before.get("weather_by_region", {}).is_empty(), "Clima regional não inicializado")
	for _index in range(8):
		world_director.call("advance_time_block")
	var after: Dictionary = world_director.call("get_snapshot")
	_assert(int(after.get("tick", 0)) >= 8, "World Director não avançou oito ticks")
	_assert(str(after.get("time_block", "")) != "", "Bloco de tempo vazio")
	_assert(not after.get("npc_states", {}).is_empty(), "Rotinas de NPC não geradas")
	_assert(not after.get("economy_modifiers", {}).is_empty(), "Economia regional não gerada")

func _test_faction_director() -> void:
	if faction_director == null:
		return
	faction_director.call("reset_director")
	var initial: Dictionary = faction_director.call("get_snapshot")
	_assert(initial.get("factions", {}).size() == 7, "Quantidade de facções inesperada")
	_assert(initial.get("territories", {}).size() >= 15, "Territórios insuficientes")
	for week_number in range(1, 6):
		faction_director.call("advance_faction_week", week_number)
	var after: Dictionary = faction_director.call("get_snapshot")
	_assert(not after.get("active_operations", []).is_empty() or not after.get("operation_history", []).is_empty(), "Facções não iniciaram nem resolveram operações")
	_assert(after.get("champions", {}).size() == 7, "Campeões das facções incompletos")
	_assert(after.get("pressure", {}).size() == 5, "Eixos de Pressão Regional incompletos")

func _test_hub_travel_and_activities() -> void:
	if world_state == null or world_map == null or hub_activity == null:
		return
	world_state.call("reset_new_game")
	world_state.set("money", 2000)
	world_state.set("energy", 100.0)
	world_map.call("reset")
	for hub_id in ["itubera", "salvador", "zambiapunga", "camamu_manguezal"]:
		var travel: Dictionary = world_map.call("travel_to", hub_id)
		_assert(bool(travel.get("ok", false)), "Falha ao viajar para %s: %s" % [hub_id, travel.get("message", "")])
		if not bool(travel.get("ok", false)):
			continue
		var activities: Array = hub_activity.call("get_available_for_hub", hub_id)
		_assert(not activities.is_empty(), "Hub sem atividades executáveis: %s" % hub_id)
		if activities.is_empty():
			continue
		var activity_id: String = str(activities[0].get("id", ""))
		_assert(activity_id != "", "Atividade do hub sem ID: %s" % hub_id)
		if activity_id != "":
			world_state.set("money", 2000)
			world_state.set("energy", 100.0)
			var result: Dictionary = hub_activity.call("execute_activity", activity_id)
			_assert(bool(result.get("ok", false)), "Atividade falhou em %s: %s" % [hub_id, result.get("message", "")])

func _test_cria_live() -> void:
	if cria_live == null:
		return
	var before: int = int(cria_live.call("get_feed").size()) if cria_live.has_method("get_feed") else 0
	if cria_live.has_method("create_faction_post"):
		cria_live.call("create_faction_post", "terreiro", "Auditoria do Terreiro concluída.", "smoke", {"reach": 1.0, "credibility": 1.0})
	var after: int = int(cria_live.call("get_feed").size()) if cria_live.has_method("get_feed") else before
	_assert(after == before + 1, "Cria Live não criou exatamente um post de facção")

func _test_combat_catalog() -> void:
	if registry == null or combat_manager == null:
		return
	var start_result: Dictionary = combat_manager.call("start_combat", "terreiro_da_luta", "ruan_macacao", "davi_relampago")
	_assert(bool(start_result.get("ok", false)), "Combate principal não iniciou")
	if not bool(start_result.get("ok", false)):
		return
	var available: Array = combat_manager.call("get_available_techniques", "ruan_macacao")
	_assert(not available.is_empty(), "Jogador iniciou combate sem técnicas disponíveis")
	for item in available:
		var technique_id: String = str(item.get("id", "")) if typeof(item) == TYPE_DICTIONARY else str(item)
		var technique = registry.call("get_technique", technique_id)
		_assert(typeof(technique) == TYPE_DICTIONARY and not technique.is_empty(), "Técnica disponível não existe no registro: %s" % technique_id)
	if bool(combat_manager.get("is_running")):
		combat_manager.call("finish_combat", {"winner": "ruan_macacao", "opponent_id": "davi_relampago", "method": "audit_stop"})
	_assert(not bool(combat_manager.get("is_running")), "Combate não encerrou no cleanup")

func _test_save_roundtrip() -> void:
	if save_manager == null or world_state == null:
		return
	const SLOT: int = 8765
	world_state.call("reset_new_game")
	world_state.set("money", 777)
	world_state.set("energy", 66.0)
	if faction_director != null:
		faction_director.call("reset_director")
		faction_director.call("advance_faction_week", 2)
	var faction_before: Dictionary = faction_director.call("get_snapshot") if faction_director != null else {}
	_assert(bool(save_manager.call("save_game", SLOT)), "Falha ao salvar estado integral")
	world_state.set("money", 0)
	world_state.set("energy", 1.0)
	if faction_director != null:
		faction_director.call("reset_director")
	_assert(bool(save_manager.call("load_game", SLOT)), "Falha ao carregar estado integral")
	_assert(int(world_state.get("money")) == 777, "Save não restaurou dinheiro")
	_assert(is_equal_approx(float(world_state.get("energy")), 66.0), "Save não restaurou energia")
	if faction_director != null:
		var faction_after: Dictionary = faction_director.call("get_snapshot")
		_assert(int(faction_after.get("week", 0)) == int(faction_before.get("week", -1)), "Save não restaurou semana das facções")
		_assert(faction_after.get("factions", {}).size() == faction_before.get("factions", {}).size(), "Save não restaurou facções")
	save_manager.call("delete_save", SLOT)

func _finish() -> void:
	if failures.is_empty():
		print("[FullGameSmoke] PASS — %s verificações; %s cenas carregadas." % [checks, loaded_scene_count])
		quit(0)
		return
	print("[FullGameSmoke] FAIL — %s falhas em %s verificações." % [failures.size(), checks])
	for failure in failures:
		print(" - " + failure)
	quit(1)
