// =============================================================
// 无敌闪烁 (Blink)
// 分类：状态影响
// -------------------------------------------------------------
// 受击后无敌帧的标准表现：整体透明度按正弦波在
// [min_alpha, 1.0] 之间来回跳。
//
//   blink = sin(TIME * speed) * 0.5 + 0.5   → [0,1]
//   blink = mix(min_alpha, 1.0, blink)      → [min_alpha, 1]
//   COLOR.a *= blink;
//
// 要点：
//   - 只改 alpha，不改 rgb，所以角色不会变色，只是"忽隐忽现"；
//   - min_alpha 不要给 0，否则角色会完全消失一瞬，玩家容易跟丢；
//   - speed 建议 8~15，太快会像噪点，太慢没有"无敌"的急促感。
// =============================================================

shader_type canvas_item;

// 闪烁频率（次/秒量级）
uniform float blink_speed : hint_range(0.0, 20.0) = 10.0;
// 最暗时保留的透明度（0 会完全消失）
uniform float min_alpha : hint_range(0.0, 1.0) = 0.3;

void fragment() {
	vec4 texture_color = texture(TEXTURE, UV);

	// 正弦映射到 [0,1]，再拉伸到 [min_alpha, 1]
	float blink = sin(TIME * blink_speed) * 0.5 + 0.5;
	blink = mix(min_alpha, 1.0, blink);

	COLOR = texture_color;
	COLOR.a *= blink;
}
