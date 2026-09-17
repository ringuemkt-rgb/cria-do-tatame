class_name CriaLiveService
extends Node

const ViralityEngineScript = preload("res://src/social/CriaLiveViralityEngine.gd")
const FeedGeneratorScript = preload("res://src/social/CriaLiveFeedGenerator.gd")
const PostComposerScript = preload("res://src/social/CriaLivePostComposer.gd")

var config: Dictionary = {}
var sponsor_catalog: Dictionary = {}
var virality
var feed_generator
var composer

func configure(config_data: Dictionary, sponsors: Dictionary = {}) -> void:
	config = config_data.duplicate(true)
	sponsor_catalog = sponsors.duplicate(true)
	virality = ViralityEngineScript.new(config)
	feed_generator = FeedGeneratorScript.new()
	composer = PostComposerScript.new(config)

func is_ready() -> bool:
	return (
		str(config.get("version", "")) == "1.0.0"
		and virality != null
		and feed_generator != null
		and composer != null
	)

func new_state() -> Dictionary:
	var defaults: Dictionary = config.get("profile_defaults", {})
	return {
		"version": "1.0.0",
		"profile": {
			"handle": str(defaults.get("handle", "@ruanmacacao")),
			"followers": maxi(0, int(defaults.get("followers", 0))),
			"hype": clampf(float(defaults.get("hype", 0.0)), 0.0, 100.0),
			"verified": bool(defaults.get("verified", false)),
			"coverage_risk": maxf(0.0, float(defaults.get("coverage_risk", 0.0)))
		},
		"posts": [],
		"proposals": [],
		"sponsors": [],
		"provocations": [],
		"rivals": {},
		"technique_exposure": {},
		"clip_history": {},
		"next_post_sequence": 1,
		"last_week_processed": 0
	}

func normalize_state(raw: Dictionary) -> Dictionary:
	var base := new_state()
	for key_value in raw.keys():
		base[str(key_value)] = raw[key_value]
	if typeof(base.get("profile", {})) != TYPE_DICTIONARY:
		base["profile"] = new_state()["profile"]
	for array_key in ["posts", "proposals", "sponsors", "provocations"]:
		if typeof(base.get(array_key, [])) != TYPE_ARRAY:
			base[array_key] = []
	for dict_key in ["rivals", "technique_exposure", "clip_history"]:
		if typeof(base.get(dict_key, {})) != TYPE_DICTIONARY:
			base[dict_key] = {}
	return base

func publish_post(raw_state: Dictionary, request: Dictionary, context: Dictionary) -> Dictionary:
	var state := normalize_state(raw_state).duplicate(true)
	var composed: Dictionary = composer.compose(state, request, context)
	if not bool(composed.get("ok", false)):
		return {"ok": false, "error": composed.get("error", "compose_failed"), "state": state}
	var post: Dictionary = composed.get("post", {})
	var clip_ref := str(post.get("clip_ref", ""))
	var clip_history: Dictionary = state.get("clip_history", {}).duplicate(true)
	var score_context := context.duplicate(true)
	score_context["clip_seen_before"] = clip_ref != "" and int(clip_history.get(clip_ref, 0)) > 0
	var profile: Dictionary = state.get("profile", {}).duplicate(true)
	var scored: Dictionary = virality.score_post(post, profile, score_context)
	var tone_rule: Dictionary = config.get("tone_rules", {}).get(str(post.get("tone", "")), {})
	var followers_before := maxi(0, int(profile.get("followers", 0)))
	var follower_gain := maxi(1, int(round((10.0 + sqrt(float(maxi(1, followers_before)))) * float(scored.get("score", 0.0)))))
	if bool(scored.get("viral", false)):
		follower_gain += int(config.get("virality", {}).get("viral_follower_bonus", 250))
	profile["followers"] = followers_before + follower_gain
	var hype_delta := float(tone_rule.get("hype_delta", 0.0))
	if bool(scored.get("viral", false)):
		hype_delta += float(config.get("virality", {}).get("viral_hype_bonus", 12.0))
	profile["hype"] = clampf(float(profile.get("hype", 0.0)) + hype_delta, 0.0, 100.0)
	var coverage_delta := 0.0
	if bool(context.get("infiltration_active", false)) and str(post.get("type", "")) in config.get("infiltration", {}).get("risk_types", []):
		coverage_delta = float(tone_rule.get("heat_delta", 0.0)) * float(tone_rule.get("coverage_multiplier", 1.0))
		profile["coverage_risk"] = maxf(0.0, float(profile.get("coverage_risk", 0.0)) + coverage_delta)
	var tier := follower_tier(int(profile.get("followers", 0)))
	var ad_rate := float(tier.get("ad_rate", 0.0))
	var ad_coin := maxi(0, int(floor(float(scored.get("likes", 0)) * ad_rate)))
	post["score"] = float(scored.get("score", 0.0))
	post["likes"] = int(scored.get("likes", 0))
	post["viral"] = bool(scored.get("viral", false))
	post["followers_delta"] = follower_gain
	post["hype_delta"] = hype_delta
	post["coverage_delta"] = coverage_delta
	post["ad_coin"] = ad_coin
	post["tier_after"] = str(tier.get("id", "bairro"))
	state["profile"] = profile
	var posts: Array = state.get("posts", []).duplicate(true)
	posts.append(post)
	while posts.size() > 120:
		posts.pop_front()
	state["posts"] = posts
	state["next_post_sequence"] = int(state.get("next_post_sequence", 1)) + 1
	if clip_ref != "":
		clip_history[clip_ref] = int(clip_history.get(clip_ref, 0)) + 1
	state["clip_history"] = clip_history
	var events: Array = [{
		"type": "crialive_post",
		"amount": 0.0,
		"context": {
			"post_id": post.get("id", ""),
			"followers_delta": follower_gain,
			"hype_delta": hype_delta,
			"ad_coin": ad_coin,
			"honra_delta": float(tone_rule.get("honra_delta", 0.0))
		}
	}]
	if bool(post.get("viral", false)):
		events.append({"type": "crialive_viral", "amount": 0.0, "context": {"post_id": post.get("id", "")}})
	var technique_id := str(post.get("technique_id", ""))
	if technique_id != "" and str(post.get("type", "")) == "clip_luta":
		var exposure: Dictionary = state.get("technique_exposure", {}).duplicate(true)
		exposure[technique_id] = int(exposure.get(technique_id, 0)) + 1
		state["technique_exposure"] = exposure
		if int(exposure[technique_id]) == int(config.get("nemesis", {}).get("technique_exposure_threshold", 2)):
			events.append({
				"type": "crialive_nemesis_exposure",
				"amount": 0.0,
				"context": {"technique_id": technique_id, "count": int(exposure[technique_id])}
			})
	var lay_low := float(profile.get("coverage_risk", 0.0)) >= float(config.get("infiltration", {}).get("lay_low_threshold", 12.0))
	return {
		"ok": true,
		"state": state,
		"post": post,
		"events": events,
		"ad_coin": ad_coin,
		"honra_delta": float(tone_rule.get("honra_delta", 0.0)),
		"lay_low_recommended": lay_low
	}

