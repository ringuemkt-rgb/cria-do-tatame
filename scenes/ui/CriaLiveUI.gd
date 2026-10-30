extends Control

const HUB_SCENE := "res://scenes/hubs/TerreiroDaLuta.tscn"

func _ready() -> void:
	if has_node("Panel/Title"):
		$Panel/Title.text = "CRIA LIVE"
	if has_node("Panel/Back"):
		$Panel/Back.text = "VOLTAR AO TERREIRO"
		$Panel/Back.pressed.connect(_on_back_pressed)
	_update_feed()
	_complete_first_combat_post_milestone()

func _update_feed() -> void:
	if not has_node("Panel/Feed"):
		return
	var lines := []
	for post in CriaLiveManager.get_feed():
		lines.append("[%s] %s" % [post.get("tone", "post"), post.get("text", "")])
	$Panel/Feed.text = "\n".join(lines) if lines.size() > 0 else "Nenhuma postagem ainda. O tatame ainda esta silencioso."

func _complete_first_combat_post_milestone() -> void:
	if not GameFlowManager.has_flag("first_davi_combat_post_pending"):
		return
	var has_combat_post := false
	for post_value in CriaLiveManager.get_feed():
		if typeof(post_value) == TYPE_DICTIONARY and str(post_value.get("source_event", "")) == "combat_finished":
			has_combat_post = true
			break
	if not has_combat_post:
		return
	GameFlowManager.complete_step("primeiro_post_cria_live")
	GameFlowManager.mark_flag("first_davi_combat_post_pending", false)
	if not SaveManager.save_game(1):
		push_warning("[CriaLiveUI] Post exibido, mas o milestone nao foi salvo.")

func _on_back_pressed() -> void:
	if not SaveManager.save_game(1):
		push_warning("[CriaLiveUI] Falha ao salvar antes de voltar ao Terreiro.")
	get_tree().change_scene_to_file(HUB_SCENE)
