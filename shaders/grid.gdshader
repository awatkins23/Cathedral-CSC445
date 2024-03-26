shader_type spatial;

uniform vec2 size = vec2(540.0, 540.0);
uniform float line_width : hint_range(0, 1) = 0.05;
uniform vec2 offset = vec2(0.0, 0.0);
uniform float grid_size = 30.0;
uniform vec3 line_color: source_color = vec3(0.0, 0.0, 0.0);
uniform vec3 bg_color: source_color = vec3(1.0, 1.0, 1.0);

void fragment() {
	vec2 uv = (offset / size) + UV;
	vec2 r = mod(size * uv, vec2(grid_size));
	vec2 lines = ceil(smoothstep(1.0 - line_width, 1, r / vec2(grid_size)));
	float alpha = dot(lines, vec2(1.0, 1.0));
	if (alpha == 0.0) {
		ALBEDO = bg_color;
	} else {
		ALBEDO = line_color;
	}
}
