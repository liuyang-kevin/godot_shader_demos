// =============================================================
// 隐身 (Invisibility)
// 分类：状态影响
// -------------------------------------------------------------
// 表现"潜行 / 半透明"：三个部分叠加。
//
//   ① 折射：用噪声扭曲 UV，强度 ∝ 隐身程度
//      → 隐身时背景被"空气折射"，这是隐身最有说服力的一笔；
//   ② 淡出：mix(原色, 黑, amount * 0.7) + alpha 乘 (1 - amount * 0.8)
//      → 注意这里没有完全透明，最多 80%，
//        故意留一点可见度让玩家/敌人还能看到轮廓；
//   ③ 边缘微光：只在靠近贴图边缘处保留一点蓝白色，
//      "只剩一个轮廓"是隐身最经典的视觉语言。
//      边缘检测这里用了简化的做法：
//        edge = 1 - smoothstep(|0.5 - UV.x|) * smoothstep(|0.5 - UV.y|)
//      它检测的是"贴图的四边"，而不是"精灵的轮廓"；
//      想检测真正的 alpha 轮廓，请参考 outline_glow.gdshader。
// =============================================================

shader_type canvas_item;

// 隐身程度 0~1
uniform float invisibility_amount : hint_range(0.0, 1.0) = 0.0;
// 折射强度
uniform float distortion_amount : hint_range(0.0, 0.05) = 0.02;
// 折射用的噪声
uniform sampler2D distortion_texture : hint_default_white;

void fragment() {
	// ① 折射
	vec2 distortion = texture(distortion_texture, UV + vec2(TIME * 0.1, 0.0)).rg;
	distortion = (distortion - 0.5) * distortion_amount * invisibility_amount;

	vec4 texture_color = texture(TEXTURE, UV + distortion);

	// ③ 边缘微光（靠近左右/上下边界时为 1）
	float edge = 1.0 - smoothstep(0.0, 0.2, abs(0.5 - UV.x)) * smoothstep(0.0, 0.2, abs(0.5 - UV.y));
	vec4 edge_glow = vec4(0.5, 0.8, 1.0, 1.0) * edge * invisibility_amount * 0.3;

	// ② 淡出 + ③ 加边缘光
	COLOR = mix(texture_color, vec4(0.0), invisibility_amount * 0.7) + edge_glow;
	COLOR.a = texture_color.a * (1.0 - invisibility_amount * 0.8);
}
