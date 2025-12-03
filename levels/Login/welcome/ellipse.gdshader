shader_type canvas_item;

uniform vec4 color : source_color = vec4(.4, .4, .4, 1.0); // 橢圓顏色

void fragment() {
	// 將 UV 座標從 0~1 轉換到 -0.5~0.5 (把中心點移到中間)
	vec2 uv = UV - 0.5;
	
	// 計算點到中心的距離。
	// 因為 UV 會隨著 Control 的長寬比拉伸，所以這裡直接畫圓形
	// 就會自動被 Control 的尺寸拉伸成橢圓。
	float d = length(uv);
	
	// 如果距離大於 0.5 (半徑)，就丟棄該像素 (變透明)
	// 使用 step 或 smoothstep 來做邊緣反鋸齒
	float alpha = 1.0 - smoothstep(0.49, 0.5, d);
	
	COLOR = COLOR * vec4(color.rgb, alpha * color.a);
}