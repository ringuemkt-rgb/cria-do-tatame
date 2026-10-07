extends RefCounted
class_name CriaLiveService
## Apresentação social. NÃO autoload. NÃO juiz de luta.

const CONTRACT := "res://data/social/crialive_v1.json"
const VIRAL := 1.5

var _rng := RandomNumberGenerator.new()

func score_post(clip_q: float, caption_fit: float, timing: float, novelty: float, fac: float, seed: int, week: int) -> float:
	_rng.seed = seed + week * 17
	var roll := 0.8 + _rng.randf() * 0.4
	return clip_q * caption_fit * timing * novelty * fac * roll

func is_viral(score: float) -> bool:
	return score > VIRAL

func purse(base: float, follower_tier_mult: float, rival_rank: float, hype: float) -> int:
	return int(base * follower_tier_mult * rival_rank * (1.0 + hype / 100.0))

func nemesis_should_learn(post_count_of_tech: int) -> bool:
	return post_count_of_tech >= 2
