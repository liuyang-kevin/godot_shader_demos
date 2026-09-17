// =============================================================
// 像素风水面 (Pixel Water)
// 分类：粒子 / 环境特效
// -------------------------------------------------------------
// 这是一个"综合型"水面：同时用了 3 个技巧，值得拆开看。
//
//   ① 像素化（Posterize / Pixelate）
//      uv *= pixel_resolution; uv = floor(uv); uv /= pixel_resolution;
//      把连续 UV 量化成网格 → 采样结果变成色块，一秒变成像素画风。
//
//   ② 屏幕纹理反射（Screen Texture）
//      hint_screen_texture 的 SCREEN_TEXTURE + SCREEN_UV
//      可以拿到"这个节点后面已经画好的画面"，于是能做出反射/折射/玻璃。
//      采样时把 SCREEN_UV.y 翻转 (1.7 - (SCREEN_UV.y - level)) 就得到倒影。
//
//   ③ 噪声 + 步进（Stepped Noise）
//      波浪高度 = 噪声采样值；水面纹理用
//      (noise.x < limit) ? 1.0 : 0.0 把平滑噪声切成"硬边水纹"，
//      这是做像素风 / 卡通水的常用手法（把连续量二值化）。
//
// 使用注意：
//   - 必须挂在覆盖水面的节点上（通常是 ColorRect / Sprite2D）；
//   - 用到 SCREEN_TEXTURE，节点需要在 CanvasItem 树中，
//     且背后要有东西才能看到反射；
//   - 需要两张 repeat 的噪声贴图。
// =============================================================

shader_type canvas_item;
render_mode unshaded;

// 水面高度（0 = 顶边，1 = 底边）
uniform float level : hint_range(0.0, 1.0) = 0.0;
// 水的固有色
uniform vec4 water_albedo : source_color;
// 水色占比（越大越"浑"）
uniform float water_opacity : hint_range(0.0, 1.0) = 0.35;
// 水流速度
uniform float water_speed = 0.05;
// 反射扭曲强度
uniform float wave_distortion = 0.2;
// 反射在 Y 方向被压缩的倍数（越大倒影越"皱"）
uniform int wave_multiplyer = 7;
// 是否显示二值化的水纹
uniform bool water_texture_on = true;
// 反射的整体偏移（手动微调倒影位置）
uniform float reflection_X_offset = 0.0;
uniform float reflection_Y_offset = 0.0;

// 两张噪声：一张做波浪，一张做水纹贴图
uniform sampler2D noise_texture : repeat_enable;
uniform sampler2D noise_texture2 : repeat_enable;
// 屏幕纹理：拿到本节点背后已绘制的画面
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

// 像素化分辨率（越小色块越大）
uniform float pixel_resolution_x : hint_range(1.0, 1280.0) = 64.0;
uniform float pixel_resolution_y : hint_range(1.0, 1280.0) = 64.0;
// 左右两侧边缘的羽化宽度，避免水块被硬切
uniform float edge_fade_width : hint_range(0.0, 0.5) = 0.05;

void fragment() {
	vec2 uv = UV;
	COLOR = vec4(0.0);

	// ---------- ① 像素化：把 UV 量化到网格 ----------
	vec2 pixel_resolution = vec2(pixel_resolution_x, pixel_resolution_y);
	uv *= pixel_resolution;
	uv = floor(uv);
	uv /= pixel_resolution;

	// ---------- ③ 水面波动：让水平线上下起伏 ----------
	float wave = texture(noise_texture, vec2(uv.x * 5.0, TIME * water_speed)).x * 0.02;

	// 只在水位线以下绘制
	if (uv.y >= level + wave) {
		COLOR.a = 1.0;

		// ---------- 反射的扭曲偏移 ----------
		vec2 water_uv = vec2(uv.x, uv.y * float(wave_multiplyer));
		float noise = texture(noise_texture, vec2(water_uv.x + TIME * water_speed, water_uv.y)).x * wave_distortion;
		noise -= (0.5 * wave_distortion);   // 中心化到 [-0.5, 0.5] * strength

		// ---------- ③ 二值化水纹 ----------
		if (water_texture_on) {
			float water_texture_limit = 0.35;
			vec4 water_texture = texture(noise_texture2, uv * vec2(0.5, 4.0) + vec2(noise, 0.0));
			// 平滑噪声 -> 0/1 硬边，得到像素风的水波纹
			float water_texture_value = (water_texture.x < water_texture_limit) ? 1.0 : 0.0;
			COLOR.xyz = vec3(water_texture_value);
		}

		// ---------- ② 屏幕反射 + 水色混合 ----------
		vec4 current_texture = texture(
			SCREEN_TEXTURE,
			vec2(SCREEN_UV.x + noise + reflection_X_offset, 1.7 - (SCREEN_UV.y - level) + reflection_Y_offset)
		);
		COLOR = mix(COLOR, current_texture, 0.5);   // 水纹与倒影各占一半
		COLOR = mix(COLOR, water_albedo, water_opacity); // 再压一层水色

		// ---------- 水位线处的白色浪花 ----------
		if (abs(uv.y - (level + wave)) < 0.02) {
			float splash = texture(noise_texture, vec2(uv.x * 5.0, TIME * water_speed)).x * 2.0;
			COLOR.a *= splash;
			// 越靠近浪花下沿白色越少，做出渐变而不是一条死白线
			float white_factor = 1.0 - smoothstep(level, level + 0.02, uv.y);
			COLOR.rgb = mix(COLOR.rgb, vec3(1.0), white_factor);
		}

		// ---------- 左右边缘羽化 ----------
		float edge_opacity = 1.0;
		edge_opacity *= smoothstep(0.0, edge_fade_width, UV.x);        // 左侧渐变
		edge_opacity *= smoothstep(0.0, edge_fade_width, 1.0 - UV.x);  // 右侧渐变
		COLOR.a *= edge_opacity;
	}
}
