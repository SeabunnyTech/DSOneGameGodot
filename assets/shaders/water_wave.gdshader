shader_type canvas_item;

uniform vec2 wave_strength = vec2(1.0, 0.5);
uniform float wave_speed = 2.0;

uniform float bubble_density = 0.2;
uniform float bubble_speed = 0.015;

// Helper function for random value
float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

// Create circular bubble pattern
float create_bubble(vec2 uv, vec2 center, float radius, float texture_aspect_ratio) {
    
    // Scale UV coordinates to make bubbles more circular
    vec2 scaled_uv = vec2(uv.x * texture_aspect_ratio, uv.y);  
    vec2 scaled_center = vec2(center.x * texture_aspect_ratio, center.y);
    
    float dist = length(scaled_uv - scaled_center);
    return smoothstep(radius, radius * 0.8, dist);
}
void fragment() {
    // Original wave effect
    vec2 wave_uv = UV;
    wave_uv.x += sin(UV.y * 10.0 + TIME * wave_speed) * wave_strength.x * 0.01;
    wave_uv.y += cos(UV.x * 10.0 + TIME * wave_speed) * wave_strength.y * 0.01;
    
    // Retrieve the texture pixel size (1/width, 1/height)
    vec2 texture_pixel_size = TEXTURE_PIXEL_SIZE;

    // Calculate aspect ratio: width / height
    float texture_aspect_ratio = texture_pixel_size.y / texture_pixel_size.x;

    // Bubble effect
    float bubble = 0.0;
    for(float i = 0.0; i < 3.0; i++) {
        // Create grid for bubble positions
        vec2 bubble_uv = UV * (3.5 + i);
        vec2 grid_id = floor(bubble_uv);
        vec2 grid_uv = fract(bubble_uv);
        
        // Animate bubble position
        vec2 bubble_center = vec2(
            random(grid_id),
            fract(random(grid_id + 1.0) - TIME * bubble_speed * (1.0 + i * 0.1))
        );
        
        // Create circular bubble
        float bubble_size = 0.045 - i * 0.01;
        bubble += create_bubble(grid_uv, bubble_center, bubble_size, texture_aspect_ratio) * (1.0 - i * 0.2);
    }

    vec4 color = texture(TEXTURE, wave_uv);
    color.rgb += bubble * bubble_density * color.a;
    
    COLOR = color;
}