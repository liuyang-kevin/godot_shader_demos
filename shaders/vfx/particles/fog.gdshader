// =============================================================
// 雾气 (Fog)
// 分类：粒子 / 环境特效
// -------------------------------------------------------------
// 原理：
//   用一张噪声贴图当作"雾的浓度场"：
//   1. UV 随时间偏移（fract 保证无限平铺）→ 雾在缓慢流动；
//   2. 取噪声的 r 通道，把 [0,1] 拉伸到 [-1,1] 再 clamp 回 [0,1]，
//      目的是"抬高对比度"：低于 0.5 的噪声被压成 0（透明），
//      只剩下团块状的高值区域，看起来才像雾而不是一层灰膜；
//   3. 直接乘到 COLOR.a 上，只改透明度不改颜色 —— 所以这个材质
//      必须挂在"白色/浅色的 ColorRect"上才会显示为白雾。
// 注意：
//   - 这是一个"只改 alpha 不改 rgb"的典型遮罩型 shader；
//   - noise_texture 建议用 NoiseTexture2D（FastNoiseLite）生成，
//     并在导入/材质上开启 repeat，否则边缘会出现拉伸。
// =============================================================

shader_type canvas_item;

// 噪声贴图（建议 seamless / repeat_enable）
uniform sampler2D noise_texture : repeat_enable, filter_nearest;
// 雾的整体浓度（0 = 全透明，1 = 最浓）
uniform float density : hint_range(0.0, 1.0) = 0.25;
// 雾的流动速度（单位：UV/秒）
uniform vec2 speed = vec2(0.02, 0.01);


void fragment() {
	// 让噪声 UV 随时间平移；fract 保证超出 [0,1] 后循环采样
	vec2 uv = fract(UV + speed * TIME);

	// 采样噪声（只取 r 通道当作浓度）
	float noise = texture(noise_texture, uv).r;

	// 把 [0,1] 映射到 [-1,1] 再截断回 [0,1]：
	// 相当于以 0.5 为阈值做了一次"软抠图"，雾变成一团一团的
	float fog = clamp(noise * 2.0 - 1.0, 0.0, 1.0);

	// 只影响透明度：颜色由节点自身（ColorRect 的 color）决定
	COLOR.a *= fog * density;
}
