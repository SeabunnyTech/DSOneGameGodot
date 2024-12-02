shader_type canvas_item;

uniform sampler2D texture_a;
uniform sampler2D texture_b;
uniform float transition : hint_range(0.0, 1.0);

void fragment() {
    vec4 color_a = texture(texture_a, UV);
    vec4 color_b = texture(texture_b, UV);
	COLOR = mix(color_a, color_b, transition);
}
