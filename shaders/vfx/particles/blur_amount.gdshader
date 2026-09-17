// =============================================================
// 均值模糊 (Box Blur)
// 分类：粒子 / 环境特效（更准确说是"画面后处理"）
// -------------------------------------------------------------
// 原理：
//   最直白的卷积：对当前像素周围 9x9 = 81 个像素各采样一次，求平均。
//   - blur_amount 的单位是"分辨率的比例"，乘上 textureSize 得到像素级偏移；
//   - 两层 for 是常量循环，GPU 会展开，代价是 81 次纹理采样/像素，
//     所以它是最贵、也最好懂的模糊。
// 延伸：
//   - 高斯模糊 = 给每个采样加权重（中间大、边缘小），效果好很多；
//   - 真正项目里通常做"两次一维模糊"(横一次竖一次)，
//     把 81 次采样降到 9+9 次，效果几乎一样（可分离卷积）。
// =============================================================

shader_type canvas_item;

// 模糊半径（相对整张贴图尺寸的比例，0.01 左右就已经很明显）
uniform float blur_amount : hint_range(0.0, 0.2);

void fragment() {
	// textureSize 拿到贴图（或精灵区域）的像素尺寸
	vec2 resolution = vec2(textureSize(TEXTURE, 0));
	vec4 sum = vec4(0.0);
	// 把比例换算成像素数；注意这里 shift 还会再除以 resolution，
	// 所以真实偏移 = i / resolution * blur_amount * resolution = i * blur_amount
	vec2 blur = blur_amount * resolution;

	// 9x9 邻域采样
	for (int i = -4; i <= 4; i++) {
		for (int j = -4; j <= 4; j++) {
			vec2 shift = vec2(float(i), float(j)) / resolution;
			sum += texture(TEXTURE, UV + shift * blur);
		}
	}

	// 求平均
	COLOR = sum / 81.0;
}
