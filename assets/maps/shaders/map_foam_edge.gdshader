shader_type canvas_item;
render_mode unshaded, blend_add;

uniform sampler2D water_mask : filter_nearest;
uniform float edge_px : hint_range(1.0, 6.0) = 2.5;
uniform float pulse : hint_range(0.2, 2.0) = 0.65;
uniform vec4 foam : source_color = vec4(0.929, 0.902, 0.839, 0.35);

void fragment() {
	float m = texture(water_mask, UV).r;
	float m2 = texture(water_mask, UV + TEXTURE_PIXEL_SIZE * vec2(edge_px, 0.0)).r;
	float edge = abs(m - m2);
	float beat = 0.5 + 0.5 * sin(TIME * pulse + UV.x * 20.0);
	COLOR = foam * edge * beat * step(0.15, m);
	COLOR.a *= step(0.02, COLOR.a);
}
