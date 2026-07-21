extends Resource
class_name ArenaLightingProfile

@export var arena_id: StringName = &"arena_do_dique"
@export var base_tint: Color = Color.WHITE
@export var overlay_tint: Color = Color(0.55, 0.72, 1.0, 0.72)
@export_range(0.0, 1.0, 0.01) var overlay_min_alpha: float = 0.48
@export_range(0.0, 1.0, 0.01) var overlay_max_alpha: float = 0.76
@export_range(0.1, 8.0, 0.1) var pulse_speed: float = 1.25
@export_range(0.0, 2.0, 0.05) var result_flash_strength: float = 0.65
@export var crowd_shadow: Color = Color(0.02, 0.03, 0.06, 0.92)
