// =============================================================
// 变色 / 染色 (Color Change / Recolor)
// 分类：状态影响
// -------------------------------------------------------------
// 把精灵整体染成目标色，同时可选"保留原有明暗层次"。
//
//   1. luminance = dot(rgb, vec3(0.299, 0.587, 0.114))
//      按人眼敏感度算出的感知亮度；
//   2. mix(原色, 目标色, mix_amount)：线性混合；
//   3. preserve_luminance（本 shader 的精髓）：
//      混完色之后再算一次新亮度，然后
//        new_color *= 旧亮度 / 新亮度
//      把整体亮度"拉回"原来的水平。
//      这样暗部还是暗、亮部还是亮，只是色相变了，
//      角色的体积感/立体感不会被抹平。
//      —— 不做这一步的话，染成红色会让整只怪变成一块纯红的饼。
// 用途：队伍色、稀有度染色、狂暴化、冰冻/中毒的自定义颜色版。
// =============================================================

shader_type canvas_item;

// 目标颜色
uniform vec4 target_color : source_color = vec4(1.0, 0.3, 0.3, 1.0);
// 混合强度 (0.0 = 原色, 1.0 = 完全变色)
uniform float mix_amount : hint_range(0.0, 1.0) = 0.7;
// 是否保留原图明暗关系（强烈建议保持 true）
uniform bool preserve_luminance = true;

void fragment() {
	vec4 original_color = texture(TEXTURE, UV);

	// 原始亮度
	float luminance = dot(original_color.rgb, vec3(0.299, 0.587, 0.114));

	// 线性混色
	vec3 new_color = mix(original_color.rgb, target_color.rgb, mix_amount);

	// 把亮度拉回原值，保留立体感
	if (preserve_luminance) {
		float new_luminance = dot(new_color, vec3(0.299, 0.587, 0.114));
		if (new_luminance > 0.0) {   // 防止除零
			new_color *= luminance / new_luminance;
		}
	}

	COLOR = vec4(new_color, original_color.a);
}
