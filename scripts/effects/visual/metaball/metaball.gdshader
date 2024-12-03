shader_type canvas_item;

// 分開定義球體屬性的陣列
uniform vec2 ball_positions[5];
uniform float ball_radii[5];
uniform vec4 ball_colors[5];
uniform int ball_count : hint_range(1, 5) = 3;


float metaball(vec2 uv, vec2 center, float radius) {
    float dist = length(uv - center);
    return radius / dist;
}


void fragment() {
    vec2 uv = UV;
    float total_influence = 0.0;
    vec4 final_color = vec4(0.0);

    // 計算每個球體對當前像素的影響
    for (int i = 0; i < ball_count; i++) {
        float influence = metaball(uv, ball_positions[i], ball_radii[i]);
        total_influence += influence;
        final_color += ball_colors[i] * influence;
    }

    // 根據總影響力決定像素顏色
    float threshold = 1.0;
    if (total_influence > threshold) {
        final_color /= total_influence;
        COLOR = final_color;
    } else {
        COLOR = vec4(0.0);
    }
}