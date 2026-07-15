extends Node

const MENU_PRINCIPAL := "res://scenes/main_menu/MainMenu.tscn"

func _ready() -> void:
	print("[Boot] Inicializando Cria do Tatame...")
	if SaveManager.has_save(1):
		if SaveManager.load_game(1):
			print("[Boot] Save carregado.")
		else:
			WorldState.reset_new_game()
			GameFlowManager.start_new_run()
			push_warning("[Boot] Save invalido; nova campanha preparada.")
	else:
		WorldState.reset_new_game()
		GameFlowManager.start_new_run()
		print("[Boot] Nova campanha preparada.")
	await get_tree().create_timer(0.20).timeout
	var error := get_tree().change_scene_to_file(MENU_PRINCIPAL)
	if error != OK:
		push_error("[Boot] Falha ao abrir menu principal: %s" % error_string(error))
