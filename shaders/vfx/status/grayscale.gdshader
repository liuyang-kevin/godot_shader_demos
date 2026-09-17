// =============================================================
// 灰度 (Grayscale)
// 分类：状态影响
// -------------------------------------------------------------
// 去色：把 rgb 全部替换成亮度值，再按 amount 与原图混合。
//
//   亮度权重的两种常见选择：
//     Rec.601  vec3(0.299, 0.587, 0.114)  —— 本文件用的，偏"老电视"
//     Rec.709  vec3(0.2126, 0.7152, 0.0722) —— 高清标准，绿权重更高
//   两者差别很小，关键是"三个数加起来 = 1"，
//   这样白依然是白、灰依然是灰（不会整体变亮/变暗）。
//
// 用途：慢动作、闪回、死亡/石化前摇、不可选中的灰化 UI。
// =============================================================

shader_type canvas_item;

// 灰度程度 0~1
uniform float grayscale_amount : hint_range(0.0, 1.0) = 0.0;
// 亮度权重（三个分量之和应为 1.0）
uniform vec3 luminance_weights = vec3(0.299, 0.587, 0.114);

void fragment() {
	vec4 texture_color = texture(TEXTURE, UV);

	// 点积求亮度，再扩展成灰度三通道
	float luminance = dot(texture_color.rgb, luminance_weights);
	vec3 grayscale = vec3(luminance);

	// 只影响 rgb，alpha 保持不变
	COLOR = vec4(mix(texture_color.rgb, grayscale, grayscale_amount), texture_color.a);
}
