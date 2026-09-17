class_name GrapplingMotionDBV1
extends RefCounted

var data: Dictionary = {}
var clips: Array = []
var by_id: Dictionary = {}
var validation_errors: Array[String] = []

func _init(database_data: Dictionary = {}):
	data = database_data.duplicate(true)
	if not data.is_empty():
		_load(data)

static func from_path(path: String):
	if not FileAccess.file_exists(path):
		return GrapplingMotionDBV1.new({})
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return GrapplingMotionDBV1.new({})
	return GrapplingMotionDBV1.new(parsed)

func _load(database_data: Dictionary) -> void:
	if str(database_data.get("version", "")) != "1.0.0":
		validation_errors.append("invalid_version")
	if bool(database_data.get("runtime_authority", true)):
		validation_errors.append("runtime_authority_must_be_false")
	for raw_clip in database_data.get("clips", []):
		if typeof(raw_clip) != TYPE_DICTIONARY:
			validation_errors.append("clip_not_dictionary")
			continue
		var clip: Dictionary = raw_clip.duplicate(true)
		var clip_id := str(clip.get("clip_id", ""))
		if clip_id == "":
			validation_errors.append("clip_id_missing")
			continue
		if by_id.has(clip_id):
			validation_errors.append("duplicate_clip_id:%s" % clip_id)
			continue
		if str(clip.get("rights_status", "")) != "COMMERCIAL_DERIVATION_ALLOWED":
			validation_errors.append("noncommercial_clip_in_runtime_db:%s" % clip_id)
			continue
		if not bool(clip.get("human_approval", false)) or str(clip.get("asset_status", "")) != "APPROVED_FINAL" or not bool(clip.get("shipping", false)):
			validation_errors.append("unapproved_clip_in_runtime_db:%s" % clip_id)
			continue
		by_id[clip_id] = clip
		clips.append(clip)
	clips.sort_custom(func(a, b): return str(a.get("clip_id", "")) < str(b.get("clip_id", "")))

func is_ready() -> bool:
	return validation_errors.is_empty() and str(data.get("version", "")) == "1.0.0"

func all_clips() -> Array:
	return clips.duplicate(true)

func clip(clip_id: String) -> Dictionary:
	if not by_id.has(clip_id):
		return {}
	return by_id[clip_id].duplicate(true)

func clips_for_technique(technique_id: String, mode: String = "") -> Array:
	var out: Array = []
	for raw_clip in clips:
		if typeof(raw_clip) != TYPE_DICTIONARY:
			continue
		var features: Dictionary = raw_clip.get("features", {})
		if str(features.get("technique_id", "")) != technique_id:
			continue
		if mode != "" and str(features.get("mode", "")) != mode:
			continue
		out.append(raw_clip.duplicate(true))
	return out

func coverage() -> Dictionary:
	var techniques := {}
	var mode_counts := {"gi": 0, "nogi": 0}
	for raw_clip in clips:
		if typeof(raw_clip) != TYPE_DICTIONARY:
			continue
		var features: Dictionary = raw_clip.get("features", {})
		var technique_id := str(features.get("technique_id", ""))
		if technique_id != "":
			techniques[technique_id] = int(techniques.get(technique_id, 0)) + 1
		var mode := str(features.get("mode", ""))
		if mode_counts.has(mode):
			mode_counts[mode] = int(mode_counts[mode]) + 1
	return {
		"ok": is_ready(),
		"clip_count": clips.size(),
		"technique_count": techniques.size(),
		"clips_by_technique": techniques,
		"clips_by_mode": mode_counts,
		"errors": validation_errors.duplicate()
	}
