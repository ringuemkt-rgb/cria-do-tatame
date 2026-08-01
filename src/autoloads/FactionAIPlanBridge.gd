extends Node

func _ready() -> void:
	if SignalBus.has_signal("world_ai_plan_applied") and not SignalBus.world_ai_plan_applied.is_connected(_on_world_ai_plan_applied):
		SignalBus.world_ai_plan_applied.connect(_on_world_ai_plan_applied)
	if SignalBus.has_signal("world_tick_completed") and not SignalBus.world_tick_completed.is_connected(_on_world_tick_completed):
		SignalBus.world_tick_completed.connect(_on_world_tick_completed)

func _on_world_ai_plan_applied(plan: Dictionary) -> void:
	if not has_node("/root/FactionDirectorManager"):
		return
	var normalized: Dictionary = {}
	for faction_id_value in plan.get("faction_pressure", {}).keys():
		var raw_id := str(faction_id_value)
		var canonical := FactionManager.canonicalize_faction_id(raw_id) if has_node("/root/FactionManager") else raw_id
		if canonical == "":
			continue
		normalized[canonical] = clampf(
			float(normalized.get(canonical, 0.0)) + float(plan["faction_pressure"][faction_id_value]),
			-3.0,
			3.0
		)
	FactionDirectorManager.apply_external_pressure(normalized)

func _on_world_tick_completed(_snapshot: Dictionary) -> void:
	if not has_node("/root/FactionDirectorManager"):
		return
	var pressure_level := FactionDirectorManager.get_pressure_level()
	if pressure_level >= 4 and has_node("/root/CriaLiveManager"):
		var recent := CriaLiveManager.get_feed()
		var fingerprint := "regional_pressure_%s_%s" % [WorldState.week, WorldState.current_day]
		for post in recent:
			if str(post.get("source_event", "")) == fingerprint:
				return
		CriaLiveManager.create_post(
			"A pressão regional subiu. Academias, eventos e moradores estão escolhendo lados.",
			"pressao_regional",
			"cria_live",
			{
				"source_event": fingerprint,
				"metrics": {"reach": 220, "polarization": 8, "authority_attention": 5}
			}
		)
