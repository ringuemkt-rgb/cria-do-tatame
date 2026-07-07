extends Control

const HUB_SCENE := "res://scenes/hubs/TerreiroDaLuta.tscn"

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.name = "VBox"
	root.anchor_left = 0.35
	root.anchor_right = 0.65
	root.anchor_top = 0.28
	root.anchor_bottom = 0.72
	root.add_theme_constant_override("separation", 16)
	add_child(root)

	var titulo := Label.new()
	titulo.text = "CRIA DO TATAME"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(titulo)

	var novo := _button("NOVO JOGO")
	var continuar := _button("CONTINUAR")
	var opcoes := _button("CONFIGURACOES")
	var sair := _button("SAIR")
	root.add_child(novo)
	root.add_child(continuar)
	root.add_child(opcoes)
	root.add_child(sair)

	continuar.disabled = not SaveManager.has_save(1)
	novo.pressed.connect(_ao_novo_jogo)
	continuar.pressed.connect(_ao_continuar)
	opcoes.pressed.connect(_ao_opcoes)
	sair.pressed.connect(_ao_sair)

func _button(texto: String) -> Button:
	var botao := Button.new()
	botao.text = texto
	botao.custom_minimum_size = Vector2(320, 64)
	return botao

func _ao_novo_jogo() -> void:
	WorldState.reset_new_game()
	if has_node("/root/GameFlowManager"):
		GameFlowManager.start_new_run()
	SaveManager.save_game(1)
	get_tree().change_scene_to_file(HUB_SCENE)

func _ao_continuar() -> void:
	if SaveManager.has_save(1):
		SaveManager.load_game(1)
	else:
		WorldState.reset_new_game()
	get_tree().change_scene_to_file(HUB_SCENE)

func _ao_opcoes() -> void:
	print("[Menu] Configuracoes entram na proxima sprint.")

func _ao_sair() -> void:
	get_tree().quit()
