extends Node

var week := 1
var day_index := 0
var days := ["segunda", "terca", "quarta", "quinta", "sexta", "sabado", "domingo"]
var act := 1
var belt := "branca"
var money := 0
var energy := 100.0
var strain_level := 0
var player_id := "ruan_macacao"
var current_hub := "terreiro_da_luta"
var skill_points := 0
var fights_won := 0
var fights_lost := 0
var technical_finishes := 0
var unlocked_skills := []
var completed_missions := []
var techniques_learned := []
var active_sponsors := []
var story_flags := {}
var last_combat_result := {}
var reputation := {"honra": 50.0, "hype": 30.0, "sombra": 0.0, "legado": 20.0, "dupla_face": 0.0, "moral": 50.0}

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
	unlocked_skills = []
	completed_missions = []
	techniques_learned = []
	active_sponsors = []
	story_flags = {}
	last_combat_result = {}
	reputation = {"honra": 50.0, "hype": 30.0, "sombra": 0.0, "legado": 20.0, "dupla_face": 0.0, "moral": 50.0}

func advance_day():
	day_index += 1
	if day_index >= days.size():
		day_index = 0
		week += 1
		SignalBus.week_completed.emit(week - 1)
	energy = min(100.0, energy + 15.0)
	if strain_level > 0:
		strain_level -= 1
	SignalBus.day_advanced.emit(days[day_index], week)

func modify_reputation(axis, delta: float) -> void:
	var key := str(axis)
	if not reputation.has(key):
		return
	reputation[key] = clamp(float(reputation[key]) + delta, 0.0, 100.0)
	SignalBus.reputation_changed.emit(key, delta, reputation[key])

func get_reputation(axis) -> float:
	return float(reputation.get(str(axis), 0.0))

func to_dict():
	return {"week": week, "day_index": day_index, "act": act, "belt": belt, "money": money, "energy": energy, "strain_level": strain_level, "player_id": player_id, "current_hub": current_hub, "skill_points": skill_points, "fights_won": fights_won, "fights_lost": fights_lost, "technical_finishes": technical_finishes, "unlocked_skills": unlocked_skills, "completed_missions": completed_missions, "techniques_learned": techniques_learned, "active_sponsors": active_sponsors, "story_flags": story_flags, "last_combat_result": last_combat_result, "reputation": reputation}

func load_from_dict(data):
	week = data.get("week", 1)
	day_index = data.get("day_index", 0)
	act = data.get("act", 1)
	belt = data.get("belt", "branca")
	money = data.get("money", 0)
	energy = data.get("energy", 100.0)
	strain_level = data.get("strain_level", 0)
	player_id = data.get("player_id", "ruan_macacao")
	current_hub = data.get("current_hub", "terreiro_da_luta")
	skill_points = data.get("skill_points", 0)
	fights_won = data.get("fights_won", 0)
	fights_lost = data.get("fights_lost", 0)
	technical_finishes = data.get("technical_finishes", 0)
	unlocked_skills = data.get("unlocked_skills", [])
	completed_missions = data.get("completed_missions", [])
	techniques_learned = data.get("techniques_learned", [])
	active_sponsors = data.get("active_sponsors", [])
	story_flags = data.get("story_flags", {})
	last_combat_result = data.get("last_combat_result", {})
	reputation = data.get("reputation", reputation)
