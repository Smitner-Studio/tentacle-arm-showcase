// Shadow Overlay: Recolors geometry using CanvasGroup's composited output
// CanvasGroup prevents alpha overdraw artifacts from overlapping segments

shader_type canvas_item;
render_mode blend_mix;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform vec4 shadow_color : source_color = vec4(0.078, 0.137, 0.227, 0.25);

void fragment() {
	vec4 group_pixel = textureLod(screen_texture, SCREEN_UV, 0.0);
	
	// Replace color entirely, scale alpha by shadow_color.a
	COLOR = vec4(shadow_color.rgb, group_pixel.a * shadow_color.a);
}
