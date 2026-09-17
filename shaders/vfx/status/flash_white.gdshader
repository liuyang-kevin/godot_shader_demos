// =============================================================
// 受击闪白 (Flash White)
// 分类：状态影响
// -------------------------------------------------------------
// 最常用也最便宜的打击反馈：把整张图往白色推。
//
//   关键细节：mix 的权重里乘了 texture_color.a
//     mix(texture_color, flash_color, flash_amount * texture_color.a)
//   这样精灵外部的透明区域不会被"涂白"，
//   否则一张矩形贴图会立刻变成一个白方块。
//   —— 处理带透明通道的精灵时，几乎每个全屏染色 shader 都要这么乘一次。
//
// 用法：受击瞬间 flash_amount 打到 1，然后在 0.1s 内补间回 0。
// =============================================================

shader_type canvas_item;

// 闪白强度 0~1
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
// 闪的颜色（默认纯白；改红可以做"暴怒"，改蓝做"冰冻一击"）
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 texture_color = texture(TEXTURE, UV);

	// 乘 alpha：只在精灵实心的部分染色，避免透明区域变成白块
	COLOR = mix(texture_color, flash_color, flash_amount * texture_color.a);
	COLOR.a = texture_color.a;
}
