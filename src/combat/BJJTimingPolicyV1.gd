class_name BJJTimingPolicyV1
extends RefCounted

var config: Dictionary = {}

func _init(data: Dictionary = {}):
	config = data.duplicate(true)

func is_ready() -> bool:
	if config.is_empty():
		return false
	var tiers = config.get("tiers", {})
	var default_tier := str(config.get("default_tier", ""))
	return typeof(tiers) == TYPE_DICTIONARY and not default_tier.is_empty() and tiers.has(default_tier)

func default_tier() -> String:
	return str(config.get("default_tier", "standard"))

func window_ms_for(tier: String = "", input_profile: String = "touch") -> int:
	if not is_ready():
		return 0
	var resolved_tier := tier if not tier.is_empty() else default_tier()
	var tiers: Dictionary = config.get("tiers", {})
	var entry: Dictionary = tiers.get(resolved_tier, tiers.get(default_tier(), {}))
	var window_ms := maxi(0, int(entry.get("window_ms", 0)))
	if input_profile == "touch":
		var profiles: Dictionary = config.get("input_profiles", {})
		var touch: Dictionary = profiles.get("touch", {})
		window_ms = maxi(window_ms, int(touch.get("minimum_counter_window_ms", 250)))
	return window_ms

func telegraph_for(tier: String = "") -> String:
	if not is_ready():
		return ""
	var resolved_tier := tier if not tier.is_empty() else default_tier()
	var tiers: Dictionary = config.get("tiers", {})
	var entry: Dictionary = tiers.get(resolved_tier, tiers.get(default_tier(), {}))
	return str(entry.get("telegraph", ""))

func is_within_window(elapsed_ms: float, tier: String = "", input_profile: String = "touch") -> bool:
	if not is_ready():
		return true
	if elapsed_ms < 0.0:
		return false
	return elapsed_ms <= float(window_ms_for(tier, input_profile))

func metadata(tier: String = "", input_profile: String = "touch") -> Dictionary:
	var resolved_tier := tier if not tier.is_empty() else default_tier()
	return {
		"tier": resolved_tier,
		"window_ms": window_ms_for(resolved_tier, input_profile),
		"telegraph": telegraph_for(resolved_tier),
		"input_profile": input_profile
	}
