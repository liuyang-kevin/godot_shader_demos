// =============================================================
// 热浪扭曲 (Heat Distortion)
// 分类：粒子 / 环境特效
// -------------------------------------------------------------
// 原理：
//   和 water_surface 是同一个套路（UV 扰动），只是偏移量来源不同：
//   water_surface 用正弦波（规则、可预测），
//   这里用"噪声贴图"当偏移量（不规则、更像真实的空气对流）。
//   1. 噪声的 UV 随时间在两个轴上以不同速度平移
//      （0.1 / 0.2 的比值让流动方向是斜的）；
//   2. 取 rg 两通道当 x/y 偏移，减 0.5 把 [0,1] 变成 [-0.5,0.5]，
//      这样偏移有正有负，画面才是"扭"而不是"整体平移"；
//   3. 乘 distortion_amount 控制强度。
// 用途：篝火上方、夏天柏油路、爆炸余波、传送门边缘。
// =============================================================

shader_type canvas_item;

// 噪声流动速度
uniform float distortion_speed : hint_range(0.0, 5.0) = 2.0;
// 扭曲强度（单位：UV，0.03 已经是相当明显的扭曲）
uniform float distortion_amount : hint_range(0.0, 0.1) = 0.03;
// 噪声贴图：需要 repeat_enable，否则边缘会被拉丝
uniform sampler2D noise_texture : hint_default_white;

void fragment() {
	// 1. 让噪声 UV 斜向流动
	vec2 noise_uv = UV + vec2(TIME * distortion_speed * 0.1, TIME * distortion_speed * 0.2);

	// 2. rg 当偏移量，中心化到 [-0.5, 0.5]
	vec2 distortion = texture(noise_texture, noise_uv).rg;
	distortion = (distortion - 0.5) * distortion_amount;

	// 3. 用偏移后的 UV 采样原图 —— 画面就"热得抖起来"了
	vec4 texture_color = texture(TEXTURE, UV + distortion);
	COLOR = texture_color;
}
