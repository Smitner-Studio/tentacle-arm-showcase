shader_type canvas_item;

// Screen texture (required for CanvasGroup)
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// Two colors - no gradient, hard cutoff
uniform vec4 light_color : source_color = vec4(0.996, 0.882, 0.722, 1.0); // Light tan #FEE1B8
uniform vec4 dark_color : source_color = vec4(0.831, 0.776, 0.573, 1.0);  // Darker tan #D4C692
// Ratio of the width that should be dark (0.0-1.0)
uniform float shade_ratio : hint_range(0.0, 1.0) = 0.3;

void fragment() {
	// Read from screen_texture (CanvasGroup composites all children first)
	vec4 c = textureLod(screen_texture, SCREEN_UV, 0.0);

	// Un-premultiply alpha - CanvasGroup pre-multiplies, we need raw colors
	if (c.a > 0.0001) {
		c.rgb /= c.a;
	}

	// Only process opaque pixels
	if (c.a > 0.01) {
		// World-oriented shading approach:
		// Sample up and down in screen space to find edges
		// The direction with fewer pixels before hitting transparency is the edge
		// Downward (+Y in screen space) with few pixels = bottom edge in world

		// How far is one pixel in screen UV space?
		float sample_offset = 1.0 / float(textureSize(screen_texture, 0).y);

		// Count solid pixels above and below this one
		float up_count = 0.0;
		float down_count = 0.0;

		// Look up until we hit transparency (top edge of tentacle)
		for (float i = 1.0; i <= 20.0; i += 1.0) {
			vec4 pixel_up = textureLod(screen_texture, SCREEN_UV + vec2(0.0, -i * sample_offset), 0.0);
			if (pixel_up.a < 0.01) break; // Found the edge
			up_count += 1.0;
		}

		// Look down until we hit transparency (bottom edge of tentacle)
		for (float i = 1.0; i <= 20.0; i += 1.0) {
			vec4 pixel_down = textureLod(screen_texture, SCREEN_UV + vec2(0.0, i * sample_offset), 0.0);
			if (pixel_down.a < 0.01) break; // Found the edge
			down_count += 1.0;
		}

		// How wide is the tentacle at this point?
		float total_height = up_count + 1.0 + down_count;

		// The shade should be proportional to the width
		float shade_width = total_height * shade_ratio;

		// If we're close to the bottom edge (few pixels below us), we're in shadow
		bool is_bottom = down_count < shade_width;

		// Apply the two-tone coloring
		if (is_bottom) {
			c.rgb = dark_color.rgb; // Bottom pixels are dark
		} else {
			c.rgb = light_color.rgb; // Top pixels are light
		}
	}

	// Standard CanvasItem multiply with modulate
	COLOR *= c;
}
