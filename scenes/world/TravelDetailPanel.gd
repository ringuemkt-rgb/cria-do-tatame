extends PanelContainer
class_name TravelDetailPanel

signal method_previewed(vehicle_id: String)
signal travel_requested(destination_node: String, vehicle_id: String, world_context: Dictionary)
signal panel_closed

const ResolverScript = preload("res://src/world/WorldRouteResolver.gd")

const VEHICLE_LABELS := {
	"kombi_terreiro": "KOMBI DO TERREIRO",
	"moto_emprestada": "MOTO EMPRESTADA",
	"onibus_regional": "ÔNIBUS REGIONAL",
	"barco_ferry": "BARCO / FERRY",
	"a_pe": "A PÉ"
}

@onready var destination_label: Label = $Margin/VBox/Destination
@onready var route_label: Label = $Margin/VBox/Route
@onready var estimate_label: Label = $Margin/VBox/Estimate
@onready var context_label: Label = $Margin/VBox/Context
@onready var mastery_label: Label = $Margin/VBox/Mastery
@onready var gate_label: Label = $Margin/VBox/Gate
@onready var methods_box: VBoxContainer = $Margin/VBox/Methods
@onready var message_label: Label = $Margin/VBox/Message
@onready var start_button: Button = $Margin/VBox/Start
@onready var close_button: Button = $Margin/VBox/Close

var resolver = ResolverScript.new()
var selected_node: Dictionary = {}
var resolved_route: Dictionary = {}
var selected_method := ""
var last_world_context: Dictionary = {}
var last_view_model: Dictionary = {}

func _ready() -> void:
	var status: Dictionary = resolver.initialize()
	if not bool(status.get("ok", false)):
		message_label.text = "Planejamento indisponível: dados de rota não carregados."
	start_button.disabled = true
	start_button.pressed.connect(_on_start_pressed)
	close_button.pressed.connect(close_panel)
	visible = false

func present_node(origin_id: String, node: Dictionary, world_context: Dictionary = {}) -> Dictionary:
	selected_node = node.duplicate(true)
	selected_method = ""
	last_world_context = world_context.duplicate(true)
	resolved_route = {}
	visible = true
	start_button.disabled = true
	_clear_methods()

	var destination_id := str(node.get("id", ""))
	var destination_name := str(node.get("nome", node.get("name", destination_id)))
	destination_label.text = destination_name.to_upper()

	var result: Dictionary = resolver.resolve_route(origin_id, destination_id, world_context)
	if not bool(result.get("ok", false)):
		_show_unresolved(origin_id, destination_id, destination_name, str(result.get("error", "route_not_found")), world_context)
		return get_view_model()

	resolved_route = result.get("route", {}).duplicate(true)
	_render_route(destination_name, resolved_route, world_context)
	return get_view_model()

func close_panel() -> void:
	visible = false
	selected_method = ""
	start_button.disabled = true
	panel_closed.emit()

func get_view_model() -> Dictionary:
	return last_view_model.duplicate(true)

func _show_unresolved(origin_id: String, destination_id: String, destination_name: String, error_code: String, world_context: Dictionary) -> void:
	route_label.text = "ROTA NÃO CATALOGADA"
	estimate_label.text = "Tempo —  •  Custo —  •  Combustível —"
	context_label.text = _context_text(world_context)
	mastery_label.text = "Conhecimento da rota: desconhecido"
	gate_label.text = "Nenhuma viagem será iniciada por esta tela."
	message_label.text = "O local existe no mapa, mas ainda não há ligação data-driven entre a origem atual e este destino."
	start_button.disabled = true
	last_view_model = {
		"route_found": false,
		"origin": origin_id,
		"destination": destination_id,
		"destination_name": destination_name,
		"error": error_code,
		"method_options": [],
		"traversable": false,
		"read_only": true
	}

func _render_route(destination_name: String, route: Dictionary, world_context: Dictionary) -> void:
	var route_type := str(route.get("type", "desconhecida"))
	var subtype := str(route.get("subtype", ""))
	var type_label := route_type.capitalize()
	if subtype != "":
		type_label += " • " + subtype.capitalize()
	route_label.text = "%s  •  %s" % [type_label, str(route.get("id", "rota"))]

	var time_text := _format_time(int(route.get("base_time_minutes", 0)), bool(route.get("time_known", false)))
	var cost_text := _format_money(int(route.get("base_money_cost", 0)))
	var fuel_text := _format_fuel(float(route.get("base_fuel_cost", 0.0)))
	estimate_label.text = "Tempo %s  •  Custo %s  •  Combustível %s" % [time_text, cost_text, fuel_text]
	context_label.text = _context_text(world_context)

	var mastery := str(world_context.get("mastery", world_context.get("route_mastery", "unknown")))
	mastery_label.text = "Conhecimento da rota: %s" % _mastery_label(mastery)

	var traversable := bool(route.get("traversable", false))
	var reasons: Array = route.get("gate_status", {}).get("reasons", [])
	if traversable:
		gate_label.text = "ROTA LIBERADA • escolha um meio."
		message_label.text = "Selecione o meio. Só PREPARAR VIAGEM criará o TravelPlan; nada foi gasto ainda."
	else:
		gate_label.text = "ROTA BLOQUEADA • %s" % _reasons_text(reasons)
		message_label.text = "Os requisitos são mostrados antes de qualquer custo ou mudança de localização."

	var options: Array = route.get("method_options", [])
	for option_value in options:
		if typeof(option_value) != TYPE_DICTIONARY:
			continue
		_add_method_button(option_value, traversable)

	last_view_model = {
		"route_found": true,
		"origin": str(route.get("origin", "")),
		"destination": str(route.get("destination", "")),
		"destination_name": destination_name,
		"route_id": str(route.get("id", "")),
		"route_type": route_type,
		"route_subtype": subtype,
		"traversable": traversable,
		"gate_reasons": reasons.duplicate(true),
		"method_options": options.duplicate(true),
		"world_context_snapshot": route.get("world_context_snapshot", {}).duplicate(true),
		"read_only": true,
		"selected_method": selected_method
	}

