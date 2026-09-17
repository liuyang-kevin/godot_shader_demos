// =============================================================
// 冰冻 (Frozen)
// 分类：状态影响
// -------------------------------------------------------------
// 表现"被冻住"：整体偏向冰蓝，再叠一层缓慢移动的冰晶纹理。
//
//   - 颜色：mix(原色, 冰色, freeze_amount * 0.6)
//     —— 只混 60%，避免角色变成一坨纯色；
//   - 冰晶：ice_texture 的 UV 随时间平移一点点（TIME * 0.02，很慢），
//     用"加法"而不是 mix 叠上去，所以是"高光/反光"而不是"覆盖"；
//     乘 freeze_amount 让冰冻越深，结晶越明显。
// 小技巧：ice_texture 用带方向性的噪声/裂纹图效果最好，
//         纯随机噪声看起来更像沙子。
// =============================================================

shader_type canvas_item;

// 冰冻程度 0~1
uniform float freeze_amount : hint_range(0.0, 1.0) = 0.0;
// 冰的颜色
uniform vec4 ice_color : source_color = vec4(0.5, 0.8, 1.0, 1.0);
// 冰晶纹理
uniform sampler2D ice_texture : hint_default_white;
// 结晶高光强度
uniform float crystal_intensity : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec4 texture_color = texture(TEXTURE, UV);
	// 冰晶缓慢横向漂移
	vec4 ice_pattern = texture(ice_texture, UV + vec2(TIME * 0.02, 0.0));

	// 1. 整体偏冷色
	vec3 frozen_color = mix(texture_color.rgb, ice_color.rgb, freeze_amount * 0.6);

	// 2. 叠加结晶高光（加法混合）
	frozen_color += ice_pattern.rgb * crystal_intensity * freeze_amount;

	COLOR = vec4(frozen_color, texture_color.a);
}
