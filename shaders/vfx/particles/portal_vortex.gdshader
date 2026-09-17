// =============================================================
// 传送门漩涡 (Portal Vortex)
// 分类：粒子 / 环境特效
// -------------------------------------------------------------
// 原理：极坐标（Polar Coordinates）变换的经典例子。
//   1. 把 UV 平移到以中心为原点：uv_centered = UV - 0.5
//   2. 转成极坐标：
//        dist  = length(uv_centered)              到中心的距离
//        angle = atan(uv_centered.y, uv_centered.x)  方位角
//   3. 关键一行：spiral = angle + dist * 10.0 - TIME * speed
//      "距离越远，角度转得越多" → 直线被拧成螺旋（漩涡）；
//      减去 TIME 让螺旋持续旋转。
//   4. 把 (cos, sin) * dist 变回笛卡尔 UV 去采样，
//      得到一张被旋进去的图；再用两色 sin 混合做能量流动感。
// 要点：
//   - angle + dist * k 是所有"漩涡 / 星系 / 黑洞 / 螺旋"的通用写法；
//   - atan(y, x) 在 x=0 处有接缝，做无缝效果需要额外处理。
// =============================================================

shader_type canvas_item;

// 旋转速度
uniform float vortex_speed : hint_range(0.0, 5.0) = 2.0;
// 漩涡强度：0 = 原图，1 = 完全漩涡化
uniform float vortex_strength : hint_range(0.0, 1.0) = 0.5;
// 两种能量色，按距离/时间互相渐变
uniform vec4 portal_color1 : source_color = vec4(0.5, 0.2, 1.0, 1.0);
uniform vec4 portal_color2 : source_color = vec4(0.2, 0.8, 1.0, 1.0);

void fragment() {
	vec2 center = vec2(0.5, 0.5);
	vec2 uv_centered = UV - center;

	// 笛卡尔 -> 极坐标
	float dist = length(uv_centered);
	float angle = atan(uv_centered.y, uv_centered.x);

	// 螺旋：角度随距离增加（拧毛巾），再随时间旋转
	float spiral = angle + dist * 10.0 - TIME * vortex_speed;

	// 极坐标 -> 笛卡尔，得到旋转后的采样 UV
	vec2 vortex_uv = vec2(
		cos(spiral) * dist + 0.5,
		sin(spiral) * dist + 0.5
	);

	// 双色能量流动
	float color_mix = sin(dist * 10.0 - TIME * vortex_speed * 2.0) * 0.5 + 0.5;
	vec4 portal_color = mix(portal_color1, portal_color2, color_mix);

	// 原图与漩涡图按 strength 混合，再叠能量色
	// (1.0 - dist * 2.0) 让颜色集中在中心，边缘自然淡出
	vec4 texture_color = texture(TEXTURE, mix(UV, vortex_uv, vortex_strength));
	COLOR = mix(texture_color, portal_color, 0.6 * (1.0 - dist * 2.0));
}