func _add_method_button(option: Dictionary, traversable: bool) -> void:
	var vehicle_id := str(option.get("vehicle_id", ""))
	if vehicle_id == "":
		return
	var button := Button.new()
	button.name = "Method_%s" % vehicle_id
	button.text = str(VEHICLE_LABELS.get(vehicle_id, vehicle_id.replace("_", " ").to_upper()))
	button.custom_minimum_size = Vector2(0.0, 48.0)
	button.disabled = not traversable
	button.pressed.connect(_on_method_previewed.bind(vehicle_id, str(option.get("mode", "resolved_travel"))))
	methods_box.add_child(button)

func _on_method_previewed(vehicle_id: String, mode: String) -> void:
	selected_method = vehicle_id
	start_button.disabled = not bool(last_view_model.get("traversable", false))
	message_label.text = "%s selecionado • modo %s. Pressione PREPARAR VIAGEM para criar o plano." % [str(VEHICLE_LABELS.get(vehicle_id, vehicle_id)), mode]
	last_view_model["selected_method"] = vehicle_id
	method_previewed.emit(vehicle_id)

func _on_start_pressed() -> void:
	if selected_method == "" or not bool(last_view_model.get("traversable", false)):
		start_button.disabled = true
		return
	start_button.disabled = true
	travel_requested.emit(str(last_view_model.get("destination", "")), selected_method, last_world_context.duplicate(true))

func _clear_methods() -> void:
	for child in methods_box.get_children():
		methods_box.remove_child(child)
		child.queue_free()

func _context_text(world_context: Dictionary) -> String:
	var weather := str(world_context.get("weather", "n/d"))
	var tide := str(world_context.get("tide", world_context.get("mare", "n/d")))
	var act := int(world_context.get("act", world_context.get("ato", 0)))
	return "Clima %s  •  Maré %s  •  Ato %d" % [weather.replace("_", " ").capitalize(), tide.replace("_", " ").capitalize(), act]

func _format_time(minutes: int, known: bool) -> String:
	if not known or minutes <= 0:
		return "—"
	if minutes < 60:
		return "%d min" % minutes
	var hours := minutes / 60
	var rest := minutes % 60
	return "%dh%02d" % [hours, rest]

func _format_money(cost: int) -> String:
	return "R$ %d" % cost if cost > 0 else "—"

func _format_fuel(cost: float) -> String:
	return "%.1f" % cost if cost > 0.0 else "—"

func _mastery_label(value: String) -> String:
	match value:
		"known": return "CONHECIDA"
		"familiar": return "FAMILIAR"
		"mastered": return "DOMINADA"
	return "DESCONHECIDA"

func _reasons_text(reasons: Array) -> String:
	if reasons.is_empty():
		return "requisito pendente"
	var labels: Array[String] = []
	for reason_value in reasons:
		var reason := str(reason_value)
		match reason:
			"route_marked_blocked": labels.append("rota bloqueada")
			"tide_context_missing": labels.append("maré ainda não resolvida")
			"tide_gate_unsatisfied": labels.append("maré incompatível")
			"rota_101_requires_terrestrial_route": labels.append("ROTA 101 só funciona em terra")
			_:
				if reason.begins_with("gate_unsatisfied:"):
					labels.append("falta %s" % reason.trim_prefix("gate_unsatisfied:"))
				elif reason.begins_with("node_lock_unsatisfied:"):
					labels.append("falta %s" % reason.trim_prefix("node_lock_unsatisfied:"))
				elif reason.begins_with("node_lock_context_missing:"):
					labels.append("contexto ausente: %s" % reason.trim_prefix("node_lock_context_missing:"))
				elif reason.begins_with("node_lock_unsupported:"):
					labels.append("bloqueio ainda não suportado: %s" % reason.trim_prefix("node_lock_unsupported:"))
				else:
					labels.append(reason.replace("_", " "))
	return ", ".join(labels)
