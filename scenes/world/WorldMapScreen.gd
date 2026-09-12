extends Control

const HUB_SCENE := "res://scenes/hubs/TerreiroDaLuta.tscn"

@onready var life_layer: Control = $WorldMapLifeLayer
@onready var status_label: Label = $HUD/LeftPanel/Status
@onready var message_label: Label = $HUD/LeftPanel/Message
@onready var detail_label: Label = $HUD/LeftPanel/Detail

func _ready() -> void:
	_connect("HUD/RightPanel/Itubera", "itubera")
	_connect("HUD/RightPanel/Salvador", "salvador")
	_connect("HUD/RightPanel/Zambiapunga", "zambiapunga")
	_connect("HUD/RightPanel/Camamu", "camamu_manguezal")
	$HUD/LeftPanel/Regional.pressed.connect(func(): life_layer.open_page("01"))
	$HUD/RightPanel/Back.pressed.connect(func(): get_tree().change_scene_to_file(HUB_SCENE))
	life_layer.page_changed.connect(_on_page_changed)
	life_layer.node_focused.connect(_on_node_focused)
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
	message_label.text = "Página %s aberta. Toque em um emblema para ler o estado do local." % page_id

func _on_node_focused(node: Dictionary) -> void:
	var lock_text := "Disponível para descoberta"
	if node.has("lock"):
		lock_text = "Bloqueio: %s" % str(node.get("lock", {}).get("tipo", "progresso"))
	detail_label.text = "%s\n%s\n%s" % [str(node.get("nome", "Local")), str(node.get("tipo", "interesse")).capitalize(), lock_text]

func _update_status() -> void:
	status_label.text = "Hub atual: %s\nR$ %d • Semana %d" % [WorldMapManager.current_hub, WorldState.money, WorldState.week]

func get_map_page_count() -> int:
	return life_layer.get_page_count()

func get_map_node_count() -> int:
	return life_layer.get_node_count()

func get_map_visual_contract() -> Dictionary:
	return life_layer.get_visual_contract()
