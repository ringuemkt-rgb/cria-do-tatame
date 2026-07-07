extends Control

const HUB_SCENE := "res://scenes/hubs/TerreiroDaLuta.tscn"

func _ready() -> void:
	if has_node("Panel/Title"):
		$Panel/Title.text = "CRIA LIVE"
	if has_node("Panel/Back"):
		$Panel/Back.text = "VOLTAR AO TERREIRO"
		$Panel/Back.pressed.connect(_on_back_pressed)
	_update_feed()

func _update_feed() -> void:
	if not has_node("Panel/Feed"):
		return
	var lines := []
	for post in CriaLiveManager.get_feed():
		lines.append("[%s] %s" % [post.get("tone", "post"), post.get("text", "")])
	$Panel/Feed.text = "\n".join(lines) if lines.size() > 0 else "Nenhuma postagem ainda. O tatame ainda esta silencioso."

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(HUB_SCENE)
