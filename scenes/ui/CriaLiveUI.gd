extends Control

const HUB_SCENE := "res://scenes/hubs/TerreiroDaLuta.tscn"

func _ready() -> void:
	if has_node("Panel/Title"):
		$Panel/Title.text = "CRIA LIVE"
	if has_node("Panel/Back"):
		$Panel/Back.text = "VOLTAR AO TERREIRO"
		$Panel/Back.pressed.connect(_on_back_pressed)
	if has_node("/root/CriaLiveInteractionManager"):
		CriaLiveInteractionManager.ensure_v1_seed_content()
	_update_feed()
	_complete_first_combat_post_milestone()

func _update_feed() -> void:
	if not has_node("Panel/Feed"):
		return
	var lines: Array = []
	if has_node("/root/CriaLiveInteractionManager"):
		var social_state: Dictionary = CriaLiveInteractionManager.get_v1_state()
		var profile: Dictionary = social_state.get("profile", {})
		lines.append("@ruanmacacao  |  %d seguidores  |  hype %d" % [
			int(profile.get("followers", 0)),
			int(round(float(profile.get("hype", 0.0))))
		])
		lines.append("")
		for card_value in CriaLiveInteractionManager.get_v1_feed():
			if typeof(card_value) != TYPE_DICTIONARY:
				continue
			var card: Dictionary = card_value
			var payload: Dictionary = card.get("payload", {})
			if str(card.get("kind", "")) == "proposal":
				lines.append("DESAFIO · %s · %s · purse %d" % [
					str(payload.get("challenger", "rival")),
					str(payload.get("venue", "arena")),
					int(payload.get("purse", 0))
				])
			else:
				lines.append("[%s] %s  ♥ %d" % [
					str(payload.get("tone", "post")),
					str(payload.get("caption", payload.get("text", ""))),
					int(payload.get("likes", 0))
				])
	if lines.size() <= 2:
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
