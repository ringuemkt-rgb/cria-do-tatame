# Godot import handoff

There is **no scene update in this PR**. Approved candidate texture/animation import must use existing project.godot, SpriteFrames/AnimationPlayer and current scenes, with 12 fps, nearest filtering, shared [64,96] and paired sync_map. The existing combat authority chooses transitions/results; artwork does not. Any future runtime adapter to data/transitions must be a separate PR with smokes and full quality.
