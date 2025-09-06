shader_type canvas_item;

uniform vec4 custom_color : source_color;
uniform sampler2D trail_texture;
uniform float time_elapsed;
uniform float trail_length = 0.5;
uniform float fade_power = 2.0;

varying vec4 v_modulate;

void vertex() {
    v_modulate = COLOR;
}

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    if (tex.a <= 0.0) {
        discard;
    }

    // 基础颜色
    vec4 base_color = vec4(custom_color.rgb, custom_color.a * v_modulate.a);

    // 拖影效果 - 基于时间和UV偏移
    float trail_factor = sin(TIME * 10.0) * 0.1;
    vec2 trail_uv = UV + vec2(trail_factor * trail_length, 0.0);

    vec4 trail_color = texture(trail_texture, trail_uv);
    trail_color.a *= pow(1.0 - abs(trail_factor), fade_power);

    // 混合颜色
    COLOR = mix(base_color, trail_color, trail_color.a);
}