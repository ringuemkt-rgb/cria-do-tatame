extends SceneTree

const ServiceScript = preload("res://src/social/CriaLiveService.gd")

func _init() -> void:
	var config: Dictionary = _load_json("res://data/social/crialive_v1.json")
	var sponsor_raw: Dictionary = _load_json("res://data/sponsors.json")
	var sponsors := {}
	for row_value in sponsor_raw.get("sponsors", []):
		if typeof(row_value) == TYPE_DICTIONARY:
			var row: Dictionary = row_value
			sponsors[str(row.get("id", ""))] = row
	var service = ServiceScript.new()
	service.configure(config, sponsors)
	if not service.is_ready():
		_fail("service_not_ready")
		return

	var state: Dictionary = service.new_state()
	state["profile"]["followers"] = 600
	state["profile"]["hype"] = 35.0
	var request := {
		"type": "clip_luta",
		"tone": "confiante",
		"caption": "Pressao e paciencia. Seguimos.",
		"clip_ref": "fight_012",
		"technique_id": "knee_cut",
		"clip_quality": 0.90
	}
	var context := {
		"week": 12,
		"seed": 424242,
		"trend_bonus": 1.30,
		"faction_align": 1.0,
		"infiltration_active": false
	}
	var a: Dictionary = service.publish_post(state, request, context)
	var b: Dictionary = service.publish_post(state, request, context)
	if not bool(a.get("ok", false)) or not bool(b.get("ok", false)):
		_fail("publish_failed")
		return
	if not is_equal_approx(float(a.get("post", {}).get("score", -1.0)), float(b.get("post", {}).get("score", -2.0))):
		_fail("seeded_score_not_deterministic")
		return
	if int(a.get("post", {}).get("likes", -1)) != int(b.get("post", {}).get("likes", -2)):
		_fail("seeded_likes_not_deterministic")
		return
	if float(a.get("state", {}).get("profile", {}).get("coverage_risk", -1.0)) != 0.0:
		_fail("coverage_changed_outside_infiltration")
		return

	var second: Dictionary = service.publish_post(a.get("state", {}), request, context)
	if not _has_event(second.get("events", []), "crialive_nemesis_exposure"):
		_fail("nemesis_did_not_learn_on_second_exposure")
		return
	if int(second.get("state", {}).get("technique_exposure", {}).get("knee_cut", 0)) != 2:
		_fail("technique_exposure_count_wrong")
		return

	var provocative := request.duplicate(true)
	provocative["clip_ref"] = "fight_013"
	provocative["tone"] = "provocador"
	var infiltrated_context := context.duplicate(true)
	infiltrated_context["infiltration_active"] = true
	var risky: Dictionary = service.publish_post(second.get("state", {}), provocative, infiltrated_context)
	if float(risky.get("state", {}).get("profile", {}).get("coverage_risk", 0.0)) <= 0.0:
		_fail("coverage_risk_not_applied")
		return

	var seeded: Dictionary = service.ensure_slice_proposals(risky.get("state", {}), 12)
	if int(seeded.get("state", {}).get("proposals", []).size()) != 1:
		_fail("slice_proposal_missing")
		return
	var accepted: Dictionary = service.accept_proposal(seeded.get("state", {}), "fp_davi_dique_v1", 12)
	if not bool(accepted.get("ok", false)) or str(accepted.get("proposal", {}).get("status", "")) != "accepted":
		_fail("proposal_accept_failed")
		return

	var signed: Dictionary = service.sign_sponsor(accepted.get("state", {}), "academia_suplementos", 3)
	if not bool(signed.get("ok", false)):
		_fail("sponsor_sign_failed:%s" % str(signed.get("error", "")))
		return
	var weekly: Dictionary = service.weekly_tick(signed.get("state", {}), 12)
	if int(weekly.get("payout_coin", -1)) != 40:
		_fail("weekly_payout_wrong:%s" % str(weekly.get("payout_coin", -1)))
		return
	if not _has_event(weekly.get("events", []), "crialive_sponsor_payout"):
		_fail("sponsor_payout_event_missing")
		return
	var duplicate: Dictionary = service.weekly_tick(weekly.get("state", {}), 12)
	if int(duplicate.get("payout_coin", -1)) != 0 or not bool(duplicate.get("duplicate", false)):
		_fail("weekly_tick_not_idempotent")
		return

	var feed: Array = service.get_feed(weekly.get("state", {}), 12)
	if feed.is_empty():
		_fail("feed_empty")
		return

	print("CRIALIVE_V1_SMOKE_OK")
	quit(0)

func _has_event(events: Array, event_type: String) -> bool:
	for event_value in events:
		if typeof(event_value) == TYPE_DICTIONARY and str(event_value.get("type", "")) == event_type:
			return true
	return false

func _load_json(path: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

func _fail(message: String) -> void:
	push_error("CRIALIVE_V1_SMOKE_FAIL: %s" % message)
	quit(1)
