// =============================================================
// 溶解 (Dissolve)
// 分类：状态影响
// -------------------------------------------------------------
// 死亡消失 / 传送 / 刷新的经典做法：用噪声当作"消失的顺序表"。
//
//   对每个像素：
//     noise = 噪声贴图在 UV 处的值（0~1），可理解为"这个像素的编号"
//     dissolve_amount = 当前溶解进度（也可以理解为"阈值"）
//     alpha = smoothstep(amount, amount + edge_width, noise)
//       → noise 小于阈值的像素被判"已消失"(alpha 0)，
//         大于阈值的还在，中间 edge_width 那一段是半透明的过渡带。
//
//   边缘发光是第二个 smoothstep 做出来的"环带"：
//     edge = smoothstep(a, a+w, n) * (1 - smoothstep(a+w*0.5, a+w, n))
//     即"已进入过渡带" 且 "还没完全消失" 的那一圈 → 描上 edge_color。
//
// 要点：
//   - 噪声贴图的选择决定溶解的质感：
//     白噪声 → 沙化/像素飘散；Perlin 噪声 → 大块剥落/燃烧；
//   - 想做"燃烧式溶解"就把 edge_color 改橙色并加大 edge_width。
// =============================================================

shader_type canvas_item;

// 溶解进度 0~1
uniform float dissolve_amount : hint_range(0.0, 1.0) = 0.0;
// 噪声（决定消失的先后顺序）
uniform sampler2D dissolve_texture : hint_default_white;
// 溶解边缘的颜色（常配橙/青/紫）
uniform vec4 edge_color : source_color = vec4(1.0, 0.5, 0.0, 1.0);
// 边缘宽度（UV 比例）
uniform float edge_width : hint_range(0.0, 0.2) = 0.05;

void fragment() {
	vec4 texture_color = texture(TEXTURE, UV);
	float noise = texture(dissolve_texture, UV).r;

	// 主体：以 dissolve_amount 为阈值做软裁剪
	float dissolve_edge = dissolve_amount + edge_width;
	float alpha = smoothstep(dissolve_amount, dissolve_edge, noise);

	// 边缘环带：在 [amount, amount+width] 之间，且靠近前段
	float edge = smoothstep(dissolve_amount, dissolve_amount + edge_width, noise);
	edge = edge * (1.0 - smoothstep(dissolve_amount + edge_width * 0.5, dissolve_edge, noise));

	// 边缘处染成 edge_color，其余保留原图
	COLOR = mix(texture_color, edge_color, edge);
	COLOR.a = texture_color.a * alpha;
}
