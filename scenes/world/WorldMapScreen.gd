extends Control

const HUB_SCENE := "res://scenes/hubs/TerreiroDaLuta.tscn"

func _ready() -> void:
	_connect("Navigation/Itubera", "itubera")
	_connect("Navigation/Salvador", "salvador")
	_connect("Navigation/Zambiapunga", "zambiapunga")
	_connect("Navigation/Camamu", "camamu_manguezal")
	$Navigation/Back.pressed.connect(func(): get_tree().change_scene_to_file(HUB_SCENE))
	_update_status()

func _connect(path: String, hub_id: String) -> void:
	if has_node(path):
		get_node(path).pressed.connect(_on_travel_pressed.bind(hub_id))

func _on_travel_pressed(hub_id: String) -> void:
	var result := WorldMapManager.travel_to(hub_id)
	$Message.text = result.get("message", "")
	_update_status()
	if result.get("ok", false):
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file(str(result.get("hub", {}).get("entry_scene", HUB_SCENE)))

func _update_status() -> void:
	$Message.text = "Hub atual: %s • R$ %d • Semana %d" % [WorldMapManager.current_hub, WorldState.money, WorldState.week]
