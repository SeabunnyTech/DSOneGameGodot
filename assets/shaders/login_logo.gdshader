shader_type canvas_item;

uniform vec4 tint_color : source_color = vec4(1.0);

void fragment() {
    vec4 texture_color = texture(TEXTURE, UV);
    COLOR = vec4(tint_color.rgb, texture_color.a * tint_color.a);
}