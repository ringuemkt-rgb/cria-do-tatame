shader_type canvas_item;
render_mode unshaded;

uniform int preset : hint_range(0, 3) = 0;
uniform float rain : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (preset == 0) {
		c.rgb *= vec3(1.08, 0.96, 0.78);
		c.rgb = mix(c.rgb, vec3(0.118, 0.227, 0.373), 0.08);
	} else if (preset == 2) {
		c.rgb *= vec3(0.45, 0.52, 0.72);
		c.rgb += vec3(0.04, 0.03, 0.01);
	} else if (preset == 3) {
		c.rgb *= vec3(0.62, 0.68, 0.74);
	}
	if (rain > 0.01) {
		float drop = step(0.97, fract(UV.y * 70.0 - TIME * 2.4 + UV.x * 8.0));
		c.rgb = mix(c.rgb, vec3(0.93, 0.90, 0.84), drop * rain * 0.35);
	}
	COLOR = c;
}
