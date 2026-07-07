extends Control

const HUB_SCENE := "res://scenes/hubs/TerreiroDaLuta.tscn"
const CRIA_LIVE_SCENE := "res://scenes/ui/CriaLiveUI.tscn"

var result_label: Label
var detail_label: Label

func _ready() -> void:
	_build_runtime_ui_if_needed()
	_update_result()

func _build_runtime_ui_if_needed() -> void:
	if has_node("Panel"):
		if has_node("Panel/BackToHub"):
			$Panel/BackToHub.pressed.connect(_on_back_pressed)
		return
	var panel := VBoxContainer.new()
	panel.name = "Panel"
	panel.anchor_left = 0.25
	panel.anchor_right = 0.75
	panel.anchor_top = 0.2
	panel.anchor_bottom = 0.8
	panel.add_theme_constant_override("separation", 14)
	add_child(panel)
	result_label = Label.new()
	result_label.name = "Result"
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(result_label)
	detail_label = Label.new()
	detail_label.name = "Details"
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(detail_label)
	var cria := Button.new()
	cria.text = "POSTAR NO CRIA LIVE"
	cria.custom_minimum_size = Vector2(360, 58)
	cria.pressed.connect(_on_cria_live_pressed)
	panel.add_child(cria)
	var back := Button.new()
	back.name = "BackToHub"
	back.text = "VOLTAR AO TERREIRO"
	back.custom_minimum_size = Vector2(360, 58)
	back.pressed.connect(_on_back_pressed)
	panel.add_child(back)

func _update_result() -> void:
	var data: Dictionary = WorldState.last_combat_result
	var winner := str(data.get("winner", ""))
	var won := winner == "ruan_macacao"
	var title := "VITORIA" if won else "DERROTA"
	if has_node("Panel/Result"):
		get_node("Panel/Result").text = "%s - %s" % [title, str(data.get("method", "controle"))]
	if has_node("Panel/Details"):
		get_node("Panel/Details").text = "A luta terminou. O resultado altera reputacao, energia, historico e o proximo post no Cria Live."

func _on_cria_live_pressed() -> void:
	var won := str(WorldState.last_combat_result.get("winner", "")) == "ruan_macacao"
	var post := {
		"type": "vitoria_luta" if won else "derrota_respeitosa",
		"caption_tone": "humilde",
		"media": "resultado_luta",
		"source": "result_screen"
	}
	if has_node("/root/CriaLiveManager") and CriaLiveManager.has_method("publish_post"):
		CriaLiveManager.publish_post(post.get("type", "vitoria_luta"), post.get("caption_tone", "humilde"), post.get("media", "resultado_luta"))
	SaveManager.save_game(1)
	get_tree().change_scene_to_file(CRIA_LIVE_SCENE)

func _on_back_pressed() -> void:
	CareerLoop.advance_day()
	SaveManager.save_game(1)
	get_tree().change_scene_to_file(HUB_SCENE)
