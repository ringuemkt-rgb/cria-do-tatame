class_name CriaLiveV2
extends Control

var last_published_post_id := ""
var last_published_text := ""

func _ready() -> void:
	if not CriaLiveManager.post_published.is_connected(_on_post_published):
		CriaLiveManager.post_published.connect(_on_post_published)
	_refresh_feed()

func _exit_tree() -> void:
	if CriaLiveManager.post_published.is_connected(_on_post_published):
		CriaLiveManager.post_published.disconnect(_on_post_published)

func _refresh_feed() -> void:
	var feed := CriaLiveManager.get_feed()
	if feed.is_empty():
		return
	_on_post_published(feed.back())
	if feed.size() > 1:
		$Columns/FeedPanel/Layout/Post2/Text.text = _format_post(feed[feed.size() - 2])

func _on_post_published(post: Dictionary) -> void:
	$Columns/FeedPanel/Layout/Post2/Text.text = $Columns/FeedPanel/Layout/Post1/Text.text
	$Columns/FeedPanel/Layout/Post1/Text.text = _format_post(post)
	last_published_post_id = str(post.get("id", ""))
	last_published_text = str(post.get("text", ""))

func _format_post(post: Dictionary) -> String:
	var author := str(post.get("author", "CRIA LIVE")).replace("_", " ").to_upper()
	var tone := str(post.get("tone", "POST")).replace("_", " ").to_upper()
	return "%s  •  %s\n\n%s\n\n%d APOIOS  •  %d COMENTÁRIOS" % [
		author,
		tone,
		str(post.get("text", "")),
		int(post.get("likes", 0)),
		post.get("comments", []).size()
	]
