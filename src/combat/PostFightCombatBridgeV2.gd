class_name PostFightCombatBridgeV2
extends RefCounted

func enrich_result(
	base_result: Dictionary,
	action_log: Array,
	duration_sec: int,
	virada_used: bool
) -> Dictionary:
	var result := base_result.duplicate(true)
	var clips: Array = []
	var techniques_used: Array[String] = []
	for index in range(action_log.size()):
		if typeof(action_log[index]) != TYPE_DICTIONARY:
			continue
		var event: Dictionary = action_log[index]
		var technique_id := str(event.get("technique_id", event.get("t", "")))
		if technique_id == "":
			continue
		if not techniques_used.has(technique_id):
			techniques_used.append(technique_id)
		var quality := _clip_quality(event, index == action_log.size() - 1)
		clips.append({
			"technique_id": technique_id,
			"quality": quality,
			"moment": "climax" if index == action_log.size() - 1 else "exchange",
			"success": bool(event.get("success", event.get("ev", "") in ["hit", "counter", "score"]))
		})
	clips.sort_custom(_sort_clip)
	result["clips"] = clips
	result["best_clip"] = clips[0].duplicate(true) if not clips.is_empty() else {}
	result["duration"] = maxi(0, duration_sec)
	result["virada_used"] = virada_used
	result["techniques_used"] = techniques_used
	return result

func _clip_quality(event: Dictionary, is_last: bool) -> float:
	var quality := 0.45
	if bool(event.get("success", false)) or str(event.get("ev", "")) in ["hit", "counter", "score"]:
		quality += 0.18
	if str(event.get("ev", "")) == "counter" or bool(event.get("denied", false)):
		quality += 0.10
	if str(event.get("method", "")).find("submission") >= 0:
		quality += 0.12
	if is_last:
		quality += 0.10
	return clampf(quality, 0.0, 1.0)

func _sort_clip(a: Dictionary, b: Dictionary) -> bool:
	var qa := float(a.get("quality", 0.0))
	var qb := float(b.get("quality", 0.0))
	if not is_equal_approx(qa, qb):
		return qa > qb
	return str(a.get("technique_id", "")) < str(b.get("technique_id", ""))
