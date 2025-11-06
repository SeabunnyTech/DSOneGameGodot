shader_type canvas_item;

// Metaball properties
uniform vec2 ball_positions[5];
uniform float ball_radii[5];
uniform int ball_count : hint_range(1, 5) = 1;

// Contour line properties
uniform float start_radius : hint_range(0.01, 1.0) = 0.1;
uniform float radius_step : hint_range(0.01, 0.5) = 0.1;
uniform int line_count : hint_range(1, 10) = 5;
uniform float pixel_line_width : hint_range(0.5, 10.0) = 2.0;
uniform float fade_factor : hint_range(0.0, 1.0) = 0.7; // How much the lines fade out. 0=no fade, 1=full fade.

// The metaball influence function
float metaball_influence(vec2 uv, vec2 center, float radius) {
    float dist = max(length(uv - center), 0.0001);
    return radius / dist;
}

void fragment() {
    vec2 uv = UV;
    float total_influence = 0.0;

    for (int i = 0; i < ball_count; i++) {
        total_influence += metaball_influence(uv, ball_positions[i], ball_radii[i]);
    }

    float alpha = 0.0;

    if (ball_count > 0 && total_influence > 0.0) {
        float reference_ball_radius = ball_radii[0];

        // 1. Transform from influence space to "effective radius" space
        float R_eff = reference_ball_radius / total_influence;

        // 2. Normalize the effective radius to get a floating-point line index
        float line_index_float = (R_eff - start_radius) / radius_step;

        // 3. Only draw if we are within the desired range of lines
        if (line_index_float >= -0.5 && line_index_float < float(line_count) - 0.5) {
            // 4. Use fract() to get the distance to the nearest integer line index (a triangle wave)
            float dist_to_line = abs(fract(line_index_float + 0.5) - 0.5);

            // 5. CORRECTED: Use built-in fwidth on the space we are drawing in (line_index_float)
            float fwidth_line_index = fwidth(line_index_float);

            // 6. Calculate the line alpha based on the distance
            float line_alpha = 1.0 - smoothstep(0.0, pixel_line_width * fwidth_line_index, dist_to_line * 2.0);

            // 7. CORRECTED: Use the integer line index for a consistent fade per line
            float line_index_int = floor(line_index_float + 0.5);
            float fade = 1.0 - (line_index_int / float(line_count - 1)) * fade_factor;

            alpha = line_alpha * clamp(fade, 0.0, 1.0);
        }
    }

	// The incoming COLOR already contains the modulated color.
    // We just need to apply our shape's alpha to it.
    COLOR.a *= clamp(alpha, 0.0, 1.0);
}
