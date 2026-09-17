// =============================================================
// 燃烧 (Burning)
// 分类：状态影响
// -------------------------------------------------------------
// 表现"着火"DEBUFF：底部先烧起来，火苗向上舔，画面带热浪扭曲。
//
//   - 热浪：噪声贴图当 UV 偏移（同 heat_distortion），
//     强度再乘 burn_amount，所以"烧得越狠抖得越厉害"；
//   - 火焰色：两色按 sin(UV.y * 10 - TIME * 5) 上下流动地渐变，
//     做出火苗往上窜的层次；
//   - 燃烧边界：smoothstep(0.3, 0.7, UV.y + burn_amount * 1.5 - 0.5)
//     —— 注意 UV.y 在 Godot 里向下增大，所以这里是"从下往上烧"；
//     burn_amount 越大，边界越往上推。
// 用法：burn_amount 0 → 1 就是"点燃 → 全身是火"。
// =============================================================

shader_type canvas_item;

// 燃烧进度 0~1（0 = 没烧，1 = 烧满）
uniform float burn_amount : hint_range(0.0, 1.0) = 0.0;
// 火焰的两段渐变色
uniform vec4 fire_color1 : source_color = vec4(1.0, 0.8, 0.2, 1.0);
uniform vec4 fire_color2 : source_color = vec4(1.0, 0.3, 0.0, 1.0);
// 热浪扭曲用的噪声（不给贴图时默认是纯白 → 无扭曲）
uniform sampler2D distortion_texture : hint_default_white;
// 热浪强度
uniform float distortion_strength : hint_range(0.0, 0.1) = 0.03;

void fragment() {
	// 热浪扭曲：噪声随时间流动，幅度再被 burn_amount 调制
	vec2 distortion = texture(distortion_texture, UV + vec2(TIME * 0.1, TIME * 0.2)).rg;
	distortion = (distortion - 0.5) * distortion_strength * burn_amount;

	vec4 texture_color = texture(TEXTURE, UV + distortion);

	// 火焰颜色动画：沿 Y 轴的正弦条纹向上流动
	float fire_gradient = sin(UV.y * 10.0 - TIME * 5.0) * 0.5 + 0.5;
	vec4 fire_color = mix(fire_color1, fire_color2, fire_gradient);

	// 燃烧边界：从下往上推进
	float burn_edge = smoothstep(0.3, 0.7, UV.y + burn_amount * 1.5 - 0.5);

	// 只混 0.6 * burn_amount，保留一部分原图细节，不至于糊成一团火
	COLOR = mix(texture_color, fire_color, burn_edge * burn_amount * 0.6);
	COLOR.a = texture_color.a;
}
