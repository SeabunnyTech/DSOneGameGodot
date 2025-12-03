shader_type canvas_item;

// --- 參數設定 ---
uniform vec4 shine_color : source_color = vec4(1.0, 1.0, 1.0, 0.4);
uniform float sweep_time : hint_range(0.1, 5.0) = 2.5;
uniform float shine_width : hint_range(0.01, 1.0) = 0.6;
uniform float shine_angle : hint_range(0.0, 360.0) = -30.0;
uniform float pause_duration : hint_range(0.0, 10.0) = 2.0;

// 長寬比修正
uniform float button_aspect_ratio : hint_range(0.5, 10.0) = 4.05;

void fragment() {
	// [修改 1] 獲取 Godot 傳入的 Modulate 顏色 (包含透明度變化)
	vec4 modulate_color = COLOR;
	
	// [修改 2] 將原始圖片顏色 "乘上" Modulate 顏色
	// 這樣當你調整 Inspector 的 Modulate 時，按鈕才會變色或變透明
	vec4 base_color = texture(TEXTURE, UV) * modulate_color;
	
	// --- 時間與座標計算 (保持不變) ---
	float total_cycle = sweep_time + pause_duration;
	float current_time = mod(TIME, total_cycle);
	float progress = smoothstep(0.0, sweep_time, current_time);

	vec2 visual_pos = vec2(UV.x * button_aspect_ratio, UV.y);
	float angle_rad = radians(shine_angle);
	vec2 direction = vec2(cos(angle_rad), sin(angle_rad));
	float position_on_line = dot(visual_pos, direction);

	float border = button_aspect_ratio + 1.0; 
	float start_pos = -border;
	float end_pos = border;
	float current_shine_center = mix(start_pos, end_pos, progress);

	// --- 光條強度 ---
	float intensity = smoothstep(current_shine_center - shine_width, current_shine_center, position_on_line) -
	                  smoothstep(current_shine_center, current_shine_center + shine_width, position_on_line);

	// --- [修改 3] 合成邏輯微調 ---
	// 這裡使用 base_color.a，因為它現在已經包含了 Modulate 的透明度
	// 如果整個按鈕變半透明，反光也會跟著變淡
	vec3 final_rgb = base_color.rgb + (shine_color.rgb * intensity * base_color.a * shine_color.a);
	
	COLOR = vec4(final_rgb, base_color.a);
}