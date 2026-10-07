shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform sampler2D water_mask : filter_nearest, repeat_disable;
uniform float speed : hint_range(0.02, 0.35) = 0.08;
uniform float freq : hint_range(4.0, 28.0) = 12.0;
uniform float amp_px : hint_range(0.0, 3.0) = 1.2;
uniform float canvas_w = 1536.0;
uniform float canvas_h = 864.0;
uniform float sparkle : hint_range(0.0, 0.25) = 0.07;
uniform vec4 deep_col : source_color = vec4(0.118, 0.227, 0.373, 1.0);
uniform vec4 foam_col : source_color = vec4(0.247, 0.890, 0.961, 1.0);

void fragment() {
	vec2 px = vec2(1.0 / canvas_w, 1.0 / canvas_h);
	float mask = texture(water_mask, UV).r;
	float t = TIME * speed;
	float wave = sin(UV.x * freq + t) * cos(UV.y * (freq * 0.55) - t * 0.7);
	vec2 off = vec2(wave, wave * 0.35) * amp_px * px;
	vec4 base = texture(TEXTURE, UV + off * mask);
	float spark = step(0.92, fract(sin(dot(UV * 180.0 + t * 3.0, vec2(12.9898, 78.233))) * 43758.5));
	base.rgb = mix(base.rgb, foam_col.rgb, spark * sparkle * mask);
	base.rgb = mix(base.rgb, deep_col.rgb, (0.12 - wave * 0.06) * mask);
	COLOR = base;
}
