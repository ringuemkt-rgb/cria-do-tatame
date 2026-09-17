class_name GrapplingPairedTimelineV1
extends RefCounted

const PHASES := ["anticipation", "entry", "establish", "stabilize", "response", "recovery"]

static func validate(sync_map: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	if str(sync_map.get("version", "")) != "1.0.0":
		errors.append("invalid_version")
	var duration_ms := int(sync_map.get("duration_ms", 0))
	var attacker_frames := int(sync_map.get("attacker_frames", 0))
	var defender_frames := int(sync_map.get("defender_frames", 0))
	if duration_ms <= 0:
		errors.append("duration_invalid")
	if attacker_frames <= 0:
		errors.append("attacker_frames_invalid")
	if defender_frames <= 0:
		errors.append("defender_frames_invalid")
	if bool(sync_map.get("human_approval", false)) != true:
		errors.append("human_approval_required")

	var phases = sync_map.get("phases", [])
	if typeof(phases) != TYPE_ARRAY or phases.is_empty():
		errors.append("phases_missing")
	else:
		var previous_end := 0
		for index in range(phases.size()):
			if typeof(phases[index]) != TYPE_DICTIONARY:
				errors.append("phase_not_dictionary:%d" % index)
				continue
			var row: Dictionary = phases[index]
			var phase := str(row.get("phase", ""))
			var start_ms := int(row.get("start_ms", -1))
			var end_ms := int(row.get("end_ms", -1))
			if phase not in PHASES:
				errors.append("phase_invalid:%s" % phase)
			if start_ms < 0 or end_ms <= start_ms or end_ms > duration_ms:
				errors.append("phase_range_invalid:%s" % phase)
			if index > 0 and start_ms < previous_end:
				errors.append("phase_overlap:%s" % phase)
			previous_end = end_ms

	var points = sync_map.get("sync_points", [])
	if typeof(points) != TYPE_ARRAY or points.size() < 2:
		errors.append("sync_points_insufficient")
	else:
		var previous_time := -1
		for index in range(points.size()):
			if typeof(points[index]) != TYPE_DICTIONARY:
				errors.append("sync_point_not_dictionary:%d" % index)
				continue
			var point: Dictionary = points[index]
			var time_ms := int(point.get("time_ms", -1))
			var attacker_frame := int(point.get("attacker_frame", -1))
			var defender_frame := int(point.get("defender_frame", -1))
			if time_ms < 0 or time_ms > duration_ms or time_ms <= previous_time:
				errors.append("sync_time_invalid:%d" % index)
			if attacker_frame < 0 or attacker_frame >= attacker_frames:
				errors.append("attacker_frame_invalid:%d" % index)
			if defender_frame < 0 or defender_frame >= defender_frames:
				errors.append("defender_frame_invalid:%d" % index)
			if typeof(point.get("contact_signature", [])) != TYPE_ARRAY:
				errors.append("contact_signature_not_array:%d" % index)
			previous_time = time_ms

	var pivot = sync_map.get("shared_pivot", {})
	if typeof(pivot) != TYPE_DICTIONARY or str(pivot.get("policy", "")) != "PAIR_WORLD_ANCHOR":
		errors.append("shared_pair_pivot_invalid")
	return {"ok": errors.is_empty(), "errors": errors}

static func sample(sync_map: Dictionary, elapsed_ms: int, loop: bool = false) -> Dictionary:
	var check := validate(sync_map)
	if not bool(check.get("ok", false)):
		return {"ok": false, "errors": check.get("errors", [])}
	var duration_ms := int(sync_map.get("duration_ms", 1))
	var t := elapsed_ms
	if loop:
		t = posmod(t, duration_ms)
	else:
		t = clampi(t, 0, duration_ms)
	var points: Array = sync_map.get("sync_points", [])
	var left: Dictionary = points[0]
	var right: Dictionary = points[points.size() - 1]
	for index in range(points.size() - 1):
		var a: Dictionary = points[index]
		var b: Dictionary = points[index + 1]
		if t >= int(a.get("time_ms", 0)) and t <= int(b.get("time_ms", duration_ms)):
			left = a
			right = b
			break
	var span := maxi(1, int(right.get("time_ms", 0)) - int(left.get("time_ms", 0)))
	var alpha := clampf(float(t - int(left.get("time_ms", 0))) / float(span), 0.0, 1.0)
	var attacker_frame := _nearest_frame(int(left.get("attacker_frame", 0)), int(right.get("attacker_frame", 0)), alpha)
	var defender_frame := _nearest_frame(int(left.get("defender_frame", 0)), int(right.get("defender_frame", 0)), alpha)
	return {
		"ok": true,
		"elapsed_ms": t,
		"normalized_time": clampf(float(t) / float(duration_ms), 0.0, 1.0),
		"phase": phase_at(sync_map, t),
		"attacker_frame": attacker_frame,
		"defender_frame": defender_frame,
		"contact_signature": _contact_for_interval(left, right, alpha),
		"shared_pivot": sync_map.get("shared_pivot", {}).duplicate(true),
		"finished": not loop and t >= duration_ms
	}

static func phase_at(sync_map: Dictionary, elapsed_ms: int) -> String:
	for raw_phase in sync_map.get("phases", []):
		if typeof(raw_phase) != TYPE_DICTIONARY:
			continue
		var phase: Dictionary = raw_phase
		if elapsed_ms >= int(phase.get("start_ms", 0)) and elapsed_ms <= int(phase.get("end_ms", 0)):
			return str(phase.get("phase", "UNKNOWN"))
	return "recovery" if elapsed_ms >= int(sync_map.get("duration_ms", 0)) else "UNKNOWN"

static func _nearest_frame(a: int, b: int, alpha: float) -> int:
	return a if alpha < 0.5 else b

static func _contact_for_interval(left: Dictionary, right: Dictionary, alpha: float) -> Array:
	var source = left.get("contact_signature", []) if alpha < 0.5 else right.get("contact_signature", [])
	if typeof(source) != TYPE_ARRAY:
		return []
	var out: Array[String] = []
	for value in source:
		var token := str(value)
		if token != "" and token not in out:
			out.append(token)
	out.sort()
	return out
