shader_type canvas_item;
uniform vec4 hint_color = vec4(0, 1, 1, 1);

uniform vec2 ball1_position = vec2(0.5, 0.5);
uniform vec2 ball2_position = vec2(0.3, 0.3);
uniform float ball1_radius = 0.1;
uniform float ball2_radius = 0.1;
uniform float smoothness = 0.01;

float metaball(vec2 uv, vec2 center, float radius) {
    float dist = length(uv - center);
    return radius / dist;
}

void fragment() {
    vec2 uv = UV;
    
    // 計算兩個球體的場強度
    float m1 = metaball(uv, ball1_position, ball1_radius);
    float m2 = metaball(uv, ball2_position, ball2_radius);
    
    // 合併場強度
    float combined = m1 + m2;
    
    // 使用 smoothstep 來創建平滑的邊緣
    float final = smoothstep(1.0 - smoothness, 1.0 + smoothness, combined);
    // 輸出顏色
    COLOR = vec4(vec3(final), final) * hint_color;
}