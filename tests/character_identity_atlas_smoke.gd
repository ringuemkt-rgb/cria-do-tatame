extends SceneTree

var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("[CharacterAtlas] " + message)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://production/character_art_v1/atlas_manifest.json"))
	check(typeof(raw) == TYPE_DICTIONARY, "manifest parses")
	if typeof(raw) != TYPE_DICTIONARY:
		quit(1)
		return
	var manifest: Dictionary = raw
	check(manifest.get("character_count") == 39, "39 corporeal identities")
	check(manifest.get("frame_count") == 117, "117 authored directional views")
	check(manifest.get("fighter_count") == 17, "all 17 roster fighters covered")
	check(manifest.get("shipping") == false and manifest.get("gameplay_authority") == false, "candidate package cannot claim shipping or gameplay authority")
	var scene: PackedScene = load("res://tools/art/CharacterAtlasReview.tscn")
	check(scene != null, "review scene loadable")
	if scene == null:
		quit(1)
		return
	var review: Control = scene.instantiate()
	root.add_child(review)
	await process_frame
	await process_frame
	var seen := {}
	for entry_value in manifest.get("characters", []):
		var entry: Dictionary = entry_value
		var id := str(entry["character_id"])
		check(not seen.has(id), "unique identity: " + id)
		seen[id] = true
		check(bool(review.call("select_character", id)), "select and load: " + id)
		check(str(review.get("selected_character_id")) == id, "correct identity selected: " + id)
		check(entry.get("shipping") == false and entry.get("human_review") == "PENDING", "no inferred approval: " + id)
		check(entry.get("animation_status") == "NOT_AUTHORED", "static views never impersonate animation: " + id)
		var frames: Array = entry.get("frames", [])
		check(frames.size() == 3, "three directions: " + id)
		var texture: Texture2D = load("res://" + str(entry["image"]))
		check(texture != null, "PNG imports: " + id)
		for frame_value in frames:
			var frame: Dictionary = frame_value
			var r: Array = frame["content_rect"]
			var c: Array = frame["source_rect"]
			var region := Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))
			var cell := Rect2(float(c[0]), float(c[1]), float(c[2]), float(c[3]))
			check(region.has_area(), "nonempty measured view: " + id)
			check(cell.encloses(region), "view stays inside its source cell: " + id)
			if texture != null:
				check(Rect2(Vector2.ZERO, texture.get_size()).encloses(cell), "source cell stays inside imported PNG: " + id)
		var previews: Array = review.get("previews")
		for preview in previews:
			var normalized: Rect2 = preview.call("get_normalized_rect")
			check(Rect2(0, 0, 128, 128).encloses(normalized), "normalized preview bounds: " + id)
			check(is_equal_approx(normalized.end.y, 96.0), "stable foot pivot: " + id)
			check(review.get_global_rect().encloses(preview.get_global_rect()), "preview visible in review screen: " + id)
		await process_frame
	check(not bool(review.call("select_character", "teruko_nishiuchi")), "hidden ancestor stays in memory fragments")
	check(not bool(review.call("select_character", "coro")), "chorus has no invented body")
	check(not bool(review.call("select_character", "unknown_character")), "unknown identity rejected")
	check(bool(review.call("select_character", "jacare_mangue")), "narrative Jacare alias accepted")
	check(str(review.get("selected_character_id")) == "jacare_do_mangue", "roster Jacare ID preserved")
	check(bool(review.call("select_character", "leoa_quilombola")), "legacy Leoa alias accepted")
	check(str(review.get("selected_character_id")) == "leoa", "current Leoa ID preserved")
	check(review.get("texture_cache").size() == 10, "only ten source atlases loaded")
	review.queue_free()
	await process_frame
	print("[CharacterAtlas] checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
