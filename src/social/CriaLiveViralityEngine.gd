class_name CriaLiveViralityEngine
extends RefCounted

var config: Dictionary = {}

func _init(config_data: Dictionary = {}) -> void:
	config = config_data.duplicate(true)

func score_post(post: Dictionary, profile: Dictionary, context: Dictionary) -> Dictionary:
	var tone_id := str(post.get("tone", "humilde"))
	var tone_rules: Dictionary = config.get("tone_rules", {}).get(tone_id, {})
	var viral_cfg: Dictionary = config.get("virality", {})
	var clip_quality := clampf(float(post.get("clip_quality", 0.5)), 0.0, 1.0)
	var caption_fit := float(tone_rules.get("caption_fit", 1.0))
	var timing := maxf(0.1, float(context.get("trend_bonus", 1.0)))
	var novelty := _novelty(post, context)
	var faction_align := clampf(float(context.get("faction_align", 1.0)), 0.5, 1.5)
	var roll := _seeded_roll(
		int(context.get("seed", 0)),
		int(context.get("week", 0)),
		str(post.get("id", "post"))
	)
	var score := clip_quality * caption_fit * timing * novelty * faction_align * roll
	var followers := maxi(0, int(profile.get("followers", 0)))
	var engagement_rate := float(viral_cfg.get("base_engagement_rate", 0.16))
	var likes := maxi(0, int(round((12.0 + float(followers) * engagement_rate) * score)))
	return {
		"score": score,
		"clip_quality": clip_quality,
		"caption_fit": caption_fit,
		"timing": timing,
		"novelty": novelty,
		"faction_align": faction_align,
		"roll": roll,
		"likes": likes,
		"viral": score >= float(viral_cfg.get("viral_threshold", 1.5))
	}

func _novelty(post: Dictionary, context: Dictionary) -> float:
	var viral_cfg: Dictionary = config.get("virality", {})
	var repeated := bool(context.get("clip_seen_before", false))
	if repeated:
		return float(viral_cfg.get("novelty_repeat", 0.78))
	return float(viral_cfg.get("novelty_first", 1.20))

func _seeded_roll(seed_value: int, week: int, salt: String) -> float:
	var viral_cfg: Dictionary = config.get("virality", {})
	var rng := RandomNumberGenerator.new()
	rng.seed = _stable_seed("%d|%d|%s" % [seed_value, week, salt])
	return rng.randf_range(
		float(viral_cfg.get("roll_min", 0.8)),
		float(viral_cfg.get("roll_max", 1.2))
	)

func _stable_seed(text: String) -> int:
	var value: int = 2166136261
	for index in range(text.length()):
		value = int((value ^ text.unicode_at(index)) * 16777619) & 0x7fffffff
	return maxi(1, value)
