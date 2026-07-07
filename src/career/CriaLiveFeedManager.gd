extends Node
class_name CriaLiveFeedManager

var save_manager: SaveManager
var feed: Dictionary = {}

func setup(p_save_manager: SaveManager) -> void:
	save_manager = p_save_manager
	feed = save_manager.load_json("cria_live_feed.json", {"posts": [], "followers": 120, "heat": 0})

func save() -> void:
	save_manager.save_json("cria_live_feed.json", feed)

func post(kind: String, text: String, impact: int = 0) -> Dictionary:
	var item := {
		"kind": kind,
		"text": text,
		"impact": impact,
		"week": 0
	}
	var posts: Array = feed.get("posts", [])
	posts.push_front(item)
	feed["posts"] = posts.slice(0, 50)
	feed["heat"] = int(feed.get("heat", 0)) + impact
	feed["followers"] = max(0, int(feed.get("followers", 0)) + impact * 3)
	save()
	return item

func get_summary() -> Dictionary:
	return {
		"followers": feed.get("followers", 0),
		"heat": feed.get("heat", 0),
		"latest": feed.get("posts", []).slice(0, 5)
	}
