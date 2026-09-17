// =============================================================
// 画面抖动 (Shake)
// 分类：状态影响
// -------------------------------------------------------------
// 最"物理"的一种受击反馈：让整张贴图在采样时左右上下乱晃。
//
//   uv.x += sin(time * 50.0) * intensity;
//   uv.y += cos(time * 50.0) * intensity;
//   —— 用 sin / cos 而不是随机，是为了得到"高频但连续"的抖动；
//      如果每帧随机，看起来会像信号雪花而不是震动。
//   50.0 是频率，数值越大抖得越"急"。
//
// 注意：
//   - 这里的 time 是**自定义 uniform**，不是 Godot 内置的 TIME。
//     内置 TIME 是"游戏启动后经过的秒数"，无法暂停/重置；
//     想让抖动"只在受击的 0.2 秒内发生"，就必须自己传一个
//     由脚本控制、能归零的 time（受击时开始累加 delta，结束归零）。
//   - 不自己传 time 的话，节点会永远在抖。
// =============================================================

shader_type canvas_item;

// 由脚本驱动的时间（受击期间累加 delta，结束后归 0）
uniform float time;
// 抖动幅度（UV 比例，0.01 就已经很明显）
uniform float shake_intensity : hint_range(0.0, 0.2);

void fragment() {
	vec2 uv = UV;
	uv.x += sin(time * 50.0) * shake_intensity;
	uv.y += cos(time * 50.0) * shake_intensity;

	COLOR = texture(TEXTURE, uv);
}
