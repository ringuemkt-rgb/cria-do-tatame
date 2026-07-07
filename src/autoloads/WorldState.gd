extends Node

var week := 1
var current_week := 1
var day_index := 0
var days := ["segunda", "terca", "quarta", "quinta", "sexta", "sabado", "domingo"]
var current_day := "segunda"
var act := 1
var current_act := 1
var belt := "branca"
var current_belt := "branca"
var money := 0
var energy := 100.0
var strain_level := 0
var injury_level := 0
var player_id := "ruan_macacao"
var campaign_id := "ruan_macacao"
var current_hub := "terreiro_da_luta"
var skill_points := 0
var fights_won := 0
var fights_lost := 0
var technical_finishes := 0
var submissions_landed := 0
var unlocked_skills := []
var completed_missions := []
var techniques_learned := []
var active_sponsors := []
var story_flags := {}
var last_combat_result := {}
var reputation := {"honra": 50.0, "hype": 30.0, "sombra": 0.0, "legado": 20.0, "dupla_face": 0.0, "moral": 50.0, "raiz": 20.0}

var id_campanha := "ruan_macacao"
var ato_atual := 1
var faixa_atual := "branca"
var semana_atual := 1
var dia_atual := "segunda"
var dinheiro := 0
var energia := 100.0
var nivel_lesao := 0
var habilidades_desbloqueadas := []
var pontos_habilidade := 0
var tecnicas_aprendidas := []
var lutas_vencidas := 0
var lutas_perdidas := 0
var finalizacoes_conectadas := 0
var sponsors_ativos := []
var flags_historia := {}

func _sync_aliases() -> void:
	current_week = week
	current_day = days[day_index]
	current_act = act
	current_belt = belt
	injury_level = strain_level
	campaign_id = player_id
	id_campanha = player_id
	ato_atual = act
	faixa_atual = belt
	semana_atual = week
	dia_atual = current_day
	dinheiro = money
	energia = energy
	nivel_lesao = strain_level
	habilidades_desbloqueadas = unlocked_skills
	pontos_habilidade = skill_points
	tecnicas_aprendidas = techniques_learned
	lutas_vencidas = fights_won
	lutas_perdidas = fights_lost
	finalizacoes_conectadas = technical_finishes
	sponsors_ativos = active_sponsors
	flags_historia = story_flags

func _apply_ptbr_aliases() -> void:
	player_id = id_campanha
	act = ato_atual
	belt = faixa_atual
	week = semana_atual
	day_index = days.find(dia_atual)
	if day_index < 0:
		day_index = 0
	money = dinheiro
	energy = energia
	strain_level = nivel_lesao
	unlocked_skills = habilidades_desbloqueadas
	skill_points = pontos_habilidade
	techniques_learned = tecnicas_aprendidas
	fights_won = lutas_vencidas
	fights_lost = lutas_perdidas
	technical_finishes = finalizacoes_conectadas
	active_sponsors = sponsors_ativos
	story_flags = flags_historia
	_sync_aliases()

func reset_new_game():
	week = 1
	day_index = 0
	act = 1
	belt = "branca"
	money = 0
	energy = 100.0
	strain_level = 0
	player_id = "ruan_macacao"
	current_hub = "terreiro_da_luta"
	skill_points = 0
	fights_won = 0
	fights_lost = 0
	technical_finishes = 0
	submissions_landed = 0
	unlocked_skills = []
	completed_missions = []
	techniques_learned = []	
	active_sponsors = []
	story_flags = {}
	last_combat_result = {}
	reputation = {"honra": 50.0, "hype": 30.0, "sombra": 0.0, "legado": 20.0, "dupla_face": 0.0, "moral": 50.0, "raiz": 20.0}
	if has_node("/root/TinkerBondManager"):
		TinkerBondManager.reset()
	_sync_aliases()

func advance_day():
	day_index += 1
	if day_index >= days.size():
		day_index = 0
		week += 1
		SignalBus.week_completed.emit(week - 1)
	energy = min(100.0, energy + 15.0)
	if strain_level > 0:
		strain_level -= 1
	_sync_aliases()
	SignalBus.day_advanced.emit(days[day_index], week)
	if SignalBus.has_signal("dia_avancou"):
		SignalBus.dia_avancou.emit(StringName(days[day_index]), week)

