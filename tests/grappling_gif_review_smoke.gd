extends SceneTree

var failures := 0
var checks := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var review = load("res://tools/art/GrapplingGifReview.tscn").instantiate()
	root.add_child(review)
	check(review.clips.size() == 13, "13 review clips")
	for clip in review.clips:
		check(review.select_clip(str(clip["id"])), "Clip loads: " + str(clip["id"]))
		check(review.pose_index == 0 and not review.playing, "Selection begins paused")
		review.playing = true
		review.advance_time(100.0)
		check(review.pose_index == 5 and not review.playing, "Playback must stop at recovery")
		review.advance_pose()
		check(review.pose_index == 5, "Manual advance cannot wrap recovery into attack")
		review.restart()
		check(review.pose_index == 0, "Explicit restart")
		review.playing = true
		review.advance_time(-1.0)
		check(review.pose_index == 0 and review.elapsed == 0.0, "Ignore negative time")
		review.advance_time(float(clip["duration_ms"][0]) / 1000.0 + 0.001)
		check(review.pose_index == 1, "Follow encoded timing")
	var selected: String = review.selected_id
	check(not review.select_clip("missing_clip"), "Unknown clip rejected")
	check(review.selected_id == selected, "Failed selection preserves state")
	print("Grappling GIF review: %d checks, %d failures" % [checks, failures])
	review.queue_free()
	quit(0 if failures == 0 else 1)
