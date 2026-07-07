extends Node

var posts: Array = []

func create_post(text: String, tone: String, author := "cria_live"):
	var post = {
		"author": author,
		"tone": tone,
		"text": text,
		"week": WorldState.week,
		"day": WorldState.days[WorldState.day_index]
	}
	posts.append(post)
	SignalBus.cria_live_post_created.emit(post)
	return post

func post_match_result(result: Dictionary):
	if result.get("winner", "") == WorldState.player_id:
		create_post("Macacão venceu. O tatame inteiro sentiu a pressão.", "hype", "cria_live")
	else:
		create_post("Hoje o chão ensinou. Amanhã o treino cobra.", "aprendizado", "mestre_dende")
