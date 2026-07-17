extends RefCounted
class_name CharacterAnimationLibrary

static func load_manifest(manifest_path: String) -> Dictionary:
	if not FileAccess.file_exists(manifest_path):
		return {}
	var file := FileAccess.open(manifest_path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

static func build_sprite_frames(manifest_path: String) -> SpriteFrames:
	var manifest := load_manifest(manifest_path)
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	if manifest.is_empty():
		return frames
	var image_path := manifest_path.get_base_dir().path_join(str(manifest.get("image", "sprite_sheet.png")))
	var atlas: Texture2D = load(image_path)
	if atlas == null:
		return frames
	var action := str(manifest.get("action_id", "default"))
	frames.add_animation(action)
	frames.set_animation_loop(action, action in ["idle", "walk", "stance", "recording"])
	var layout: Array = manifest.get("frame_layout", [])
	var fps := 8.0
	if not layout.is_empty():
		fps = 1000.0 / maxf(1.0, float(layout[0].get("duration_ms", 125)))
	frames.set_animation_speed(action, fps)
	for item_value in layout:
		var item: Dictionary = item_value
		var texture := AtlasTexture.new()
		texture.atlas = atlas
		texture.region = Rect2(float(item.x), float(item.y), float(item.w), float(item.h))
		frames.add_frame(action, texture)
	return frames
