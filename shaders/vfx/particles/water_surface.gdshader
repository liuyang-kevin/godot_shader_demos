// =============================================================
// 水面波纹 (Water Surface)
// 分类：粒子 / 环境特效
// -------------------------------------------------------------
// 原理：
//   最基础的"UV 扰动"（UV distortion / refraction）：
//   1. 用 sin/cos 按 UV.y / UV.x 生成两组正交的正弦波，
//      再乘上 TIME * wave_speed 让波峰移动；
//   2. 把波当作一个偏移量加到采样 UV 上：
//      texture(TEXTURE, UV + wave_offset)
//      —— 这不会移动物体，只是"采样时取旁边的像素"，
//         于是画面看起来像隔着水面在晃动；
//   3. 最后整体乘一个水色 tint，让画面偏蓝、偏透。
// 要点：
//   - 任何"热浪 / 水面 / 玻璃 / 传送门扭曲"本质都是这一行：
//     texture(TEXTURE, UV + offset)；
//   - 区别只在于 offset 从哪来（正弦 / 噪声 / 极坐标）。
// =============================================================

shader_type canvas_item;

// 波的传播方向（这里只作为阅读用，实际由 sin/cos 的正交组合决定）
uniform vec2 wave_direction = vec2(1.0, 0.0);
// 波速
uniform float wave_speed : hint_range(0.0, 5.0) = 1.0;
// 波密度（越大波纹越密）
uniform float wave_frequency : hint_range(0.0, 20.0) = 5.0;
// 波幅（单位：UV，0.02 约等于 2% 的画面尺寸）
uniform float wave_amplitude : hint_range(0.0, 0.1) = 0.02;
// 水色（相乘染色）
uniform vec4 water_tint : source_color = vec4(0.5, 0.7, 1.0, 0.8);

void fragment() {
	// 1. 生成正交的两组波：
	//    x 偏移用 sin(UV.y ...)，y 偏移用 cos(UV.x ...)
	//    这样水面会呈"斜向交叉"的网格状晃动，而不是单向拉伸
	vec2 wave_offset = vec2(
		sin(UV.y * wave_frequency + TIME * wave_speed) * wave_amplitude,
		cos(UV.x * wave_frequency + TIME * wave_speed) * wave_amplitude
	);

	// 2. 扰动采样 + 3. 水色叠加
	vec4 texture_color = texture(TEXTURE, UV + wave_offset);
	COLOR = texture_color * water_tint;
}
