extends Control

const HUB_SCENE := "res://scenes/hubs/TerreiroDaLuta.tscn"

@onready var life_layer: Control = $WorldMapLifeLayer
@onready var status_label: Label = $HUD/LeftPanel/Status
@onready var message_label: Label = $HUD/LeftPanel/Message
@onready var detail_label: Label = $HUD/LeftPanel/Detail
@onready var travel_panel: TravelDetailPanel = $TravelDetailPanel

func _ready() -> void:
	# Compatibilidade temporária: estes quatro atalhos permanecem até VT3 provar
	# o fluxo data-driven prepare -> resolve -> commit de ponta a ponta.
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
	var view_model := travel_panel.present_node(WorldMapManager.current_hub, node, _build_travel_context())
	if bool(view_model.get("route_found", false)):
		message_label.text = "Rota encontrada. O painel é somente leitura nesta etapa; nenhum recurso foi gasto."
	else:
		message_label.text = "Local selecionado. A ligação a partir do hub atual ainda não está catalogada."

func _on_method_previewed(vehicle_id: String) -> void:
	message_label.text = "Prévia: %s. VT2 não inicia viagem nem altera o estado do mundo." % vehicle_id.replace("_", " ").capitalize()

func _build_travel_context() -> Dictionary:
	var flags: Dictionary = WorldState.story_flags.duplicate(true)
	var context := {
		"act": int(WorldState.act),
		"sombra": int(WorldState.get_reputation("sombra")),
		"lua_cheia": bool(flags.get("lua_cheia", false)),
		"weather": WorldDirectorManager.get_weather_for_hub(WorldMapManager.current_hub),
		"flags": flags,
		"route_unlocks": flags.get("route_unlocks", [])
	}
	var tide := str(flags.get("tide", flags.get("mare", "")))
	if tide != "":
		context["tide"] = tide
	return context

func _update_status() -> void:
	status_label.text = "Hub atual: %s\nR$ %d • Semana %d" % [WorldMapManager.current_hub, WorldState.money, WorldState.week]

func get_map_page_count() -> int:
	return life_layer.get_page_count()

func get_map_node_count() -> int:
	return life_layer.get_node_count()

func get_map_visual_contract() -> Dictionary:
	return life_layer.get_visual_contract()
