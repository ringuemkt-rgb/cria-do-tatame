extends Node

const MENU_PRINCIPAL := "res://scenes/main_menu.tscn"

func _ready() -> void:
	print("[Boot] Inicializando Cria do Tatame...")
	if SaveManager.has_save(1):
		SaveManager.load_game(1)
		print("[Boot] Save carregado.")
	else:
		WorldState.reset_new_game()
		print("[Boot] Nova campanha preparada.")
	await get_tree().create_timer(0.35).timeout
	get_tree().change_scene_to_file(MENU_PRINCIPAL)
