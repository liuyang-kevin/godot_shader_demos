// =============================================================
// 径向模糊 (Radial / Zoom Blur)
// 分类：粒子 / 环境特效（画面后处理）
// -------------------------------------------------------------
// 原理：
//   沿"从中心指向当前像素"的方向，依次采样若干个点再求平均。
//   - direction = UV - blur_center：指向外侧的向量；
//   - 第 i 次采样把 UV 往中心方向拉回 t = i/(samples-1) 的比例：
//       texture(TEXTURE, UV - direction * strength * t)
//     于是每个像素都混入了"更靠中心"的一串像素 → 放射状拖尾；
//   - 中心点本身（direction = 0）完全不受影响，所以中心保持清晰。
// 用途：冲刺、冲击波、瞬移、被击中的速度线。
// 注意：
//   - for 循环里 i < samples 是动态上界，Godot 的 GLSL 需要 samples 为 uniform int，
//     循环次数在编译期未知，会有一定开销；低端设备建议固定为一个常量。
// =============================================================

shader_type canvas_item;

// 拉伸长度（UV 比例）
uniform float blur_strength : hint_range(0.0, 0.1) = 0.03;
// 放射中心（默认画面正中）
uniform vec2 blur_center = vec2(0.5, 0.5);
// 采样次数：越多越平滑、越贵
uniform int samples : hint_range(4, 32) = 16;

void fragment() {
	vec2 direction = UV - blur_center;

	vec4 color = vec4(0.0);
	for (int i = 0; i < samples; i++) {
		// t 从 0 到 1，采样点从"当前像素"一路拉回"接近中心"
		float t = float(i) / float(samples - 1);
		vec2 offset = direction * blur_strength * t;
		color += texture(TEXTURE, UV - offset);
	}

	COLOR = color / float(samples);
}
