// =============================================================
// 晕影 (Vignette)
// 分类：粒子 / 环境特效（画面后处理）
// -------------------------------------------------------------
// 原理：
//   按"到画面中心的距离"做一个遮罩，边缘压暗（或染色），中心保持不变。
//   1. dist = distance(UV, 0.5)  中心 0，四角约 0.707；
//   2. smoothstep(size, size - 0.5, dist)：
//      起止参数反着写 → dist 越小结果越接近 1，越大越接近 0，
//      也就是"中心为 1（不遮挡）、边缘为 0（全遮挡）"；
//   3. 再 1.0 - 该值 得到"边缘强度"，乘 strength 后用来混色。
// 用途：聚焦视线、低血量红边、受击反馈、电影感。
// =============================================================

shader_type canvas_item;

// 强度：0 = 无效果，1 = 边缘完全变成 vignette_color
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.5;
// 半径：越小晕影越早出现（暗区越大）
uniform float vignette_size : hint_range(0.0, 2.0) = 0.8;
// 晕影颜色（默认红色 → 低血量警告）
uniform vec4 vignette_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);

void fragment() {
	vec4 texture_color = texture(TEXTURE, UV);

	// 到中心的距离
	vec2 center = vec2(0.5, 0.5);
	float dist = distance(UV, center);

	// 生成"中心 1、边缘 0"的遮罩，再翻转成"边缘强度"
	float vignette = smoothstep(vignette_size, vignette_size - 0.5, dist);
	vignette = 1.0 - vignette;

	// 这里是"乘以晕影色"而不是"混向晕影色"，
	// 效果相当于给边缘加一层彩色滤镜（红边会保留原图细节）
	COLOR = mix(texture_color, texture_color * vignette_color, vignette * vignette_strength);
}
