// =============================================================
// 中毒 (Poison)
// 分类：状态影响
// -------------------------------------------------------------
// 全篇最简的状态 shader，很适合入门：
//   中毒强度 = 基础强度 × 呼吸系数
//   呼吸系数 = sin(TIME * speed) * 0.5 + 0.5   → 在 0~1 之间来回
//   然后用 mix 把原色往毒绿色拉。
//
// 为什么"脉动"很重要：
//   静态染色玩家会看腻，加上周期性起伏后，
//   角色会持续"一鼓一鼓"地提示"你还在掉血"，这是 DEBUFF 的通用设计。
// =============================================================

shader_type canvas_item;

// 中毒程度 0~1（可以理解为"毒层数/最大层数"）
uniform float poison_amount : hint_range(0.0, 1.0) = 0.0;
// 毒的颜色
uniform vec4 poison_color : source_color = vec4(0.3, 1.0, 0.3, 1.0);
// 脉动速度
uniform float pulse_speed : hint_range(0.0, 10.0) = 3.0;

void fragment() {
	vec4 texture_color = texture(TEXTURE, UV);

	// 呼吸脉动：sin 从 [-1,1] 映射到 [0,1]
	float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;
	// 最多只染 50%（* 0.5），保证还能看清角色本身
	float poison_intensity = poison_amount * pulse * 0.5;

	vec3 poisoned_color = mix(texture_color.rgb, poison_color.rgb, poison_intensity);

	COLOR = vec4(poisoned_color, texture_color.a);
}
