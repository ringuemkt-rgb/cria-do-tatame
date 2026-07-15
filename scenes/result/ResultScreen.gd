extends Control

const HUB_SCENE := "res://scenes/hubs/TerreiroDaLuta.tscn"
const CRIA_LIVE_SCENE := "res://scenes/ui/CriaLiveUI.tscn"

var _leaving := false
var _progression_committed := false

func _ready() -> void:
	_connect_buttons()
	_update_result()

func _connect_buttons() -> void:
	if has_node("Panel/BackToHub"):
		var back_button: Button = $Panel/BackToHub
		if not back_button.pressed.is_connected(_on_back_pressed):
			back_button.pressed.connect(_on_back_pressed)
	if has_node("Panel/CriaLive"):
		var cria_button: Button = $Panel/CriaLive
		if not cria_button.pressed.is_connected(_on_cria_live_pressed):
			cria_button.pressed.connect(_on_cria_live_pressed)

func _update_result() -> void:
	var data: Dictionary = WorldState.last_combat_result
	var winner := str(data.get("winner", ""))
	var won := winner == WorldState.player_id
	var title := "VITORIA" if won else "DERROTA"
	var method := _humanize_method(str(data.get("method", "controle_posicional")))
	if has_node("Panel/Result"):
		$Panel/Result.text = "%s • %s" % [title, method]
	if has_node("Panel/Details"):
		var final_state := str(data.get("final_state", "RESET")).replace("_", " ")
		$Panel/Details.text = "O combate terminou por %s. Estado final: %s." % [method.to_lower(), final_state]
	if has_node("Panel/Reward"):
		if won:
			$Panel/Reward.text = "+ R$ 200 • Honra +5 • Hype +3 • Vitorias: %d" % WorldState.fights_won
		else:
			$Panel/Reward.text = "Honra -3 • Hype -2 • Derrotas: %d" % WorldState.fights_lost
	if has_node("Panel/CriaLive"):
		$Panel/CriaLive.disabled = data.is_empty()

func _humanize_method(method: String) -> String:
	match method:
		"controle_posicional": return "Controle Posicional"
		"encerramento_tecnico": return "Encerramento Tecnico"
		"mata_leao": return "Mata-leao com tap"
		"chave_braco": return "Chave de braco com tap"
		"triangulo": return "Triangulo com tap"
		"cansaco": return "Cansaco"
	return method.replace("_", " ").capitalize()

func _commit_post_combat_progression() -> void:
	if _progression_committed:
		return
	_progression_committed = true
	CareerLoop.advance_day()
	if not SaveManager.save_game(1):
		push_warning("[ResultScreen] O dia avancou, mas o save pos-combate falhou.")

func _on_cria_live_pressed() -> void:
	if _leaving:
		return
	_leaving = true
	# A postagem da luta e criada pelo CriaLiveManager ao receber combat_finished.
	# Aqui apenas consolidamos o calendario e abrimos o feed.
	_commit_post_combat_progression()
	var error := get_tree().change_scene_to_file(CRIA_LIVE_SCENE)
	if error != OK:
		_leaving = false
		push_error("[ResultScreen] Falha ao abrir Cria Live: %s" % error_string(error))

func _on_back_pressed() -> void:
	if _leaving:
		return
	_leaving = true
	_commit_post_combat_progression()
	var error := get_tree().change_scene_to_file(HUB_SCENE)
	if error != OK:
		_leaving = false
		push_error("[ResultScreen] Falha ao voltar ao Terreiro: %s" % error_string(error))
