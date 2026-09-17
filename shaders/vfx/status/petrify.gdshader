// =============================================================
// 石化 (Petrify)
// 分类：状态影响
// -------------------------------------------------------------
// 表现"变成石头"：去饱和 → 混向石灰色 → 叠裂纹。
//
//   - 去饱和：gray = dot(rgb, vec3(0.299, 0.587, 0.114))
//     这是 Rec.601 亮度权重（人眼对绿最敏感），
//     几乎所有"灰度/去色"shader 都用这三个数；
//   - 再 mix(gray, stone_color, 0.5)：不是纯灰，而是"带一点石色的灰"，
//     比直接变成灰色更像石头；
//   - 裂纹：贴图的 r 通道当遮罩，用
//     mix(color, color * 0.5, mask) 把裂纹处压暗一半。
//     这种"用遮罩在两档亮度间插值"的写法，比直接乘更可控。
// =============================================================

shader_type canvas_item;

// 石化程度 0~1
uniform float petrify_amount : hint_range(0.0, 1.0) = 0.0;
// 石头颜色
uniform vec4 stone_color : source_color = vec4(0.5, 0.5, 0.5, 1.0);
// 裂纹贴图（r 通道为遮罩）
uniform sampler2D crack_texture : hint_default_white;
// 裂纹明显程度
uniform float crack_intensity : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec4 texture_color = texture(TEXTURE, UV);
	vec4 cracks = texture(crack_texture, UV);

	// 去饱和 + 混一点石色
	float gray = dot(texture_color.rgb, vec3(0.299, 0.587, 0.114));
	vec3 stone = mix(vec3(gray), stone_color.rgb, 0.5);

	// 在原图与石头之间过渡
	vec3 petrified = mix(texture_color.rgb, stone, petrify_amount);

	// 按裂纹遮罩压暗（0.5 倍亮度）
	petrified = mix(petrified, petrified * 0.5, cracks.r * crack_intensity * petrify_amount);

	COLOR = vec4(petrified, texture_color.a);
}
