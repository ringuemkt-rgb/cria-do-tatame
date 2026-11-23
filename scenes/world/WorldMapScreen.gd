extends Control

const HUB_SCENE := "res://scenes/hubs/TerreiroDaLuta.tscn"
const ROTA_101_SCENE := "res://scenes/world/Rota101Travel.tscn"

# Lock before the world mutation: repeated Android taps must not charge twice.
var _travel_pending := false

@onready var life_layer: Control = $WorldMapLifeLayer
@onready var status_label: Label = $HUD/LeftPanel/Status
@onready var message_label: Label = $HUD/LeftPanel/Message
@onready var detail_label: Label = $HUD/LeftPanel/Detail
@onready var page_label: Label = $HUD/LeftPanel/PageIndex
@onready var travel_panel: TravelDetailPanel = $TravelDetailPanel

func _ready() -> void:
	_connect("HUD/RightPanel/Itubera", "itubera")
	# Legacy map page 10 remains inspectable as narrative reference;
	# Salvador is outside the playable Baixo Sul regional map.
	if has_node("HUD/RightPanel/Salvador"):
		$HUD/RightPanel/Salvador.disabled = true
		$HUD/RightPanel/Salvador.tooltip_text = "Referência narrativa externa • não é destino jogável do Baixo Sul."
	_connect("HUD/RightPanel/Zambiapunga", "zambiapunga")
	_connect("HUD/RightPanel/Camamu", "camamu_manguezal")
	$HUD/LeftPanel/Regional.pressed.connect(func():
		travel_panel.close_panel()
		life_layer.open_page("01")
	)
	$HUD/LeftPanel/PreviousPage.pressed.connect(_shift_page.bind(-1))
	$HUD/LeftPanel/NextPage.pressed.connect(_shift_page.bind(1))
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
	if _travel_pending:
		return
	if hub_id not in ["itubera", "zambiapunga", "camamu_manguezal"]:
		message_label.text = "Fora do circuito regional jogável nesta etapa."
		return
	# Validate the destination scene before WorldMapManager debits currency,
	# advances time, writes a save or broadcasts the travel event.
	if WorldMapManager.can_travel_to(hub_id):
		var hub: Dictionary = WorldMapManager.get_hub_data(hub_id)
		var entry_scene := str(hub.get("entry_scene", HUB_SCENE))
		if entry_scene == "" or not ResourceLoader.exists(entry_scene):
			message_label.text = "Cena regional indisponível. Nenhum valor debitado."
			return
	_travel_pending = true
	_set_travel_controls_enabled(false)
	var result: Dictionary = _perform_travel(hub_id)
	message_label.text = str(result.get("message", ""))
	_update_status()
	if not bool(result.get("ok", false)):
		_travel_pending = false
		_set_travel_controls_enabled(true)
		return
	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree():
		return
	var destination := str(result.get("hub", {}).get("entry_scene", HUB_SCENE))
	var error: Error = get_tree().change_scene_to_file(destination)
	if error != OK:
		# Travel has already been committed and saved. Keep controls locked
		# instead of charging the player a second time on another tap.
		message_label.text = "Viagem registrada, mas o destino não abriu. Reabra o jogo para recuperar o save."
		push_error("[WorldMapScreen] Falha ao abrir destino: %s" % error_string(error))

func _perform_travel(hub_id: String) -> Dictionary:
	return WorldMapManager.travel_to(hub_id)

func _set_travel_controls_enabled(enabled: bool) -> void:
	for button_name in ["Itubera", "Zambiapunga", "Camamu", "Back"]:
		var button := get_node_or_null("HUD/RightPanel/" + button_name) as Button
		if button != null:
			button.disabled = not enabled
	# Salvador remains a context-only location regardless of travel state.

func _on_page_changed(page_id: String) -> void:
	travel_panel.close_panel()
	message_label.text = "Página %s: %s. Toque em um emblema para detalhes." % [page_id, life_layer.get_page_name(page_id)]
	_update_status()

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
	if _travel_pending:
		return
	_travel_pending = true
	_set_travel_controls_enabled(false)
	var prepared: Dictionary = WorldMapManager.prepare_travel(destination_node, vehicle_id, world_context)
	if not bool(prepared.get("ok", false)):
		message_label.text = "Viagem não preparada: %s" % _travel_error_text(prepared)
		_travel_pending = false
		_set_travel_controls_enabled(true)
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
		_travel_pending = false
		_set_travel_controls_enabled(true)
		return
	if mode in ["resolved_travel", "route_of_tides_future_or_resolved_travel"]:
		await _resolve_non_playable_travel(plan)
		return
	WorldMapManager.cancel_pending_travel(str(plan.get("plan_id", "")))
	message_label.text = "Modo %s ainda não possui runtime; plano cancelado sem custos." % mode
	_travel_pending = false
	_set_travel_controls_enabled(true)

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
		_travel_pending = false
		_set_travel_controls_enabled(true)
		return
	var entry: Dictionary = committed.get("travel_entry", {})
	message_label.text = "Viagem concluída para %s. Estado salvo." % str(entry.get("destination_node", "destino")).replace("_", " ").capitalize()
	var destination_hub := str(entry.get("destination_hub", ""))
	if destination_hub != "" and destination_hub != str(entry.get("origin_hub", "")):
		var hub: Dictionary = WorldMapManager.get_hub_data(destination_hub)
		var scene_path := str(hub.get("entry_scene", ""))
		if scene_path != "" and ResourceLoader.exists(scene_path):
			await get_tree().create_timer(0.35).timeout
			if is_inside_tree():
				var error := get_tree().change_scene_to_file(scene_path)
				if error == OK:
					return
				push_error("[WorldMapScreen] Falha ao abrir destino two-phase: %s" % error_string(error))
	travel_panel.close_panel()
	life_layer.queue_redraw()
	_travel_pending = false
	_set_travel_controls_enabled(true)

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

func _shift_page(direction: int) -> void:
	var ids: Array = life_layer.call("get_page_ids")
	if ids.is_empty():
		return
	var current_index := ids.find(str(life_layer.active_page_id))
	var next_index := posmod(current_index + direction, ids.size())
	life_layer.open_page(str(ids[next_index]))

func _update_status() -> void:
	status_label.text = "Hub: %s • Ponto: %s\nR$ %d • Semana %d" % [WorldMapManager.current_hub, WorldMapManager.current_node, WorldState.money, WorldState.week]
	var id := str(life_layer.active_page_id)
	var source: Dictionary = life_layer.call("get_page_source_state", id)
	page_label.text = "PÁGINA %s/%d • %s\nARTE: %s • CARTOGRAFIA EM REVISÃO" % [
		id, life_layer.get_page_count(), life_layer.get_page_name(id),
		"CONCEITO" if bool(source.get("candidate_loaded", false)) else "PROVISÓRIA"
	]

func get_map_page_count() -> int:
	return life_layer.get_page_count()

func get_map_node_count() -> int:
	return life_layer.get_node_count()

func get_map_visual_contract() -> Dictionary:
	return life_layer.get_visual_contract()
