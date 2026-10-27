extends Control

const HUB_SCENE := "res://scenes/hubs/TerreiroDaLuta.tscn"

# Lock before the world mutation: repeated Android taps must not charge twice.
var _travel_pending := false

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
