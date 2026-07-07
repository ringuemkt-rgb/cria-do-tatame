extends Control

const HUB_SCENE := "res://scenes/hubs/TerreiroDaLuta.tscn"

func _ready() -> void:
	_connect("Panel/Itubera", "itubera")
	_connect("Panel/Salvador", "salvador")
	_connect("Panel/Zambiapunga", "zambiapunga")
	_connect("Panel/Camamu", "camamu_manguezal")
	if has_node("Panel/Back"):
		$Panel/Back.pressed.connect(func(): get_tree().change_scene_to_file(HUB_SCENE))
	_update_status()

func _connect(path: String, hub_id: String) -> void:
	if has_node(path):
		get_node(path).pressed.connect(_on_travel_pressed.bind(hub_id))

func _on_travel_pressed(hub_id: String) -> void:
	var result := WorldMapManager.travel_to(hub_id)
	if has_node("Panel/Message"):
		$Panel/Message.text = result.get("message", "")
	_update_status()
	if result.get("ok", false):
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file(str(result.get("hub", {}).get("entry_scene", HUB_SCENE)))

func _update_status() -> void:
	if has_node("Panel/Status"):
		$Panel/Status.text = "Hub atual: %s • R$ %d • Semana %d" % [WorldMapManager.current_hub, WorldState.money, WorldState.week]
