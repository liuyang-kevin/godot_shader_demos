// =============================================================
// 能量屏障 (Energy Barrier)
// 分类：粒子 / 环境特效
// -------------------------------------------------------------
// 原理：用 SDF（有向距离场）程序化画六边形蜂窝网格。
//   1. UV * hex_scale 放大 → 每个格子边长为 1 的坐标系；
//   2. 六边形网格要拆成两套交错的矩形格点：
//        a = mod(uv, r) - h
//        b = mod(uv - h, r) - h     （h = r/2，错开半格）
//      对任意一点，取离它更近的那个格点中心 → gv（格子局部坐标）；
//   3. hex_dist(p) 返回 p 到六边形边界的近似距离：
//        先 abs 对称到第一象限，再用 max(dot(p, normalize(1,√3)), p.x)
//      这是"六边形 = 6 个方向的半平面交集"的简化写法；
//   4. smoothstep(0.05, 0.02, abs(dist - 0.5)) 只保留 dist≈0.5 的一圈
//      → 得到六边形的"边框线"；
//   5. 边框 × 脉冲 × 屏障色，加到原图上（additive 发光）。
// 要点：
//   - 这种"取最近格点 + 距离场描边"是画蜂窝 / 三角格 / 方格的通用套路；
//   - 加在精灵上就是护盾罩，铺满屏就是扫描网格。
// =============================================================

shader_type canvas_item;

// 六边形密度（越大格子越小）
uniform float hex_scale : hint_range(1.0, 50.0) = 20.0;
// 屏障颜色
uniform vec4 barrier_color : source_color = vec4(0.3, 0.7, 1.0, 0.8);
// 呼吸脉冲速度
uniform float pulse_speed : hint_range(0.0, 10.0) = 3.0;
// 边框亮度（>1 会让边框过曝，更像发光）
uniform float edge_brightness : hint_range(0.0, 2.0) = 1.5;

// 六边形距离函数：返回点 p 到六边形外接轮廓的近似距离
float hex_dist(vec2 p) {
	p = abs(p);                                   // 对称到第一象限，只需算 1/4
	float c = dot(p, normalize(vec2(1.0, 1.732))); // 1.732 ≈ √3，六边形的斜边方向
	return max(c, p.x);                            // 两个半平面取交集
}

void fragment() {
	vec2 uv = UV * hex_scale;
	vec2 r = vec2(1.0, 1.732);                     // 六边形网格的重复周期
	vec2 h = r * 0.5;                              // 错开半格，形成交错网格

	// 两套格点，取更近的那个作为当前格中心
	vec2 a = mod(uv, r) - h;
	vec2 b = mod(uv - h, r) - h;
	vec2 gv = length(a) < length(b) ? a : b;

	// 只保留 dist≈0.5 的一圈 → 六边形边框（注意 smoothstep 起止反着写，得到"线"）
	float dist = hex_dist(gv);
	float hex = smoothstep(0.05, 0.02, abs(dist - 0.5));

	// 整体呼吸：0.4 ~ 1.0 之间脉动
	float pulse = sin(TIME * pulse_speed) * 0.3 + 0.7;

	vec4 texture_color = texture(TEXTURE, UV);
	vec4 hex_pattern = barrier_color * hex * edge_brightness * pulse;

	// 0.3 的屏障底色（像一层淡蓝玻璃） + 边框发光（相加，越界即过曝）
	COLOR = mix(texture_color, barrier_color, 0.3) + hex_pattern;
}
