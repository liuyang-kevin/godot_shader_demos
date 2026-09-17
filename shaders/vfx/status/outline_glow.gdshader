// =============================================================
// 轮廓发光 (Outline Glow)
// 分类：状态影响
// -------------------------------------------------------------
// 不改角色本身，只在"精灵的外部一圈"描边 → 用来表示
// 选中 / 可交互 / 高亮 / 被锁定 等状态。
//
// 边缘检测（最朴素的 alpha 版）：
//   1. 以当前像素为圆心，在半径 step_size 的圆周上采样 8 个点，
//      把它们的 alpha 累加成 alpha_sum；
//   2. 判断"当前像素是透明的(alpha≈0)，但周围有不透明像素"：
//        outline = step(0.1, alpha_sum) * (1.0 - texture_color.a)
//      step(0.1, alpha_sum)  = 周围至少有一点点不透明 → 1
//      (1 - 自身 alpha)      = 自己在精灵外面 → 1
//      两者相乘 = 正好落在轮廓外侧的一圈；
//   3. 把这圈染成 outline_color * glow_intensity，
//      alpha 取 max(原 alpha, outline) 让描边能画到透明区上。
//
// 局限：
//   - 采样半径 outline_width / 100.0 是硬编码的换算，
//     贴图分辨率不同时描边粗细会变，需要按实际情况调；
//   - 只在**贴图还有空余透明边距**时有效，
//     如果精灵已经把图撑满（边缘就是 alpha=1），外圈会画不出来。
// =============================================================

shader_type canvas_item;

// 描边颜色
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 0.5, 1.0);
// 采样半径（越粗轮廓越宽）
uniform float outline_width : hint_range(0.0, 10.0) = 2.0;
// 发光强度（>1 会过曝，配合 bloom 效果最好）
uniform float glow_intensity : hint_range(0.0, 2.0) = 1.0;

void fragment() {
	vec4 texture_color = texture(TEXTURE, UV);

	// 绕一圈采样邻域 alpha
	float alpha_sum = 0.0;
	float samples = 8.0;
	float step_size = outline_width / 100.0;

	for (float angle = 0.0; angle < 6.28318; angle += 6.28318 / samples) {
		vec2 offset = vec2(cos(angle), sin(angle)) * step_size;
		alpha_sum += texture(TEXTURE, UV + offset).a;
	}

	// 自己是透明的 + 周围有不透明的 → 判定为外轮廓
	float outline = step(0.1, alpha_sum) * (1.0 - texture_color.a);

	// 角色内部保持原样，只在轮廓处染色
	COLOR = mix(texture_color, outline_color * glow_intensity, outline);
	// 用 max 让描边能绘制到原本全透明的区域上
	COLOR.a = max(texture_color.a, outline);
}
