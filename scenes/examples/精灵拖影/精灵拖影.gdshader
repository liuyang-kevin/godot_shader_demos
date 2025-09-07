shader_type canvas_item;

uniform vec4 custom_color : source_color = vec4(1.0, 1.0, 1.0, 0.8); // 可自定义的颜色，默认与初始颜色一致
uniform float time_factor : hint_range(0.0, 10.0) = 1.0; // 时间因子，控制效果随时间变化的速度
uniform float distortion_strength : hint_range(0.0, 0.1) = 0.02; // 扭曲强度
uniform float color_shift : hint_range(0.0, 0.1) = 0.01; // 颜色偏移量
uniform float fade_effect : hint_range(0.0, 1.0) = 0.5; // 淡化效果强度

varying vec4 v_modulate;
varying float v_time;

void vertex() {
    v_modulate = COLOR; // 捕获 Sprite2D.modulate 的颜色
    v_time = TIME * time_factor; // 应用时间因子
}

void fragment() {
    // 创建动态UV偏移，基于时间和位置
    vec2 distorted_uv = UV;
    distorted_uv.x += sin(v_time + UV.y * 10.0) * distortion_strength;
    distorted_uv.y += cos(v_time + UV.x * 8.0) * distortion_strength * 0.8;

    // 采样纹理，使用扭曲后的UV
    vec4 tex = texture(TEXTURE, distorted_uv);

    // 如果原始纹理像素完全透明，则丢弃
    if (tex.a <= 0.0) {
        discard;
    }

    // 创建颜色偏移效果 - 对RGB通道分别采样不同的UV偏移
    vec4 color_shifted = tex;
    color_shifted.r = texture(TEXTURE, distorted_uv + vec2(color_shift * sin(v_time), 0.0)).r;
    color_shifted.g = texture(TEXTURE, distorted_uv + vec2(color_shift * cos(v_time * 0.7), 0.0)).g;
    color_shifted.b = texture(TEXTURE, distorted_uv + vec2(color_shift * sin(v_time * 1.3), 0.0)).b;

    // 混合原始颜色和自定义颜色
    vec4 final_color = mix(color_shifted, custom_color, fade_effect);

    // 应用 modulate 的 alpha 值
    COLOR = vec4(final_color.rgb, final_color.a * v_modulate.a);

    // 添加轻微的发光效果，基于时间变化
    COLOR.rgb += vec3(0.1) * (sin(v_time * 2.0) * 0.5 + 0.5) * (1.0 - fade_effect);
}