// =============================================================
// 色差 / RGB 分离 (Chromatic Aberration)
// 分类：粒子 / 环境特效（画面后处理）
// -------------------------------------------------------------
// 原理：
//   模拟镜头对不同波长光的折射率不同 —— 三个颜色通道各采样一次，
//   R 向正方向偏、B 向负方向偏、G 保持原位，再拼回一个颜色。
//   于是物体边缘出现"红蓝描边"，越靠边越明显（如果偏移量随距离变化）。
// 要点：
//   - 只需 3 次采样，非常便宜，是性价比最高的"打击感"后处理；
//   - aberration_direction 是单位向量，决定分离方向；
//     让它随时间旋转就能做出"屏幕被震歪"的感觉。
// =============================================================

shader_type canvas_item;

// 分离距离（UV 比例，0.01 就相当明显了）
uniform float aberration_amount : hint_range(0.0, 0.1) = 0.01;
// 分离方向（建议传单位向量）
uniform vec2 aberration_direction = vec2(1.0, 0.0);

void fragment() {
	vec2 offset = aberration_direction * aberration_amount;

	// 三个通道分别在不同位置采样
	float r = texture(TEXTURE, UV + offset).r;
	float g = texture(TEXTURE, UV).g;
	float b = texture(TEXTURE, UV - offset).b;
	// alpha 用原位置，避免出现半透明的鬼影边缘
	float a = texture(TEXTURE, UV).a;

	COLOR = vec4(r, g, b, a);
}
