shader_type canvas_item;

uniform float alpha = 1.0;
const vec2 resolution = vec2(3840.0, 2160.0);
uniform vec2 mask_center = vec2(1920, 1080);
uniform float mask_radius = 600;

void fragment() {
    // Calculate distance from current pixel to mask center
    vec2 delta = UV * resolution - mask_center;
    
    // Create smooth circular mask
    float mask = step(mask_radius * mask_radius, dot(delta, delta));
    
    // Set alpha based on mask
    COLOR.a = mask * alpha;
}