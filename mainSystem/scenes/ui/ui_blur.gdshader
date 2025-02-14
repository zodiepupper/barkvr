shader_type spatial;

render_mode unshaded, cull_disabled;

uniform sampler2D screen : hint_screen_texture;

void fragment() {
	ALBEDO = textureLod(screen, SCREEN_UV, 3.0).xyz;
}
