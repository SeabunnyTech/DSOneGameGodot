shader_type canvas_item;

// 球體屬性
uniform vec2 ball_positions[5];
uniform float ball_radii[5];
uniform int ball_count : hint_range(1, 5) = 3;


float metaball(vec2 uv, vec2 center, float radius) {
    float dist = length(uv - center);
    return radius / dist;
}


void fragment() {
    vec2 uv = UV;
    float total_influence = 0.0;

    // 計算每個球體對當前像素的影響
    for (int i = 0; i < ball_count; i++) {
        total_influence += metaball(uv, ball_positions[i], ball_radii[i]);
    }

    // 根據總影響力決定像素的 Alpha 值，RGB 顏色由 modulate 決定
    float threshold = 1.0;
    if (total_influence > threshold) {
		// 保留傳入的顏色(COLOR.rgb)，只修改 alpha
		// 使用 smoothstep 讓邊緣更平滑
        COLOR.a *= step(threshold, total_influence);
    } else {
        COLOR.a = 0.0;
    }
}