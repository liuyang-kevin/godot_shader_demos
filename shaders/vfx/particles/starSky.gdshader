// =============================================================
// 滚动星空 (Starfield)
// 分类：粒子 / 环境特效
// -------------------------------------------------------------
// 原理：
//   纯程序化生成，不使用任何贴图。
//   1. 把 UV 按 small_stars / large_stars 划分成若干"星轨"(行/列)；
//   2. 用 fract(sin(floor(...)) * ...) 伪造每行一个随机数 rn；
//      rn 同时决定这颗星的颜色插值、大小和滚动速度（视差）；
//   3. 把 UV 映射到 [-1,1] 的小坐标系，用 length(uv) 画圆/十字，
//      得到"远小近大、有明暗层次"的星星；
//   4. 用 fract(UV.x + speed * time) 让星星横向循环滚动。
// 要点：
//   - 这是典型的 hash 随机（sin 大数取小数部分），不是真实随机；
//   - 属于"粒子感"特效：看起来像很多粒子，实际是纯 fragment 计算；
//   - 一般铺在 ColorRect / TextureRect 上做背景。
// 原作者：Brian Smith (steampunkdemon.itch.io) — MIT Licence
// =============================================================

shader_type canvas_item;

// 节点的像素尺寸（影响星星的宽高比，铺在 ColorRect 上时填 ColorRect 的大小）
uniform vec2 dimensions = vec2(1024.0, 600.0);

// 小星星数量：横向滚动时表示"行数"
uniform float small_stars = 50.0;
uniform float small_stars_far_size : hint_range(0.1, 1.0, 0.1) = 0.5;   // 最远（最暗）小星半径
uniform float small_stars_near_size : hint_range(0.1, 1.0, 0.1) = 1.0;  // 最近（最亮）小星半径

// 大星星数量：横向滚动时表示"行数"
uniform float large_stars = 8.0;
uniform float large_stars_far_size : hint_range(0.1, 1.0, 0.1) = 0.5;
uniform float large_stars_near_size : hint_range(0.1, 1.0, 0.1) = 1.0;

// 远近两色：rn 越接近 1 的星越"近"，颜色越靠近 near_stars_color
uniform vec4 far_stars_color : source_color = vec4(0.50, 0.0, 1.0, 1.0);
uniform vec4 near_stars_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// 基础滚动速度 + 随机附加速度（附加速度 × rn 形成视差）
uniform float base_scroll_speed : hint_range(0.0, 1.0, 0.01) = 0.05;
uniform float additional_scroll_speed : hint_range(0.01, 1.0, 0.01) = 0.05;

// 若想用贴图代替程序化画星，取消下面两个 sampler 的注释并在底部启用对应分支
// uniform sampler2D small_stars_texture : source_color, filter_nearest_mipmap;
// uniform sampler2D large_stars_texture : source_color, filter_nearest_mipmap;

// 阶跃函数：x > y 返回 1，否则 0（用来画"硬边"图形，替代 if 分支）
float greater_than(float x, float y) {
	return max(sign(x - y), 0.0);
}

void fragment() {
	// 时间偏移：改成 10000.0 - TIME 即可反向滚动
	float time = 10000.0 + TIME;

	// ---------- 1. 每行一颗星：伪造随机数 ----------
	// floor(UV.y * small_stars)  -> 当前行号
	// fract(sin(行号) * dimensions.y) -> [0,1) 的伪随机数 rn
	float small_star_rn = fract(sin(floor(UV.y * small_stars)) * dimensions.y);
	float large_star_rn = fract(sin(floor(UV.y * large_stars)) * dimensions.y);

	// ---------- 2. 横向滚动 + 局部坐标 ----------
	// fract(...) 让星星滚出屏幕后从另一侧循环出现
	// * 2.0 - 1.0 把 [0,1) 映射到 [-1,1)，方便以原点为圆心画圆
	vec2 small_star_uv = vec2(
		fract(UV.x + (base_scroll_speed + small_star_rn * additional_scroll_speed) * time) * small_stars * dimensions.x / dimensions.y,
		fract(UV.y * small_stars)
	) * 2.0 - 1.0;

	vec2 large_star_uv = vec2(
		fract(UV.x + (base_scroll_speed + large_star_rn * additional_scroll_speed) * time) * large_stars * dimensions.x / dimensions.y,
		fract(UV.y * large_stars)
	) * 2.0 - 1.0;

	// ---------- 3. 画小星星（柔边圆） ----------
	vec4 star_color = mix(far_stars_color, near_stars_color, small_star_rn);
	float star_size = small_stars_far_size + (small_stars_near_size - small_stars_far_size) * small_star_rn;
	// max((半径 - 距离)/半径, 0) 得到中心亮、边缘渐隐的圆
	COLOR.rgb = mix(COLOR.rgb, star_color.rgb, max((star_size - length(small_star_uv)) / star_size, 0.0) * star_color.a);

	// ---------- 4. 画大星星（圆 + 十字星芒，柔边） ----------
	star_color = mix(far_stars_color, near_stars_color, large_star_rn);
	star_size = large_stars_far_size + (large_stars_near_size - large_stars_far_size) * large_star_rn;
	float core = max((star_size / 1.7 - length(large_star_uv)) / star_size, 0.0);          // 中心圆
	float cross = max((star_size - length(large_star_uv)) / star_size / 2.0, 0.0)
		* max(greater_than(star_size / 10.0, abs(large_star_uv.x)),                        // 横向光条
			  greater_than(star_size / 10.0, abs(large_star_uv.y)));                       // 纵向光条
	COLOR.rgb = mix(COLOR.rgb, star_color.rgb, (core + cross) * star_color.a);

	// ---------- 可选：换成别的星星形状（把上面第 4 步替换掉即可） ----------
	// 硬边圆：      greater_than(star_size, length(large_star_uv))
	// 柔边十字：    max((star_size - length(large_star_uv)) / star_size, 0.0)
	//                * max(greater_than(star_size/10.0, abs(large_star_uv.x)),
	//                      greater_than(star_size/10.0, abs(large_star_uv.y)))
	// 方形：        greater_than(star_size, abs(large_star_uv.x)) * greater_than(star_size, abs(large_star_uv.y))
	// 菱形：        greater_than(star_size, abs(large_star_uv.y) + abs(large_star_uv.x))
	// 贴图：        vec4 p = texture(large_stars_texture, (large_star_uv / star_size + 1.0) / 2.0) * star_color;
	//               COLOR.rgb = mix(COLOR.rgb, p.rgb, p.a);
}