func ensure_slice_proposals(raw_state: Dictionary, current_week: int) -> Dictionary:
	var state := normalize_state(raw_state).duplicate(true)
	var proposals: Array = state.get("proposals", []).duplicate(true)
	var existing: Dictionary = {}
	for proposal_value in proposals:
		if typeof(proposal_value) == TYPE_DICTIONARY:
			existing[str(proposal_value.get("id", ""))] = true
	for spec_value in config.get("slice_proposals", []):
		if typeof(spec_value) != TYPE_DICTIONARY:
			continue
		var spec: Dictionary = spec_value
		var proposal_id := str(spec.get("id", ""))
		if proposal_id == "" or existing.has(proposal_id):
			continue
		var proposal := spec.duplicate(true)
		proposal["created_week"] = current_week
		proposal["deadline_week"] = current_week + int(spec.get("deadline_week_offset", 2))
		proposal["status"] = "open"
		proposal["purse"] = _dynamic_purse(spec, state)
		proposals.append(proposal)
	state["proposals"] = proposals
	return {"ok": true, "state": state, "proposals": proposals}

func accept_proposal(raw_state: Dictionary, proposal_id: String, current_week: int) -> Dictionary:
	var state := normalize_state(raw_state).duplicate(true)
	var proposals: Array = state.get("proposals", []).duplicate(true)
	for index in range(proposals.size()):
		if typeof(proposals[index]) != TYPE_DICTIONARY:
			continue
		var proposal: Dictionary = proposals[index]
		if str(proposal.get("id", "")) != proposal_id:
			continue
		if str(proposal.get("status", "")) != "open":
			return {"ok": false, "error": "proposal_not_open", "state": state}
		if current_week > int(proposal.get("deadline_week", current_week)):
			proposal["status"] = "expired"
			proposals[index] = proposal
			state["proposals"] = proposals
			return {"ok": false, "error": "proposal_expired", "state": state}
		if float(state.get("profile", {}).get("hype", 0.0)) < float(proposal.get("hype_req", 0.0)):
			return {"ok": false, "error": "hype_requirement_not_met", "state": state}
		proposal["status"] = "accepted"
		proposal["accepted_week"] = current_week
		proposals[index] = proposal
		state["proposals"] = proposals
		return {
			"ok": true,
			"state": state,
			"proposal": proposal,
			"events": [{"type": "crialive_proposal_accepted", "amount": 0.0, "context": proposal.duplicate(true)}]
		}
	return {"ok": false, "error": "proposal_not_found", "state": state}

