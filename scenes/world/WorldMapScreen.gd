extends Control

const HUB_SCENE := "res://scenes/hubs/TerreiroDaLuta.tscn"
const ROTA_101_SCENE := "res://scenes/world/Rota101Travel.tscn"

@onready var life_layer: Control = $WorldMapLifeLayer
@onready var status_label: Label = $HUD/LeftPanel/Status
@onready var message_label: Label = $HUD/LeftPanel/Message
@onready var detail_label: Label = $HUD/LeftPanel/Detail
@onready var travel_panel: TravelDetailPanel = $TravelDetailPanel

func _ready() -> void:
	# Compatibilidade temporária: estes quatro atalhos permanecem até o fluxo
	# data-driven substituir toda navegação legada de hubs sem regressão.
	_connect("HUD/RightPanel/Itubera", "itubera")
	_connect("HUD/RightPanel/Salvador", "salvador")
	_connect("HUD/RightPanel/Zambiapunga", "zambiapunga")
	_connect("HUD/RightPanel/Camamu", "camamu_manguezal")
	$HUD/LeftPanel/Regional.pressed.connect(func():
		travel_panel.close_panel()
		life_layer.open_page("01")
	)
	$HUD/RightPanel/Back.pressed.connect(func(): get_tree().change_scene_to_file(HUB_SCENE))
	life_layer.page_changed.connect(_on_page_changed)
	life_layer.node_focused.connect(_on_node_focused)
	travel_panel.method_previewed.connect(_on_method_previewed)
	travel_panel.travel_requested.connect(_on_travel_requested)
	_update_status()

func _connect(path: String, hub_id: String) -> void:
	if has_node(path):
		get_node(path).pressed.connect(_on_travel_pressed.bind(hub_id))

func _on_travel_pressed(hub_id: String) -> void:
	var result := WorldMapManager.travel_to(hub_id)
	message_label.text = str(result.get("message", ""))
	_update_status()
	if result.get("ok", false):
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file(str(result.get("hub", {}).get("entry_scene", HUB_SCENE)))

func _on_page_changed(page_id: String) -> void:
	travel_panel.close_panel()
	message_label.text = "Página %s aberta. Toque em um emblema para planejar ou inspecionar a rota." % page_id

func _on_node_focused(node: Dictionary) -> void:
	var lock_text := "Disponível para descoberta"
	if node.has("lock"):
		lock_text = "Bloqueio: %s" % str(node.get("lock", {}).get("tipo", "progresso"))
	detail_label.text = "%s\n%s\n%s" % [str(node.get("nome", "Local")), str(node.get("tipo", "interesse")).capitalize(), lock_text]
	var context := _build_travel_context()
	var view_model := travel_panel.present_node(WorldMapManager.current_node, node, context)
	var route_id := str(view_model.get("route_id", ""))
	if route_id != "":
		var mastery: Dictionary = WorldMapManager.get_route_mastery(route_id)
		context["route_mastery"] = str(mastery.get("level", "unknown"))
		view_model = travel_panel.present_node(WorldMapManager.current_node, node, context)
	if bool(view_model.get("route_found", false)):
		message_label.text = "Rota encontrada. Escolha o meio e prepare o TravelPlan. Nenhum custo é aplicado antes do commit."
	else:
		message_label.text = "Local selecionado. A ligação a partir do ponto atual ainda não está catalogada."

func _on_method_previewed(vehicle_id: String) -> void:
	message_label.text = "Meio selecionado: %s. PREPARAR VIAGEM valida recursos e cria o plano imutável." % vehicle_id.replace("_", " ").capitalize()

