extends Node2D
class_name CombatVFXController

const GOLD := Color("f2c230")
const CYAN := Color("4fc3f7")
const BLUE := Color("2d6cdf")
const CONFLICT := Color("e34b4b")

@export_range(1, 24, 1) var max_pulses: int = 12

var _pulses: Array[Dictionary] = []


func _ready() -> void:
	z_index = 3
	set_process(true)


func emit_technique(technique_id: String, origin: Vector2, success: bool) -> void:
	if _pulses.size() >= max_pulses:
		_pulses.pop_front()
	var profile := _profile_for(technique_id, success)
	profile["origin"] = origin
	profile["age"] = 0.0
	_pulses.append(profile)
	queue_redraw()


func emit_clash(origin: Vector2, level_gap: int) -> void:
	if _pulses.size() >= max_pulses:
		_pulses.pop_front()
	_pulses.append({
		"origin": origin,
		"age": 0.0,
		"duration": 0.62,
		"radius": 54.0 + abs(level_gap) * 8.0,
		"color": GOLD if level_gap >= 0 else CONFLICT,
		"rays": 14,
		"thickness": 5.0,
		"style": "clash"
	})
	queue_redraw()


func _process(delta: float) -> void:
	if _pulses.is_empty():
		return
	for index in range(_pulses.size() - 1, -1, -1):
		var pulse: Dictionary = _pulses[index]
		pulse["age"] = float(pulse.get("age", 0.0)) + delta
		if float(pulse["age"]) >= float(pulse.get("duration", 0.4)):
			_pulses.remove_at(index)
		else:
			_pulses[index] = pulse
	queue_redraw()


func _draw() -> void:
	for pulse in _pulses:
		_draw_pulse(pulse)


func _draw_pulse(pulse: Dictionary) -> void:
	var duration: float = maxf(0.01, float(pulse.get("duration", 0.4)))
	var progress: float = clampf(float(pulse.get("age", 0.0)) / duration, 0.0, 1.0)
	var origin: Vector2 = pulse.get("origin", Vector2.ZERO)
	var base_radius: float = float(pulse.get("radius", 42.0))
	var radius: float = lerpf(base_radius * 0.35, base_radius, ease(progress, -1.6))
	var alpha: float = pow(1.0 - progress, 1.35)
	var color: Color = pulse.get("color", GOLD)
	color.a *= alpha
	var thickness: float = maxf(1.0, float(pulse.get("thickness", 4.0)) * (1.0 - progress * 0.55))
	draw_arc(origin, radius, 0.0, TAU, 40, color, thickness)
	var rays: int = int(pulse.get("rays", 10))
	for ray_index in range(rays):
		var angle: float = TAU * float(ray_index) / float(rays) + progress * 0.22
		var inner: Vector2 = origin + Vector2.from_angle(angle) * radius * 0.74
		var outer: Vector2 = origin + Vector2.from_angle(angle) * radius * (1.05 + 0.20 * progress)
		draw_line(inner, outer, color, maxf(1.0, thickness * 0.62))
	if str(pulse.get("style", "")) == "submission":
		var core := Color(GOLD, alpha * 0.22)
		draw_circle(origin, radius * 0.42, core)
	if str(pulse.get("style", "")) == "defense":
		var shield_color := Color(CYAN, alpha * 0.34)
		draw_arc(origin, radius * 0.62, PI, TAU, 18, shield_color, thickness * 1.4)


func _profile_for(technique_id: String, success: bool) -> Dictionary:
	if not success:
		return {
			"duration": 0.28,
			"radius": 28.0,
			"color": CONFLICT,
			"rays": 6,
			"thickness": 3.0,
			"style": "blocked"
		}
	match technique_id:
		"baiana", "raspagem_tesoura", "raspagem_borboleta":
			return {"duration": 0.48, "radius": 64.0, "color": BLUE, "rays": 12, "thickness": 5.0, "style": "impact"}
		"sprawl", "defesa", "defesa_perfeita":
			return {"duration": 0.40, "radius": 52.0, "color": CYAN, "rays": 9, "thickness": 4.0, "style": "defense"}
		"encerramento_tecnico", "chave_braco", "estrangulamento_costas":
			return {"duration": 0.68, "radius": 72.0, "color": GOLD, "rays": 16, "thickness": 6.0, "style": "submission"}
		"grip_de_ferro", "grip":
			return {"duration": 0.32, "radius": 36.0, "color": GOLD, "rays": 8, "thickness": 4.0, "style": "grip"}
		_:
			return {"duration": 0.38, "radius": 44.0, "color": GOLD, "rays": 10, "thickness": 4.0, "style": "control"}
