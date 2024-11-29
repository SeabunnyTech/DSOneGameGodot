shader_type canvas_item;

uniform vec2 wave_strength = vec2(0.3, 0.5); // Controls wave movement
uniform float speed = 3.0;

void fragment() {
    // Create wave effect
    vec2 wave = vec2(
        sin(TIME * speed + UV.x * 10.0) * wave_strength.x,
        cos(TIME * speed + UV.y * 10.0) * wave_strength.y
    );
    
    // Sample texture with wave offset
    vec4 color = texture(TEXTURE, UV + wave * 0.02);
    
    COLOR = color;
}