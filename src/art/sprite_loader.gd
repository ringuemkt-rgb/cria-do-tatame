class_name SpriteLoader
extends Node

const PIVOT := Vector2(64, 96)
const OFFSET := Vector2(-64, -96)
const FPS := 12.0

var _cache: Dictionary = {}

func get_frames(char_id: String, anim: String) -> SpriteFrames:
	if not _safe_token(char_id) or not _safe_token(anim):
		push_error("SpriteLoader: unsafe character/animation id")
		return null
	var key := "%s/%s" % [char_id, anim]
	if _cache.has(key):
		return _cache[key] as SpriteFrames
	var path := "res://assets/chars/frames/%s/%s.tres" % [char_id, anim]
	if not ResourceLoader.exists(path):
		push_error("SpriteLoader: missing prebuilt SpriteFrames: %s" % path)
		return null
	var sf := ResourceLoader.load(path) as SpriteFrames
	if sf == null:
		push_error("SpriteLoader: invalid SpriteFrames resource: %s" % path)
		return null
	_cache[key] = sf
	return sf

func attach(node: AnimatedSprite2D, char_id: String, anim: String) -> bool:
	var sf := get_frames(char_id, anim)
	if sf == null:
		return false
	node.sprite_frames = sf
	node.centered = false
	node.offset = OFFSET
	node.play("default")
	return true

func clear_cache() -> void:
	_cache.clear()

func _safe_token(value: String) -> bool:
	if value.is_empty() or value.contains("..") or value.contains("/") or value.contains("\\"):
		return false
	for ch in value:
		if not (ch.is_valid_identifier() or ch == "-"):
			return false
	return true
