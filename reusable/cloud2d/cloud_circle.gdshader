shader_type canvas_item;

uniform vec2 light_position = vec2(0.7, 0.3); // 光源位置 (相對座標 0-1)
uniform vec4 shadow_color : source_color = vec4(0.7, 0.7, 0.7, 1.0); // 陰影顏色
uniform float shadow_smoothness = 0.0; // 陰影過渡的平滑度
uniform float sphere_radius = 0.45; // 球體半徑
uniform float shadow_intensity = 1; // 陰影強度
uniform float bright_side_expansion = 0.06;

void fragment() {
    // 將 UV 座標轉換為中心為原點的座標系統
    vec2 uv = UV - vec2(0.5, 0.5);
    float dist = length(uv);

    // 創建圓形遮罩
    //float circle = smoothstep(sphere_radius + edge_width, sphere_radius - edge_width, dist);
    float circle = step(dist, sphere_radius);

    if (circle < 0.01) {
        COLOR = vec4(0.0); // 圓形外部透明
    } else {
        // 計算球體表面的法線（假設為球體）
        float z = sqrt(max(0.0, sphere_radius * sphere_radius + bright_side_expansion - dist * dist));
        vec3 normal = normalize(vec3(uv.x, uv.y, z));

        // 計算光照方向
        vec3 light_dir = normalize(vec3(light_position.x - 0.5, light_position.y - 0.5, 0.5));

        // 簡單的漫反射光照計算
        float diffuse = max(dot(normal, light_dir), 0.0);

        // 創建卡通風格的陰影（使用階梯函數）
        float toon_diffuse = smoothstep(0.3 - shadow_smoothness, 0.3 + shadow_smoothness, diffuse);

        // 使用 COLOR 來取得 modulate 顏色（這是節點的顏色屬性）
        vec4 base_color = COLOR;

        // 計算陰影版本的顏色
        vec4 shadowed = mix(base_color, shadow_color, shadow_intensity);
        //shadowed.rgb *= (1.0 - shadow_intensity);

        // 混合基礎顏色和陰影顏色
        vec4 final_color = mix(shadowed, base_color, toon_diffuse);

        COLOR = final_color * circle;
    }
}