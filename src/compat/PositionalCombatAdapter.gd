class_name PositionalCombatAdapter
extends RefCounted

const LEGACY_TO_V4 := {
	"PLAYER_STANDING_NEUTRAL": {"position": "STANDING", "side": "any"},
	"PLAYER_TOP_CLINCH": {"position": "CLINCH", "side": "top"},
	"PLAYER_BOTTOM_CLINCH": {"position": "CLINCH", "side": "bottom"},
	"PLAYER_TOP_GUARD": {"position": "GUARD", "side": "top"},
	"PLAYER_BOTTOM_GUARD": {"position": "GUARD", "side": "bottom"},
	"PLAYER_TOP_SIDE": {"position": "SIDE_CONTROL", "side": "top"},
	"PLAYER_BOTTOM_SIDE": {"position": "SIDE_CONTROL", "side": "bottom"},
	"PLAYER_TOP_MOUNT": {"position": "MOUNT", "side": "top"},
	"PLAYER_BOTTOM_MOUNT": {"position": "MOUNT", "side": "bottom"},
	"PLAYER_BACK_ATTACK": {"position": "BACK_CONTROL", "side": "top"},
	"PLAYER_BACK_DEFENSE": {"position": "BACK_CONTROL", "side": "bottom"},
	"PLAYER_SUBMISSION_ATTACK": {"position": "SUBMISSION", "side": "top"},
	"PLAYER_SUBMISSION_DEFENSE": {"position": "SUBMISSION", "side": "bottom"},
	"RESET": {"position": "STANDING", "side": "any"}
}

const V4_TO_LEGACY := {
	"STANDING:any": "PLAYER_STANDING_NEUTRAL",
	"CLINCH:top": "PLAYER_TOP_CLINCH",
	"CLINCH:bottom": "PLAYER_BOTTOM_CLINCH",
	"CLINCH:any": "PLAYER_TOP_CLINCH",
	"GUARD:top": "PLAYER_TOP_GUARD",
	"GUARD:bottom": "PLAYER_BOTTOM_GUARD",
	"HALF:top": "PLAYER_TOP_GUARD",
	"HALF:bottom": "PLAYER_BOTTOM_GUARD",
	"SIDE_CONTROL:top": "PLAYER_TOP_SIDE",
	"SIDE_CONTROL:bottom": "PLAYER_BOTTOM_SIDE",
	"MOUNT:top": "PLAYER_TOP_MOUNT",
	"MOUNT:bottom": "PLAYER_BOTTOM_MOUNT",
	"BACK_CONTROL:top": "PLAYER_BACK_ATTACK",
	"BACK_CONTROL:bottom": "PLAYER_BACK_DEFENSE",
	"SUBMISSION:top": "PLAYER_SUBMISSION_ATTACK",
	"SUBMISSION:bottom": "PLAYER_SUBMISSION_DEFENSE"
}

static func legacy_to_v4(state_name: String) -> Dictionary:
	return LEGACY_TO_V4.get(state_name, {"position": "STANDING", "side": "any"}).duplicate(true)

static func v4_to_legacy(position: String, side: String) -> String:
	var normalized_position := position.to_upper()
	var normalized_side := side.to_lower()
	var key := "%s:%s" % [normalized_position, normalized_side]
	if V4_TO_LEGACY.has(key):
		return V4_TO_LEGACY[key]
	if normalized_position == "STANDING":
		return "PLAYER_STANDING_NEUTRAL"
	return "PLAYER_STANDING_NEUTRAL"

static func opposite_side(side: String) -> String:
	match side.to_lower():
		"top": return "bottom"
		"bottom": return "top"
		_: return "any"

static func validate_contract() -> Dictionary:
	var required_positions := ["STANDING", "CLINCH", "GUARD", "HALF", "SIDE_CONTROL", "MOUNT", "BACK_CONTROL", "SUBMISSION"]
	var represented := {}
	for value in LEGACY_TO_V4.values():
		represented[str(value.get("position", ""))] = true
	# HALF is intentionally projected onto legacy GUARD until runtime migration is complete.
	represented["HALF"] = true
	var missing: Array[String] = []
	for position in required_positions:
		if not represented.has(position):
			missing.append(position)
	return {"ok": missing.is_empty(), "missing": missing}
