class_name HubPanel
extends VBoxContainer

signal primary_action_requested(node_id: String)

var _node_id := ""
var _title: Label
var _type_line: Label
var _description: Label
var _ecosystem: Label
var _services: Label
var _characters: Label
var _lock_line: Label
var _action: Button

func _ready() -> void:
	_title = Label.new()
	_title.text = "HUB SELECIONADO"
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_title)

	_type_line = Label.new()
	add_child(_type_line)

	_description = Label.new()
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_description)

	_ecosystem = Label.new()
	_ecosystem.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_ecosystem)

	_services = Label.new()
	_services.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_services)

	_characters = Label.new()
	_characters.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_characters)

	_lock_line = Label.new()
	_lock_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_lock_line)

	_action = Button.new()
	_action.text = "SELECIONAR"
	_action.disabled = true
	_action.pressed.connect(func(): primary_action_requested.emit(_node_id))
	add_child(_action)

func show_node(node: Dictionary, panel: Dictionary, evaluation: Dictionary) -> void:
	_node_id = str(node.get("id", ""))
	_title.text = str(panel.get("nome", node.get("nome", _node_id)))
	_type_line.text = "%s • %s" % [str(node.get("tipo", "")), str(node.get("mun", ""))]
	_description.text = str(panel.get("descricao", ""))
	_ecosystem.text = "ECOSSISTEMA: " + str(panel.get("ecossistema", ""))
	_services.text = "SERVIÇOS: " + ", ".join(panel.get("servicos", []))
	_characters.text = "PRESENTES: " + (", ".join(panel.get("personagens", [])) if not panel.get("personagens", []).is_empty() else "—")
	var unlocked := bool(evaluation.get("unlocked", false))
	_lock_line.text = "" if unlocked else str(evaluation.get("reason", panel.get("lock", "Bloqueado")))
	_action.text = "SELECIONAR" if unlocked else "BLOQUEADO"
	_action.disabled = not unlocked

func clear_panel() -> void:
	_node_id = ""
	if not is_node_ready():
		return
	_title.text = "HUB SELECIONADO"
	_type_line.text = ""
	_description.text = "Selecione um nó do mapa."
	_ecosystem.text = ""
	_services.text = ""
	_characters.text = ""
	_lock_line.text = ""
	_action.text = "SELECIONAR"
	_action.disabled = true
