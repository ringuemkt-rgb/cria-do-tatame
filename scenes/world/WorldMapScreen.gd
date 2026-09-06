extends Control

const HUB_SCENE := "res://scenes/hubs/TerreiroDaLuta.tscn"

@onready var page_bar: HBoxContainer = $Root/PageBar
@onready var map_page: MapPage = $Root/Main/MapPage
@onready var hub_panel: HubPanel = $Root/Main/HubPanel
@onready var title_label: Label = $Root/TopBar/Title
@onready var status_label: Label = $Root/TopBar/Status
@onready var message_label: Label = $Root/Message

func _ready() -> void:
	map_page.map_node_selected.connect(_on_map_node_selected)
	map_page.page_anchor_selected.connect(_show_page)
	hub_panel.primary_action_requested.connect(_on_primary_action)
	$Root/TopBar/Back.pressed.connect(func(): get_tree().change_scene_to_file(HUB_SCENE))
	_build_page_bar()
	var initial_page := WorldMapManager.current_page
	if WorldMapManager.get_page(initial_page).is_empty():
		initial_page = "01"
	_show_page(initial_page)

func _build_page_bar() -> void:
	for child in page_bar.get_children():
		child.queue_free()
	for page_value in WorldMapManager.get_pages():
		var page: Dictionary = page_value
		var page_id := str(page.get("id", ""))
		var button := Button.new()
		button.text = page_id
		button.tooltip_text = str(page.get("nome", page_id))
		button.pressed.connect(_show_page.bind(page_id))
		page_bar.add_child(button)

func _show_page(page_id: String) -> void:
	if not WorldMapManager.set_page(page_id):
		message_label.text = "Página inexistente: " + page_id
		return
	var page := WorldMapManager.get_page(page_id)
	title_label.text = "MAPA %s/10 • %s" % [page_id, str(page.get("nome", ""))]
	status_label.text = "Hub: %s • R$ %d • Semana %d" % [WorldMapManager.current_hub, WorldState.money, WorldState.week]
	map_page.configure(
		page,
		WorldMapManager.get_page_anchors(page_id),
		WorldMapManager.get_page_nodes(page_id),
		WorldMapManager.get_page_evaluations(page_id)
	)
	hub_panel.clear_panel()
	message_label.text = "Selecione um nó. Locks são decididos pelo WorldMapManager."

func _on_map_node_selected(node_id: String) -> void:
	var result := WorldMapManager.select_map_node(node_id)
	if not bool(result.get("ok", false)):
		message_label.text = str(result.get("message", "Falha ao selecionar nó."))
		return
	var evaluation: Dictionary = result.get("evaluation", {})
	hub_panel.show_node(result.get("node", {}), result.get("panel", {}), evaluation)
	if bool(evaluation.get("unlocked", false)):
		message_label.text = "Nó disponível: " + str(result.get("node", {}).get("nome", node_id))
	else:
		message_label.text = str(evaluation.get("reason", "Bloqueado."))

func _on_primary_action(node_id: String) -> void:
	var result := WorldMapManager.select_map_node(node_id)
	if not bool(result.get("ok", false)):
		message_label.text = str(result.get("message", "Falha ao selecionar nó."))
		return
	var evaluation: Dictionary = result.get("evaluation", {})
	if not bool(evaluation.get("unlocked", false)):
		message_label.text = str(evaluation.get("reason", "Bloqueado."))
		return
	message_label.text = "Destino selecionado. Custo/tempo/maré e entrada end-to-end entram no EPIC 70."