func _on_travel_requested(destination_node: String, vehicle_id: String, world_context: Dictionary) -> void:
	var prepared: Dictionary = WorldMapManager.prepare_travel(destination_node, vehicle_id, world_context)
	if not bool(prepared.get("ok", false)):
		message_label.text = "Viagem não preparada: %s" % _travel_error_text(prepared)
		# Reapresenta o nó para reabilitar a ação após uma falha de recurso/gate.
		if not travel_panel.selected_node.is_empty():
			travel_panel.present_node(WorldMapManager.current_node, travel_panel.selected_node, world_context)
		return
	var plan: Dictionary = prepared.get("plan", {})
	var mode := str(plan.get("mode", "resolved_travel"))
	message_label.text = "TravelPlan %s criado. Modo: %s." % [str(plan.get("plan_id", "")), mode]
	if mode == "rota_101":
		if ResourceLoader.exists(ROTA_101_SCENE):
			get_tree().change_scene_to_file(ROTA_101_SCENE)
			return
		WorldMapManager.cancel_pending_travel(str(plan.get("plan_id", "")))
		message_label.text = "ROTA 101 não encontrada; plano cancelado sem custos."
		return
	if mode in ["resolved_travel", "route_of_tides_future_or_resolved_travel"]:
		_resolve_non_playable_travel(plan)
		return
	WorldMapManager.cancel_pending_travel(str(plan.get("plan_id", "")))
	message_label.text = "Modo %s ainda não possui runtime; plano cancelado sem custos." % mode

func _resolve_non_playable_travel(plan: Dictionary) -> void:
	var committed: Dictionary = WorldMapManager.commit_travel_outcome(str(plan.get("plan_id", "")), {
		"success": true,
		"elapsed_minutes": int(plan.get("base_time_minutes", 0)),
		"energy_delta": 0.0,
		"arrival_condition": "steady",
		"clean": true,
		"discoveries": []
	})
	_update_status()
	if not bool(committed.get("ok", false)):
		message_label.text = "Falha ao comprometer viagem: %s" % _travel_error_text(committed)
		return
	var entry: Dictionary = committed.get("travel_entry", {})
	message_label.text = "Viagem concluída para %s. Estado salvo." % str(entry.get("destination_node", "destino")).replace("_", " ").capitalize()
	var destination_hub := str(entry.get("destination_hub", ""))
	if destination_hub != "" and destination_hub != str(entry.get("origin_hub", "")):
		var hub: Dictionary = WorldMapManager.get_hub_data(destination_hub)
		var scene_path := str(hub.get("entry_scene", ""))
		if scene_path != "" and ResourceLoader.exists(scene_path):
			await get_tree().create_timer(0.35).timeout
			get_tree().change_scene_to_file(scene_path)
			return
	travel_panel.close_panel()
	life_layer.queue_redraw()

func _build_travel_context() -> Dictionary:
	var flags: Dictionary = WorldState.story_flags.duplicate(true)
	var context := {
		"act": int(WorldState.act),
		"sombra": int(WorldState.get_reputation("sombra")),
		"hype": int(WorldState.get_reputation("hype")),
		"honra": int(WorldState.get_reputation("honra")),
		"lua_cheia": bool(flags.get("lua_cheia", false)),
		"weather": WorldDirectorManager.get_weather_for_hub(WorldMapManager.current_hub),
		"flags": flags,
		"completed_missions": WorldState.completed_missions.duplicate(),
		"route_unlocks": WorldMapManager.world_travel_state.get("route_unlocks", []).duplicate()
	}
	if has_node("/root/FactionManager"):
		context["heat_by_faction"] = FactionManager.heat.duplicate(true)
	var tide := str(flags.get("tide", flags.get("mare", "")))
	if tide != "":
		context["tide"] = tide
	var collectibles: Dictionary = flags.get("collectibles", {}) if typeof(flags.get("collectibles", {})) == TYPE_DICTIONARY else {}
	if not collectibles.is_empty():
		context["collectibles"] = collectibles.duplicate(true)
	return context

func _travel_error_text(result: Dictionary) -> String:
	var code := str(result.get("error", "erro_desconhecido"))
	var details: Dictionary = result.get("details", {})
	if code == "route_gated":
		return ", ".join(details.get("reasons", []))
	if code == "insufficient_money":
		return "dinheiro insuficiente"
	if code == "insufficient_fuel":
		return "combustível insuficiente"
	if code == "travel_plan_already_pending":
		return "já existe uma viagem preparada"
	return code.replace("_", " ")

func _update_status() -> void:
	status_label.text = "Hub: %s • Ponto: %s\nR$ %d • Semana %d" % [WorldMapManager.current_hub, WorldMapManager.current_node, WorldState.money, WorldState.week]

func get_map_page_count() -> int:
	return life_layer.get_page_count()

func get_map_node_count() -> int:
	return life_layer.get_node_count()

func get_map_visual_contract() -> Dictionary:
	return life_layer.get_visual_contract()