func avancar_dia() -> void:
	_apply_ptbr_aliases()
	advance_day()

func modify_reputation(axis, delta: float) -> void:
	var key := str(axis)
	if not reputation.has(key):
		reputation[key] = 0.0
	reputation[key] = clamp(float(reputation[key]) + delta, 0.0, 100.0)
	SignalBus.reputation_changed.emit(key, delta, reputation[key])
	if SignalBus.has_signal("reputacao_mudou"):
		SignalBus.reputacao_mudou.emit(StringName(key), delta, float(reputation[key]))

func modificar_reputacao(eixo, delta: float) -> void:
	modify_reputation(eixo, delta)

func get_reputation(axis) -> float:
	return float(reputation.get(str(axis), 0.0))

func obter_reputacao(eixo) -> float:
	return get_reputation(eixo)

func determine_final():
	var honra = get_reputation("honra")
	var hype = get_reputation("hype")
	var sombra = get_reputation("sombra")
	var legado = get_reputation("legado")
	var moral = get_reputation("moral")
	var raiz = get_reputation("raiz")
	var tinker_state = TinkerBondManager.get_state() if has_node("/root/TinkerBondManager") else "IRMANDADE"
	if honra >= 70.0 and legado >= 70.0 and raiz >= 70.0 and tinker_state == "LEGADO":
		return "raiz_eterna"
	if sombra >= 70.0 and moral < 40.0 and tinker_state == "RUPTURA":
		return "rei_dos_atalhos"
	if hype >= 60.0 and sombra >= 60.0 and tinker_state == "RETORNO_DIFICIL":
		return "traidor_silencioso"
	if hype >= 70.0 and honra < 50.0 and tinker_state in ["AFASTAMENTO", "RUPTURA"]:
		return "estrela_vazia"
	if honra >= 70.0 and legado >= 70.0 and sombra < 30.0 and tinker_state in ["IRMANDADE", "LEGADO", "ALERTA"]:
		return "heroi_duas_aguas"
	return "heroi_duas_aguas"

func determinar_final():
	return determine_final()

func to_dict():
	_sync_aliases()
	return {"week": week, "current_week": current_week, "day_index": day_index, "current_day": current_day, "act": act, "current_act": current_act, "belt": belt, "current_belt": current_belt, "money": money, "energy": energy, "strain_level": strain_level, "injury_level": injury_level, "player_id": player_id, "campaign_id": campaign_id, "current_hub": current_hub, "skill_points": skill_points, "fights_won": fights_won, "fights_lost": fights_lost, "technical_finishes": technical_finishes, "submissions_landed": submissions_landed, "unlocked_skills": unlocked_skills, "completed_missions": completed_missions, "techniques_learned": techniques_learned, "active_sponsors": active_sponsors, "story_flags": story_flags, "last_combat_result": last_combat_result, "reputation": reputation, "final_preview": determine_final()}

func load_from_dict(data):
	week = data.get("week", data.get("current_week", 1))
	current_day = data.get("current_day", "segunda")
	day_index = data.get("day_index", days.find(current_day))
	if day_index < 0:
		day_index = 0
	act = data.get("act", data.get("current_act", 1))
	belt = data.get("belt", data.get("current_belt", "branca"))
	money = data.get("money", 0)
	energy = data.get("energy", 100.0)
	strain_level = data.get("strain_level", data.get("injury_level", 0))
	player_id = data.get("player_id", data.get("campaign_id", "ruan_macacao"))
	current_hub = data.get("current_hub", "terreiro_da_luta")
	skill_points = data.get("skill_points", 0)
	fights_won = data.get("fights_won", 0)
	fights_lost = data.get("fights_lost", 0)
	technical_finishes = data.get("technical_finishes", data.get("submissions_landed", 0))
	submissions_landed = data.get("submissions_landed", technical_finishes)
	unlocked_skills = data.get("unlocked_skills", [])
	completed_missions = data.get("completed_missions", [])
	techniques_learned = data.get("techniques_learned", [])
	active_sponsors = data.get("active_sponsors", [])
	story_flags = data.get("story_flags", {})
	last_combat_result = data.get("last_combat_result", {})
	reputation = data.get("reputation", reputation)
	if not reputation.has("raiz"):
		reputation["raiz"] = 20.0
	_sync_aliases()
