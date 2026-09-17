shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform sampler2D secret_mask : filter_nearest;
uniform float density : hint_range(0.0, 1.0) = 0.55;
uniform float drift : hint_range(0.01, 0.12) = 0.03;
uniform vec4 mist : source_color = vec4(0.294, 0.0, 0.510, 0.55);
uniform vec4 eye : source_color = vec4(0.55, 0.12, 0.72, 0.25);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	float m = texture(secret_mask, UV).r;
	vec2 nUV = UV * 6.0 + vec2(TIME * drift, TIME * drift * -0.4);
	float n = mix(hash(floor(nUV * 32.0)), hash(floor(nUV * 32.0) + 1.0), 0.35);
	n = floor(n * 5.0) / 5.0;
	vec4 col = mix(mist, eye, n);
	col.a *= m * density * (0.65 + 0.35 * n);
	COLOR = col;
}
