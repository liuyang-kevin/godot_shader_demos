// =============================================================
// 受击反馈 - 抖动 + 模糊 + 泛白 (Enemy Hit Feedback)
// 分类：状态影响
// -------------------------------------------------------------
// 把三种最基础的受击表现叠在一起，是一个很好的"组合练习"：
//
//   ① 抖动：uv += sin/cos(time * 50) * shake_intensity
//            （同 shake_intensity.gdshader）
//   ② 模糊：以抖动后的 uv 为中心做 9x9 均值卷积
//            （同 blur_amount.gdshader）
//            注意：抖动必须在模糊**之前**算，
//            这样模糊会跟着抖动一起动，才有"被打散"的糊感；
//   ③ 泛白：mix(结果, 白, white_intensity)
//            但白色只保留原 alpha → vec4(1,1,1, final_color.a)
//            避免精灵外围出现白方块。
//
// 三个参数分开控制，就能组合出不同强度的受击：
//   轻微：shake 0.005 / blur 0 / white 0.3
//   重击：shake 0.02  / blur 0.05 / white 0.8
// =============================================================

shader_type canvas_item;

// 模糊半径
uniform float blur_amount : hint_range(0.0, 0.2);
// 抖动幅度
uniform float shake_intensity : hint_range(0.0, 0.2);
// 泛白强度 0~1
uniform float white_intensity : hint_range(0.0, 1.0);
// 由脚本驱动的时间（见 shake_intensity.gdshader 的说明）
uniform float time;

void fragment() {
	vec2 resolution = vec2(textureSize(TEXTURE, 0));
	vec4 sum = vec4(0.0);
	vec2 blur = blur_amount * resolution;

	// ① 先抖动，得到采样中心
	vec2 uv = UV;
	uv.x += sin(time * 50.0) * shake_intensity;
	uv.y += cos(time * 50.0) * shake_intensity;

	// ② 以抖动后的 uv 为中心做 9x9 均值模糊
	for (int i = -4; i <= 4; i++) {
		for (int j = -4; j <= 4; j++) {
			vec2 shift = vec2(float(i), float(j)) / resolution;
			sum += texture(TEXTURE, uv + shift * blur);
		}
	}
	vec4 final_color = sum / 81.0;

	// ③ 泛白：白只保留原 alpha，防止透明区域被涂白
	vec4 white = vec4(1.0, 1.0, 1.0, final_color.a);
	COLOR = mix(final_color, white, white_intensity);
}
