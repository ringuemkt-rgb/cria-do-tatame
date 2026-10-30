class_name CriaLivePostComposer
extends RefCounted

var config: Dictionary = {}

func _init(config_data: Dictionary = {}) -> void:
	config = config_data.duplicate(true)

func compose(state: Dictionary, request: Dictionary, context: Dictionary) -> Dictionary:
	var post_type := str(request.get("type", ""))
	var tone := str(request.get("tone", ""))
	if post_type not in config.get("post_types", []):
		return {"ok": false, "error": "invalid_post_type"}
	if not config.get("tone_rules", {}).has(tone):
		return {"ok": false, "error": "invalid_tone"}
	var sequence := maxi(1, int(state.get("next_post_sequence", 1)))
	var clip_ref := str(request.get("clip_ref", ""))
	if post_type == "clip_luta" and clip_ref == "":
		return {"ok": false, "error": "clip_ref_required"}
	var post := {
		"id": "clp_%05d" % sequence,
		"type": post_type,
		"tone": tone,
		"caption": str(request.get("caption", "")).left(280),
		"clip_ref": clip_ref,
		"technique_id": str(request.get("technique_id", "")),
		"clip_quality": clampf(float(request.get("clip_quality", 0.5)), 0.0, 1.0),
		"week": int(context.get("week", 0)),
		"source_event": str(request.get("source_event", "manual_composer"))
	}
	return {"ok": true, "post": post}
