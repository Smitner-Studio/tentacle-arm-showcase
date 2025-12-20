/*
 * Eye Tracking Shader
 *
 * Single-pass eye rendering that handles:
 * - Pupil tracking via UV scrolling (offset pre-clamped by GDScript)
 * - Static eyelid overlay compositing
 * - Mask cutout for eye shape
 *
 */
shader_type canvas_item;

// Pre-clamped offset from GDScript (no per-pixel math needed)
uniform ivec2 target_offset = ivec2(0, 0);
uniform sampler2D eyelid_texture : filter_nearest;
uniform sampler2D mask_texture : filter_nearest;

void fragment() {
	// Apply pre-computed UV offset (GDScript handles clamping)
	vec2 uv_offset = vec2(target_offset) * TEXTURE_PIXEL_SIZE;
	vec2 eye_uv = UV - uv_offset;

	// Sample layers
	vec4 eye_color = texture(TEXTURE, eye_uv);       // Scrolled UV
	vec4 eyelid_color = texture(eyelid_texture, UV); // Static UV
	vec4 mask = texture(mask_texture, UV);           // Static UV

	// Composite: eye + eyelid overlay
	vec4 composite = mix(eye_color, eyelid_color, eyelid_color.a);

	// Apply mask cutout (transparent = visible, opaque = hidden)
	composite.a *= (1.0 - round(mask.a));

	COLOR = composite;
}
