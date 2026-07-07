extends Node

var week := 1
var day_index := 0
var days := ["segunda", "terca", "quarta", "quinta", "sexta", "sabado", "domingo"]
var act := 1
var money := 0
var energy := 100
var player_id := "ruan_macacao"
var current_hub := "terreiro_da_luta"
var unlocked_skills := []
var completed_missions := []
var last_combat_result := {}
var reputation := {"honra": 0, "hype": 0, "sombra": 0, "legado": 0, "dupla_face": 0, "moral": 50}

func reset_new_game():
	week = 1
	day_index = 0
	act = 1
	money = 0
	energy = 100
	player_id = "ruan_macacao"
	current_hub = "terreiro_da_luta"
	unlocked_skills = []
	completed_missions = []
	last_combat_result = {}
	reputation = {"honra": 0, "hype": 0, "sombra": 0, "legado": 0, "dupla_face": 0, "moral": 50}

func to_dict():
	return {"week": week, "day_index": day_index, "act": act, "money": money, "energy": energy, "player_id": player_id, "current_hub": current_hub, "unlocked_skills": unlocked_skills, "completed_missions": completed_missions, "last_combat_result": last_combat_result, "reputation": reputation}

func load_from_dict(data):
	week = data.get("week", 1)
	day_index = data.get("day_index", 0)
	act = data.get("act", 1)
	money = data.get("money", 0)
	energy = data.get("energy", 100)
	player_id = data.get("player_id", "ruan_macacao")
	current_hub = data.get("current_hub", "terreiro_da_luta")
	unlocked_skills = data.get("unlocked_skills", [])
	completed_missions = data.get("completed_missions", [])
	last_combat_result = data.get("last_combat_result", {})
	reputation = data.get("reputation", reputation)