func sign_sponsor(raw_state: Dictionary, sponsor_id: String, duration_weeks: int = 4) -> Dictionary:
	var state := normalize_state(raw_state).duplicate(true)
	var spec: Dictionary = sponsor_catalog.get(sponsor_id, {})
	if spec.is_empty():
		return {"ok": false, "error": "sponsor_not_found", "state": state}
	var requirements: Dictionary = spec.get("requirements", {})
	var profile: Dictionary = state.get("profile", {})
	if int(profile.get("followers", 0)) < int(requirements.get("followers", 0)):
		return {"ok": false, "error": "followers_requirement_not_met", "state": state}
	if float(profile.get("hype", 0.0)) < float(requirements.get("hype", 0.0)):
		return {"ok": false, "error": "hype_requirement_not_met", "state": state}
	var sponsors: Array = state.get("sponsors", []).duplicate(true)
	for active_value in sponsors:
		if typeof(active_value) == TYPE_DICTIONARY and str(active_value.get("id", "")) == sponsor_id and bool(active_value.get("active", false)):
			return {"ok": false, "error": "sponsor_already_active", "state": state}
	sponsors.append({
		"id": sponsor_id,
		"active": true,
		"weeks_remaining": maxi(1, duration_weeks),
		"posts_done_this_week": 0
	})
	state["sponsors"] = sponsors
	return {
		"ok": true,
		"state": state,
		"sponsor": spec.duplicate(true),
		"events": [{"type": "sponsor_signed", "amount": 0.0, "context": {"sponsor_id": sponsor_id}}]
	}

func weekly_tick(raw_state: Dictionary, completed_week: int) -> Dictionary:
	var state := normalize_state(raw_state).duplicate(true)
	if completed_week <= int(state.get("last_week_processed", 0)):
		return {"ok": true, "state": state, "payout_coin": 0, "events": [], "duplicate": true}
	var profile: Dictionary = state.get("profile", {}).duplicate(true)
	var posts_this_week := 0
	for post_value in state.get("posts", []):
		if typeof(post_value) == TYPE_DICTIONARY and int(post_value.get("week", -1)) == completed_week:
			posts_this_week += 1
	var weekly_cfg: Dictionary = config.get("weekly", {})
	if posts_this_week == 0:
		profile["followers"] = maxi(0, int(floor(float(profile.get("followers", 0)) * float(weekly_cfg.get("inactive_follower_multiplier", 0.98)))))
	profile["hype"] = clampf(float(profile.get("hype", 0.0)) * float(weekly_cfg.get("hype_multiplier", 0.90)), 0.0, 100.0)
	var payout_coin := 0
	var events: Array = []
	var sponsors: Array = state.get("sponsors", []).duplicate(true)
	for index in range(sponsors.size()):
		if typeof(sponsors[index]) != TYPE_DICTIONARY:
			continue
		var active: Dictionary = sponsors[index]
		if not bool(active.get("active", false)):
			continue
		var spec: Dictionary = sponsor_catalog.get(str(active.get("id", "")), {})
		var obligations: Dictionary = spec.get("obligations", {})
		var required_posts := int(obligations.get("posts_per_week", 0))
		var fulfilled := posts_this_week >= required_posts
		if fulfilled:
			var coin := maxi(0, int(spec.get("weekly_reward", 0)))
			payout_coin += coin
			events.append({
				"type": "crialive_sponsor_payout",
				"amount": 0.0,
				"context": {"sponsor_id": active.get("id", ""), "coin": coin, "week": completed_week}
			})
		else:
			events.append({
				"type": "crialive_sponsor_obligation_missed",
				"amount": 0.0,
				"context": {"sponsor_id": active.get("id", ""), "week": completed_week}
			})
		active["weeks_remaining"] = maxi(0, int(active.get("weeks_remaining", 1)) - 1)
		active["posts_done_this_week"] = 0
		if int(active["weeks_remaining"]) <= 0:
			active["active"] = false
		sponsors[index] = active
	state["profile"] = profile
	state["sponsors"] = sponsors
	state["last_week_processed"] = completed_week
	return {"ok": true, "state": state, "payout_coin": payout_coin, "events": events, "posts_this_week": posts_this_week}

func get_feed(raw_state: Dictionary, current_week: int) -> Array:
	return feed_generator.generate(normalize_state(raw_state), current_week)

func follower_tier(followers: int) -> Dictionary:
	for tier_value in config.get("follower_tiers", []):
		if typeof(tier_value) != TYPE_DICTIONARY:
			continue
		var tier: Dictionary = tier_value
		if followers >= int(tier.get("min", 0)) and followers <= int(tier.get("max", 999999999)):
			return tier
	return {"id": "bairro", "ad_rate": 0.0, "sponsor_tier": 0}

func _dynamic_purse(spec: Dictionary, state: Dictionary) -> int:
	var base := float(spec.get("base_purse", 100))
	var profile: Dictionary = state.get("profile", {})
	var hype_multiplier := 1.0 + float(profile.get("hype", 0.0)) / 100.0
	var tier: Dictionary = follower_tier(int(profile.get("followers", 0)))
	var tier_multiplier := 1.0 + float(tier.get("sponsor_tier", 0)) * 0.15
	return maxi(1, int(round(base * hype_multiplier * tier_multiplier)))
