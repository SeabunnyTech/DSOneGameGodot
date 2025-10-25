shader_type canvas_item;

uniform float time_scale : hint_range(0.0, 2.0) = 1.0;
uniform sampler2D noise_texture;
uniform float flame_speed : hint_range(0.0, 1.0) = 0.2;
uniform float variation_strength : hint_range(0.0, 2.0) = 0.15;
uniform float focus_inner : hint_range(0.0, 1.0) = 0.1;
uniform float focus_outer : hint_range(0.0, 1.0) = 0.35;

// 卡通風格控制參數
uniform int color_steps : hint_range(3, 10) = 4;

// 色調控制
uniform vec3 core_color = vec3(1.5, 1.15, 0.6);    // 核心
uniform vec3 edge_color = vec3(0.01, 0.1, 0.0);     // 邊緣
uniform float brightness_boost : hint_range(0.5, 2.0) = 1.0;

// 2D 特定參數
uniform vec2 flame_center = vec2(0.5, 0.5);
uniform float flame_scale : hint_range(0.1, 5.0) = 1.0;

// 新增：太陽移動速度和拖尾效果
uniform vec2 sun_velocity = vec2(0.0, 0.0);  // 太陽的移動速度向量
uniform float trail_strength : hint_range(0.0, 2.0) = 1.0;  // 拖尾強度

float get_noise(vec2 uv) {
    return texture(noise_texture, fract(uv)).r * 0.5 +
           texture(noise_texture, fract(uv * 2.0)).r * 0.25 + 0.25;
}

// 高效的色階化函數
float posterize_fast(float value, int steps) {
    return floor(value * float(steps) + 0.5) / float(steps);
}

void fragment() {
    // 將 UV 座標調整為以 flame_center 為中心
    vec2 uv = (UV - flame_center) * flame_scale;

    // 極坐標轉換
    float r = length(uv);
    float a = fract(atan(uv.y, uv.x) / (2.0 * PI) + 0.5);

    // 計算拖尾偏移：距離越遠，偏移越大
    // 偏移方向與速度相反（落後於移動方向）
    float trail_factor = smoothstep(0.0, 0.5, r) * trail_strength;
    vec2 trail_offset = -sun_velocity * trail_factor * r;

    // 應用拖尾偏移到 UV
    uv += trail_offset;

    // 重新計算極坐標（使用偏移後的 UV）
    r = length(uv);
    a = fract(atan(uv.y, uv.x) / (2.0 * PI) + 0.5);

    // 火焰動畫和噪音
    float t = TIME * time_scale * flame_speed;
    float noise = get_noise(vec2(r, a) + vec2(t, 0.0));

    // 應用變化
    r += (noise - 0.5) * variation_strength * smoothstep(0.05, 0.4, r);

    // 計算基礎值
    float focused = smoothstep(focus_inner, focus_outer, r);
    float brightness = 1.0 - focused;

    // 色階化
    float stepped_r = posterize_fast(r, color_steps);
    float stepped_brightness = posterize_fast(brightness, color_steps);

    // 顏色計算
    vec3 col = core_color * (1.0 - stepped_r) + edge_color * stepped_r;
    col *= brightness_boost;

    // Alpha 處理
    float alpha = stepped_brightness;

    COLOR = COLOR * vec4(col, alpha);
}