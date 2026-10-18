extends Control

const HUB_SCENE := "res://scenes/hubs/TerreiroDaLuta.tscn"

@onready var life_layer: Control = $WorldMapLifeLayer
@onready var status_label: Label = $HUD/LeftPanel/Status
@onready var message_label: Label = $HUD/LeftPanel/Message
@onready var detail_label: Label = $HUD/LeftPanel/Detail
@onready var page_label: Label = $HUD/LeftPanel/PageIndex

func _ready() -> void:
	_connect("HUD/RightPanel/Itubera", "itubera")
	# Legacy map page 10 remains inspectable as narrative reference;
	# Salvador is outside the playable Baixo Sul regional map.
	if has_node("HUD/RightPanel/Salvador"):
		$HUD/RightPanel/Salvador.disabled = true
		$HUD/RightPanel/Salvador.tooltip_text = "Referência narrativa externa • não é destino jogável do Baixo Sul."
	_connect("HUD/RightPanel/Zambiapunga", "zambiapunga")
	_connect("HUD/RightPanel/Camamu", "camamu_manguezal")
	$HUD/LeftPanel/Regional.pressed.connect(func(): life_layer.open_page("01"))
	$HUD/LeftPanel/PreviousPage.pressed.connect(_shift_page.bind(-1))
	$HUD/LeftPanel/NextPage.pressed.connect(_shift_page.bind(1))
	$HUD/RightPanel/Back.pressed.connect(func(): get_tree().change_scene_to_file(HUB_SCENE))
	life_layer.page_changed.connect(_on_page_changed)
	life_layer.node_focused.connect(_on_node_focused)
	_update_status()

func _connect(path: String, hub_id: String) -> void:
	if has_node(path):
		get_node(path).pressed.connect(_on_travel_pressed.bind(hub_id))

func _on_travel_pressed(hub_id: String) -> void:
	if hub_id not in ["itubera", "zambiapunga", "camamu_manguezal"]:
		message_label.text = "Fora do circuito regional jogável nesta etapa."
		return
	var result := WorldMapManager.travel_to(hub_id)
	message_label.text = str(result.get("message", ""))
	_update_status()
	if result.get("ok", false):
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file(str(result.get("hub", {}).get("entry_scene", HUB_SCENE)))

func _on_page_changed(page_id: String) -> void:
	message_label.text = "Página %s: %s. Toque em um emblema para detalhes." % [page_id, life_layer.get_page_name(page_id)]
	_update_status()

func _on_node_focused(node: Dictionary) -> void:
	var lock_text := "Disponível para descoberta"
	if node.has("lock"):
		lock_text = "Bloqueio: %s" % str(node.get("lock", {}).get("tipo", "progresso"))
	detail_label.text = "%s\n%s\n%s" % [str(node.get("nome", "Local")), str(node.get("tipo", "interesse")).capitalize(), lock_text]

func _shift_page(direction: int) -> void:
	var ids: Array = life_layer.call("get_page_ids")
	if ids.is_empty():
		return
	var current_index := ids.find(str(life_layer.active_page_id))
	var next_index := posmod(current_index + direction, ids.size())
	life_layer.open_page(str(ids[next_index]))

func _update_status() -> void:
	status_label.text = "Hub: %s\nR$ %d • Semana %d" % [WorldMapManager.current_hub, WorldState.money, WorldState.week]
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
