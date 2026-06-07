shader_type canvas_item;

uniform float blur_strength : hint_range(0.0, 4.0) = 1.8;
uniform float dim_strength : hint_range(0.0, 1.0) = 0.72;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE * blur_strength;
	vec4 col = texture(screen_texture, SCREEN_UV) * 0.34;
	col += texture(screen_texture, SCREEN_UV + vec2(px.x, 0.0)) * 0.11;
	col += texture(screen_texture, SCREEN_UV + vec2(-px.x, 0.0)) * 0.11;
	col += texture(screen_texture, SCREEN_UV + vec2(0.0, px.y)) * 0.11;
	col += texture(screen_texture, SCREEN_UV + vec2(0.0, -px.y)) * 0.11;
	col += texture(screen_texture, SCREEN_UV + vec2(px.x, px.y)) * 0.055;
	col += texture(screen_texture, SCREEN_UV + vec2(-px.x, px.y)) * 0.055;
	col += texture(screen_texture, SCREEN_UV + vec2(px.x, -px.y)) * 0.055;
	col += texture(screen_texture, SCREEN_UV + vec2(-px.x, -px.y)) * 0.055;
	col.rgb = mix(col.rgb, vec3(0.03, 0.07, 0.14), dim_strength);
	col.a = 0.94;
	COLOR = col;
}
