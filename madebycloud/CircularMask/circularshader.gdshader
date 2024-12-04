shader_type canvas_item;

uniform vec2 resolution = vec2(3840.0, 2160.0);
uniform vec2 mask_center = vec2(1920, 1080);
uniform float mask_radius : hint_range(0.0, 1.0) = 600;
uniform float smoothness : hint_range(0.0, 0.5) = 0.0;

void fragment() {
    // Calculate distance from current pixel to mask center
    float distance = length(UV * resolution - mask_center);
    
    // Create smooth circular mask
    float mask = smoothstep(
        mask_radius, 
        mask_radius + smoothness, 
        distance
    );
    
    // Set alpha based on mask
    COLOR.a = mask;
}